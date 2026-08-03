# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists s3_output]} {
    set s3_output /tmp/rainbios-s3.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::s3_callback $callback
    set ::s3_breakpoint [
        debug set_bp $sentinel {} {s3_call_returned}
    ]
    reg PC $address
}

proc s3_call_returned {} {
    debug remove_bp $::s3_breakpoint
    set callback $::s3_callback
    uplevel #0 $callback
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc vdp_registers_0_6 {} {
    set values {}
    for {set r 0} {$r < 7} {incr r} {
        lappend values [format "%02X" [debug read "VDP regs" $r]]
    }
    return [join $values ","]
}

proc record_s3 {line} {
    set handle [open $::s3_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    set ::s3_lines {}
    # Force STATFL away from the live value so RDVDP must overwrite it.
    poke 0xF3E7 0xFF
    invoke_bios 0x013E rdvdp_done
}

proc rdvdp_done {} {
    lappend ::s3_lines [format "RDVDP=%02X,%02X" [reg A] [peek 0xF3E7]]
    invoke_bios 0x0075 inimlt_done
}

proc inimlt_done {} {
    lappend ::s3_lines [format "INIMLT=%02X,%02X,%s,%04X,%04X,%04X,%04X,%02X,%02X" \
        [peek 0xFCAF] [peek 0xF3B0] [vdp_registers_0_6] \
        [word_at 0xF922] [word_at 0xF924] [word_at 0xF926] [word_at 0xF928] \
        [debug read VRAM 0x1B00] [debug read VRAM 0x0000]]
    invoke_bios 0x0081 setmlt_done
}

proc setmlt_done {} {
    lappend ::s3_lines [format "SETMLT=%s" [vdp_registers_0_6]]
    record_s3 [join $::s3_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
