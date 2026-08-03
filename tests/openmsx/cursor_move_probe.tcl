# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists cursor_output]} {
    set cursor_output /tmp/rainbios-cursor.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::cursor_callback $callback
    set ::cursor_breakpoint [
        debug set_bp $sentinel {} {cursor_call_returned}
    ]
    reg PC $address
}

proc cursor_call_returned {} {
    debug remove_bp $::cursor_breakpoint
    set callback $::cursor_callback
    uplevel #0 $callback
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc record_cursor {line} {
    set handle [open $::cursor_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    invoke_bios 0x006C initxt_done
}

proc initxt_done {} {
    set ::cursor_lines {}
    lappend ::cursor_lines [
        format "INITXT=%02X,%02X,%02X" \
            [peek 0xFCAF] [peek 0xF3B0] [peek 0xF3B1]
    ]
    poke 0xF3DC 5
    poke 0xF3DD 5
    invoke_bios 0x00FC right_done
}

proc right_done {} {
    lappend ::cursor_lines [format "RIGHTC=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    poke 0xF3DC 5
    poke 0xF3DD 40
    invoke_bios 0x00FC right_edge_done
}

proc right_edge_done {} {
    lappend ::cursor_lines [format "RIGHTEDGE=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    poke 0xF3DC 5
    poke 0xF3DD 5
    invoke_bios 0x00FF left_done
}

proc left_done {} {
    lappend ::cursor_lines [format "LEFTC=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    poke 0xF3DC 5
    poke 0xF3DD 1
    invoke_bios 0x00FF left_edge_done
}

proc left_edge_done {} {
    lappend ::cursor_lines [format "LEFTEDGE=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    poke 0xF3DC 5
    poke 0xF3DD 5
    invoke_bios 0x0102 up_done
}

proc up_done {} {
    lappend ::cursor_lines [format "UPC=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    poke 0xF3DC 1
    poke 0xF3DD 5
    invoke_bios 0x0102 up_edge_done
}

proc up_edge_done {} {
    lappend ::cursor_lines [format "UPEDGE=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    poke 0xF3DC 5
    poke 0xF3DD 5
    invoke_bios 0x0108 down_done
}

proc down_done {} {
    lappend ::cursor_lines [format "DOWNC=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    poke 0xF3DC 24
    poke 0xF3DD 5
    invoke_bios 0x0108 down_edge_done
}

proc down_edge_done {} {
    lappend ::cursor_lines [format "DOWNEDGE=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    # TUPC at the top row scrolls the text down: seed row 1 with 'X', the
    # cursor stays at row 1 and 'X' moves to row 2.
    poke 0xF3DC 1
    poke 0xF3DD 1
    debug write "VRAM" 0x0000 0x58
    invoke_bios 0x0105 tupc_done
}

proc tupc_done {} {
    lappend ::cursor_lines [format "TUPC=%02X,%02X,%02X,%02X" \
        [peek 0xF3DC] [peek 0xF3DD] \
        [debug read "VRAM" 0x0000] [debug read "VRAM" 0x0028]]
    # TDOWNC at the bottom row scrolls the text up: seed row 24 with 'Y',
    # the cursor stays at row 24 and 'Y' moves to row 23.
    poke 0xF3DC 24
    poke 0xF3DD 1
    debug write "VRAM" 0x0398 0x59
    invoke_bios 0x010B tdownc_done
}

proc tdownc_done {} {
    lappend ::cursor_lines [format "TDOWNC=%02X,%02X,%02X,%02X" \
        [peek 0xF3DC] [peek 0xF3DD] \
        [debug read "VRAM" 0x0370] [debug read "VRAM" 0x0398]]
    set handle [open $::cursor_output w]
    puts $handle [join $::cursor_lines "\n"]
    close $handle
    exit
}

after time 1.0 start_probe
after realtime 15 exit
