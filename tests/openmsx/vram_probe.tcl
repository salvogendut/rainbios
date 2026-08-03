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
    # The VDP registers must still be readable after the data-port traffic.
    lappend ::vram_lines [format "VDPREG=%02X,%02X" \
        [debug read "VDP regs" 0] [debug read "VDP regs" 1]]
    record_vram [join $::vram_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
