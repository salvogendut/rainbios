# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists color_output]} {
    set color_output /tmp/rainbios-color.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::color_callback $callback
    set ::color_breakpoint [
        debug set_bp $sentinel {} {color_call_returned}
    ]
    reg PC $address
}

proc color_call_returned {} {
    debug remove_bp $::color_breakpoint
    set callback $::color_callback
    uplevel #0 $callback
}

proc record_color {line} {
    set handle [open $::color_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    set ::color_lines {}
    lappend ::color_lines [format "BOOT=%02X,%02X,%02X,%02X" \
        [debug read "VDP regs" 7] [peek 0xF3E9] [peek 0xF3EA] [peek 0xF3EB]]
    # Screen 0: CHGCLR with FORCLR=5, BAKCLR=1, BDRCLR=4.
    invoke_bios 0x006C initxt_done
}

proc initxt_done {} {
    poke 0xF3E9 5
    poke 0xF3EA 1
    poke 0xF3EB 4
    invoke_bios 0x0062 chgclr_s0_done
}

proc chgclr_s0_done {} {
    lappend ::color_lines [format "S0=%02X,%02X" \
        [debug read "VDP regs" 7] [peek 0xF3E6]]
    # Screen 1: same colors; R7 becomes BDRCLR and the color table is filled.
    invoke_bios 0x006F init32_done
}

proc init32_done {} {
    poke 0xF3E9 5
    poke 0xF3EA 1
    poke 0xF3EB 4
    invoke_bios 0x0062 chgclr_s1_done
}

proc chgclr_s1_done {} {
    lappend ::color_lines [format "S1=%02X,%02X,%02X" \
        [debug read "VDP regs" 7] [debug read VRAM 0x2000] [debug read VRAM 0x2001]]
    # Screen 2: same colors; R7 becomes BDRCLR.
    invoke_bios 0x0072 initgrp_done
}

proc initgrp_done {} {
    poke 0xF3E9 5
    poke 0xF3EA 1
    poke 0xF3EB 4
    invoke_bios 0x0062 chgclr_s2_done
}

proc chgclr_s2_done {} {
    lappend ::color_lines [format "S2=%02X,%02X" \
        [debug read "VDP regs" 7] [peek 0xF3E6]]
    record_color [join $::color_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
