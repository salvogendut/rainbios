# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists screend_output]} {
    set screend_output /tmp/rainbios-screend.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::screend_callback $callback
    set ::screend_breakpoint [
        debug set_bp $sentinel {} {screend_call_returned}
    ]
    reg PC $address
}

proc screend_call_returned {} {
    debug remove_bp $::screend_breakpoint
    set callback $::screend_callback
    uplevel #0 $callback
}

proc vram_registers {} {
    format "%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X" \
        [debug read "VDP regs" 0] [debug read "VDP regs" 1] \
        [debug read "VDP regs" 2] [debug read "VDP regs" 3] \
        [debug read "VDP regs" 4] [debug read "VDP regs" 5] \
        [debug read "VDP regs" 6] [debug read "VDP regs" 7]
}

proc record_screend {line} {
    set handle [open $::screend_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    set ::screend_lines {}
    invoke_bios 0x006C initxt_done
}

proc initxt_done {} {
    lappend ::screend_lines [format "INITXT=%s,%02X,%02X" [vram_registers] [peek 0xFCAF] [peek 0xF3B0]]
    invoke_bios 0x006F init32_done
}

proc init32_done {} {
    lappend ::screend_lines [format "INIT32=%s,%02X,%02X" [vram_registers] [peek 0xFCAF] [peek 0xF3B0]]
    invoke_bios 0x0072 initgrp_done
}

proc initgrp_done {} {
    lappend ::screend_lines [format "INITGRP=%s,%02X,%02X" [vram_registers] [peek 0xFCAF] [peek 0xF3B0]]
    # SETTXT must reproduce the INITXT mode state without touching the tables.
    debug write VRAM 0x0000 0x55
    poke 0xF3DC 7
    poke 0xF3DD 9
    invoke_bios 0x0078 settxt_done
}

proc settxt_done {} {
    lappend ::screend_lines [format "SETTXT=%s,%02X,%02X,%02X,%02X,%02X" \
        [vram_registers] [peek 0xFCAF] [peek 0xF3B0] \
        [debug read VRAM 0x0000] [peek 0xF3DC] [peek 0xF3DD]]
    invoke_bios 0x007B sett32_done
}

proc sett32_done {} {
    lappend ::screend_lines [format "SETT32=%s,%02X,%02X" \
        [vram_registers] [peek 0xFCAF] [peek 0xF3B0]]
    invoke_bios 0x007E setgrp_done
}

proc setgrp_done {} {
    lappend ::screend_lines [format "SETGRP=%s,%02X,%02X" \
        [vram_registers] [peek 0xFCAF] [peek 0xF3B0]]
    record_screend [join $::screend_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
