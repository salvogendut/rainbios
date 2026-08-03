# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists vdpstate_output]} {
    set vdpstate_output /tmp/rainbios-vdpstate.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::vdpstate_callback $callback
    set ::vdpstate_breakpoint [
        debug set_bp $sentinel {} {vdpstate_call_returned}
    ]
    reg PC $address
}

proc vdpstate_call_returned {} {
    debug remove_bp $::vdpstate_breakpoint
    set callback $::vdpstate_callback
    uplevel #0 $callback
}

proc live_registers {} {
    set values {}
    for {set r 0} {$r < 8} {incr r} {
        lappend values [format "%02X" [debug read "VDP regs" $r]]
    }
    return [join $values ","]
}

proc shadow_registers {} {
    set values {}
    for {set r 0} {$r < 8} {incr r} {
        lappend values [format "%02X" [peek [expr {0xF3DF + $r}]]]
    }
    return [join $values ","]
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc record_vdpstate {line} {
    set handle [open $::vdpstate_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    set ::vdpstate_lines {}
    lappend ::vdpstate_lines [format "BOOT=%s,%s,%04X,%04X,%04X,%04X,%02X,%02X" \
        [live_registers] [shadow_registers] \
        [word_at 0xF922] [word_at 0xF924] [word_at 0xF926] [word_at 0xF928] \
        [peek 0xFCAF] [peek 0xF3B0]]
    invoke_bios 0x0041 disscr_done
}

proc disscr_done {} {
    lappend ::vdpstate_lines [format "DISSCR=%02X,%02X" \
        [debug read "VDP regs" 1] [peek 0xF3E0]]
    invoke_bios 0x0044 enascr_done
}

proc enascr_done {} {
    lappend ::vdpstate_lines [format "ENASCR=%02X,%02X" \
        [debug read "VDP regs" 1] [peek 0xF3E0]]
    reg B 0x08
    reg C 2
    invoke_bios 0x0047 wrtvdp_done
}

proc wrtvdp_done {} {
    lappend ::vdpstate_lines [format "WRTVDP=%02X,%02X" \
        [debug read "VDP regs" 2] [peek 0xF3E1]]
    invoke_bios 0x006C initxt_done
}

proc initxt_done {} {
    lappend ::vdpstate_lines [format "INITXT=%s,%s,%04X,%04X,%04X,%04X,%02X,%02X" \
        [live_registers] [shadow_registers] \
        [word_at 0xF922] [word_at 0xF924] [word_at 0xF926] [word_at 0xF928] \
        [peek 0xFCAF] [peek 0xF3B0]]
    invoke_bios 0x006F init32_done
}

proc init32_done {} {
    lappend ::vdpstate_lines [format "INIT32=%s,%s,%04X,%04X,%04X,%04X,%02X,%02X" \
        [live_registers] [shadow_registers] \
        [word_at 0xF922] [word_at 0xF924] [word_at 0xF926] [word_at 0xF928] \
        [peek 0xFCAF] [peek 0xF3B0]]
    invoke_bios 0x0072 initgrp_done
}

proc initgrp_done {} {
    lappend ::vdpstate_lines [format "INITGRP=%s,%s,%04X,%04X,%04X,%04X,%02X,%02X" \
        [live_registers] [shadow_registers] \
        [word_at 0xF922] [word_at 0xF924] [word_at 0xF926] [word_at 0xF928] \
        [peek 0xFCAF] [peek 0xF3B0]]
    record_vdpstate [join $::vdpstate_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
