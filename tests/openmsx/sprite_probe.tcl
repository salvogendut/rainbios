# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists sprite_output]} {
    set sprite_output /tmp/rainbios-sprite.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::sprite_callback $callback
    set ::sprite_breakpoint [
        debug set_bp $sentinel {} {sprite_call_returned}
    ]
    reg PC $address
}

proc sprite_call_returned {} {
    debug remove_bp $::sprite_breakpoint
    set callback $::sprite_callback
    uplevel #0 $callback
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc record_sprite {line} {
    set handle [open $::sprite_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    set ::sprite_lines {}
    invoke_bios 0x0072 initgrp_done
}

proc initgrp_done {} {
    lappend ::sprite_lines [format "BASES=%04X,%04X,%02X" \
        [word_at 0xF926] [word_at 0xF928] [peek 0xF3E9]]
    reg A 0
    invoke_bios 0x008A gspsiz_small_done
}

proc gspsiz_small_done {} {
    lappend ::sprite_lines [format "GSPSIZ0=%02X,%d,%02X" \
        [reg A] [expr {[reg F] & 1}] [peek 0xF3E0]]
    reg A 1
    invoke_bios 0x008A gspsiz_big_done
}

proc gspsiz_big_done {} {
    lappend ::sprite_lines [format "GSPSIZ1=%02X,%d,%02X" \
        [reg A] [expr {[reg F] & 1}] [peek 0xF3E0]]
    reg A 5
    invoke_bios 0x0084 calpat_big_done
}

proc calpat_big_done {} {
    lappend ::sprite_lines [format "CALPAT16=%04X" [reg HL]]
    reg A 0
    invoke_bios 0x008A gspsiz_small2_done
}

proc gspsiz_small2_done {} {
    reg A 5
    invoke_bios 0x0084 calpat_small_done
}

proc calpat_small_done {} {
    lappend ::sprite_lines [format "CALPAT8=%04X" [reg HL]]
    reg A 7
    invoke_bios 0x0087 calatr_done
}

proc calatr_done {} {
    lappend ::sprite_lines [format "CALATR7=%04X" [reg HL]]
    invoke_bios 0x0069 clrspr_done
}

proc clrspr_done {} {
    lappend ::sprite_lines [format "ATR0=%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X" \
        [debug read VRAM 0x1B00] [debug read VRAM 0x1B01] \
        [debug read VRAM 0x1B02] [debug read VRAM 0x1B03] \
        [debug read VRAM 0x1B7C] [debug read VRAM 0x1B7D] \
        [debug read VRAM 0x1B7E] [debug read VRAM 0x1B7F]]
    lappend ::sprite_lines [format "PAT=%02X,%02X" \
        [debug read VRAM 0x3800] [debug read VRAM 0x38FF]]
    record_sprite [join $::sprite_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
