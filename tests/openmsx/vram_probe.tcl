# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists vram_output]} {
    set vram_output /tmp/rainbios-vram.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::vram_callback $callback
    set ::vram_breakpoint [
        debug set_bp $sentinel {} {vram_call_returned}
    ]
    reg PC $address
}

proc vram_call_returned {} {
    debug remove_bp $::vram_breakpoint
    set callback $::vram_callback
    uplevel #0 $callback
}

proc record_vram {line} {
    set handle [open $::vram_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    # Seed four VRAM bytes and the equivalent RAM bytes so both read and
    # write directions are exercised.
    debug write VRAM 0x0000 0x11
    debug write VRAM 0x1FFF 0x22
    debug write VRAM 0x3FFF 0x33
    poke 0xFC00 0x41
    poke 0xFC01 0x42
    poke 0xFC02 0x43
    poke 0xFC03 0x44
    # WRTVRM then RDVRM at a mid address
    reg HL 0x1000
    reg A 0x5A
    invoke_bios 0x004D write_mid_done
}

proc write_mid_done {} {
    set ::wrote [reg A]
    reg HL 0x1000
    invoke_bios 0x004A read_mid_done
}

proc read_mid_done {} {
    lappend ::vram_lines [format "ROUNDTRIP=%02X,%02X" $::wrote [reg A]]
    # Boundary reads: the 14-bit address mask wraps 0x4000 to 0x0000.
    reg HL 0x0000
    invoke_bios 0x004A read_low_done
}

proc read_low_done {} {
    lappend ::vram_lines [format "READLOW=%02X" [reg A]]
    reg HL 0x4000
    invoke_bios 0x004A read_wrapped_done
}

proc read_wrapped_done {} {
    lappend ::vram_lines [format "READWRAP=%02X" [reg A]]
    reg HL 0x1FFF
    invoke_bios 0x004A read_mid2_done
}

proc read_mid2_done {} {
    lappend ::vram_lines [format "READMID=%02X" [reg A]]
    reg HL 0x3FFF
    invoke_bios 0x004A read_top_done
}

proc read_top_done {} {
    lappend ::vram_lines [format "READTOP=%02X" [reg A]]
    # FILVRM fills 256 bytes at 0x0800 with 0x5A.
    reg HL 0x0800
    reg BC 256
    reg A 0x5A
    invoke_bios 0x0056 fill_done
}

proc fill_done {} {
    lappend ::vram_lines [format "FILL=%02X,%02X,%02X" \
        [debug read VRAM 0x0800] [debug read VRAM 0x08FF] [debug read VRAM 0x0900]]
    # LDIRMV copies 4 VRAM bytes at 0x2000 into RAM at 0xFC10.
    debug write VRAM 0x2000 0x61
    debug write VRAM 0x2001 0x62
    debug write VRAM 0x2002 0x63
    debug write VRAM 0x2003 0x64
    reg HL 0x2000
    reg DE 0xFC10
    reg BC 4
    invoke_bios 0x0059 ldir_mv_done
}

proc ldir_mv_done {} {
    lappend ::vram_lines [format "LDIRMV=%02X,%02X,%02X,%02X" \
        [peek 0xFC10] [peek 0xFC11] [peek 0xFC12] [peek 0xFC13]]
    # LDIRVM copies 4 RAM bytes at 0xFC00 into VRAM at 0x3000.
    reg HL 0xFC00
    reg DE 0x3000
    reg BC 4
    invoke_bios 0x005C ldir_vm_done
}

proc ldir_vm_done {} {
    lappend ::vram_lines [format "LDIRVM=%02X,%02X,%02X,%02X" \
        [debug read VRAM 0x3000] [debug read VRAM 0x3001] \
        [debug read VRAM 0x3002] [debug read VRAM 0x3003]]
    # Boundary wrap: the 14-bit address mask maps 0x7FFF and 0x4000 back
    # into the 16 KiB window, so WRTVRM at the top of the window and at the
    # window base both land on existing 16 KiB addresses.
    reg HL 0x7FFF
    reg A 0x88
    invoke_bios 0x004D wrap_high_done
}

proc wrap_high_done {} {
    reg HL 0x7FFF
    invoke_bios 0x004A wrap_high_read
}

proc wrap_high_read {} {
    set ::wrap_high [reg A]
    reg HL 0x4000
    reg A 0x77
    invoke_bios 0x004D wrap_base_done
}

proc wrap_base_done {} {
    reg HL 0x4000
    invoke_bios 0x004A wrap_base_read
}

proc wrap_base_read {} {
    set ::wrap_base [reg A]
    reg HL 0x0000
    invoke_bios 0x004A wrap_zero_read
}

proc wrap_zero_read {} {
    set ::wrap_zero [reg A]
    # FILVRM crossing the 0x4000 boundary: 16 bytes at 0x3FF8 wrap into
    # 0x0000-0x0007 because the VDP address counter is 14-bit.
    reg HL 0x3FF8
    reg BC 16
    reg A 0x5C
    invoke_bios 0x0056 fill_cross_done
}

proc fill_cross_done {} {
    lappend ::vram_lines [format "FILLX=%02X,%02X,%02X,%02X" \
        [debug read VRAM 0x3FF8] [debug read VRAM 0x3FFF] \
        [debug read VRAM 0x0000] [debug read VRAM 0x0007]]
    # LDIRVM crossing: RAM 0xFC50..0xFC57 to VRAM 0x3FFC wraps to 0x0003.
    poke 0xFC50 0x71
    poke 0xFC51 0x72
    poke 0xFC52 0x73
    poke 0xFC53 0x74
    poke 0xFC54 0x75
    poke 0xFC55 0x76
    poke 0xFC56 0x77
    poke 0xFC57 0x78
    reg HL 0xFC50
    reg DE 0x3FFC
    reg BC 8
    invoke_bios 0x005C ldir_vm_cross_done
}

proc ldir_vm_cross_done {} {
    lappend ::vram_lines [format "LDIRVMX=%02X,%02X,%02X,%02X" \
        [debug read VRAM 0x3FFC] [debug read VRAM 0x3FFF] \
        [debug read VRAM 0x0000] [debug read VRAM 0x0003]]
    # LDIRMV crossing: read VRAM 0x3FFC..0x3FFF then 0x0000..0x0003 back.
    reg HL 0x3FFC
    reg DE 0xFC60
    reg BC 8
    invoke_bios 0x0059 ldir_mv_cross_done
}

proc ldir_mv_cross_done {} {
    lappend ::vram_lines [format "LDIRMVX=%02X,%02X,%02X,%02X" \
        [peek 0xFC60] [peek 0xFC63] [peek 0xFC64] [peek 0xFC67]]
    lappend ::vram_lines [format "WRAPTOP=%02X" $::wrap_high]
    lappend ::vram_lines [format "WRAPBASE=%02X" $::wrap_base]
    lappend ::vram_lines [format "WRAPZERO=%02X" $::wrap_zero]
    install_vdp_hook
}

# Port-ordering hardening: an H.TIMI hook actively writes a complete VDP
# register (R0) and bumps a frame counter on every VBlank, so interrupts keep
# interleaving with the main loop. The main loop then issues thousands of
# WRTVDP register writes to R7 through the public BIOS. Each WRTVDP control
# pair must be interrupt-atomic: if an interrupt could split the value byte
# from the register byte, the hook's R0 write would corrupt R7. After the
# loop R7 must still hold the main loop's value and the hook must have fired.
proc install_vdp_hook {} {
    # H.TIMI at FD9F jumps to 0xFC40: write R0 = 2, bump the frame counter, ret.
    poke 0xFC40 0x3E
    poke 0xFC41 0x02          ; # ld a,2
    poke 0xFC42 0xD3
    poke 0xFC43 0x99          ; # out (0x99),a
    poke 0xFC44 0x3E
    poke 0xFC45 0x80          ; # ld a,0x80
    poke 0xFC46 0xD3
    poke 0xFC47 0x99          ; # out (0x99),a
    poke 0xFC48 0x3A
    poke 0xFC49 0x7F
    poke 0xFC4A 0xFC          ; # ld a,(0xFC7F)
    poke 0xFC4B 0x3C          ; # inc a
    poke 0xFC4C 0x32
    poke 0xFC4D 0x7F
    poke 0xFC4E 0xFC          ; # ld (0xFC7F),a
    poke 0xFC4F 0xC9          ; # ret
    poke 0xFD9F 0xC3          ; # JP
    poke 0xFDA0 [expr {0xFC40 & 0xFF}]
    poke 0xFDA1 [expr {0xFC40 >> 8}]
    poke 0xFC7F 0
    # Machine-code WRTVDP loop at 0xFC50: WRTVDP(R7, 0x5A) DE times.
    poke 0xFC50 0x06
    poke 0xFC51 0x5A          ; # ld b,0x5A (value)
    poke 0xFC52 0x0E
    poke 0xFC53 0x07          ; # ld c,7 (register R7)
    poke 0xFC54 0xCD
    poke 0xFC55 0x47
    poke 0xFC56 0x00          ; # call 0x0047 (WRTVDP)
    poke 0xFC57 0x1B          ; # dec de
    poke 0xFC58 0x7A          ; # ld a,d
    poke 0xFC59 0xB3          ; # or e
    poke 0xFC5A 0x20
    poke 0xFC5B 0xF8          ; # jr nz,0xFC54
    poke 0xFC5C 0xC9          ; # ret
    reg B 0x5A
    reg C 7
    reg DE 0x0FA0             ; # 4000 writes, several frames of interrupts
    invoke_bios 0xFC50 order_loop_done
}

proc order_loop_done {} {
    set ::hook_frames [peek 0xFC7F]
    # Restore the H.TIMI hook to its RET default.
    poke 0xFD9F 0xC9
    lappend ::vram_lines [format "ORDER=%02X" [debug read "VDP regs" 7]]
    lappend ::vram_lines [format "HOOKFIRE=%02X" \
        [expr {$::hook_frames > 0 ? 1 : 0}]]
    # The VDP registers must still be readable after the control-port traffic.
    lappend ::vram_lines [format "VDPREG=%02X,%02X" \
        [debug read "VDP regs" 0] [debug read "VDP regs" 1]]
    record_vram [join $::vram_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
