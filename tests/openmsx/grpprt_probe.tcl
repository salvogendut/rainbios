# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists grpprt_output]} {
    set grpprt_output /tmp/rainbios-grpprt.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::grpprt_callback $callback
    set ::grpprt_breakpoint [
        debug set_bp $sentinel {} {grpprt_call_returned}
    ]
    reg PC $address
}

proc grpprt_call_returned {} {
    debug remove_bp $::grpprt_breakpoint
    set callback $::grpprt_callback
    uplevel #0 $callback
}

proc record_grpprt {line} {
    set handle [open $::grpprt_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    set ::grpprt_lines {}
    invoke_bios 0x0072 initgrp_done
}

proc initgrp_done {} {
    # Print 'A' at row 3, column 2 in Screen 2.
    poke 0xF3DC 3
    poke 0xF3DD 2
    reg A 0x41
    invoke_bios 0x008D grpprt_a_done
}

proc grpprt_a_done {} {
    lappend ::grpprt_lines [format "GLYPH=%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X" \
        [debug read VRAM 0x208] [debug read VRAM 0x209] \
        [debug read VRAM 0x20A] [debug read VRAM 0x20B] \
        [debug read VRAM 0x20C] [debug read VRAM 0x20D] \
        [debug read VRAM 0x20E] [debug read VRAM 0x20F]]
    lappend ::grpprt_lines [format "COLOR=%02X" [debug read VRAM 0x2208]]
    lappend ::grpprt_lines [format "ADVANCE=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    reg A 0x0D
    invoke_bios 0x008D grpprt_cr_done
}

proc grpprt_cr_done {} {
    lappend ::grpprt_lines [format "CR=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    reg A 0x0A
    invoke_bios 0x008D grpprt_lf_done
}

proc grpprt_lf_done {} {
    lappend ::grpprt_lines [format "LF=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    record_grpprt [join $::grpprt_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
