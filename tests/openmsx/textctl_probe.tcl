# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists textctl_output]} {
    set textctl_output /tmp/rainbios-textctl.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::textctl_callback $callback
    set ::textctl_breakpoint [
        debug set_bp $sentinel {} {textctl_call_returned}
    ]
    reg PC $address
}

proc textctl_call_returned {} {
    debug remove_bp $::textctl_breakpoint
    set callback $::textctl_callback
    uplevel #0 $callback
}

proc record_textctl {line} {
    set handle [open $::textctl_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    set ::textctl_lines {}
    invoke_bios 0x006C initxt_done
}

proc initxt_done {} {
    # Tab from column 1 advances to the 8-column tab stop at column 9.
    poke 0xF3DC 2
    poke 0xF3DD 1
    reg A 0x09
    invoke_bios 0x00A2 tab1_done
}

proc tab1_done {} {
    lappend ::textctl_lines [format "TAB1=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    # Tab from the line end wraps to the next row.
    poke 0xF3DC 2
    poke 0xF3DD 40
    reg A 0x09
    invoke_bios 0x00A2 tab2_done
}

proc tab2_done {} {
    lappend ::textctl_lines [format "TAB2=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    # Cursor up moves one row; at the top row it stays.
    poke 0xF3DC 5
    poke 0xF3DD 3
    reg A 0x0B
    invoke_bios 0x00A2 up1_done
}

proc up1_done {} {
    lappend ::textctl_lines [format "UP1=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    poke 0xF3DC 1
    poke 0xF3DD 3
    reg A 0x0B
    invoke_bios 0x00A2 up2_done
}

proc up2_done {} {
    lappend ::textctl_lines [format "UP2=%02X,%02X" [peek 0xF3DC] [peek 0xF3DD]]
    # Form feed clears the name table and homes the cursor.
    debug write VRAM 0x0000 0x41
    poke 0xF3DC 7
    poke 0xF3DD 9
    reg A 0x0C
    invoke_bios 0x00A2 ff_done
}

proc ff_done {} {
    lappend ::textctl_lines [format "FF=%02X,%02X,%02X" \
        [peek 0xF3DC] [peek 0xF3DD] [debug read VRAM 0x0000]]
    # Nextor selects the overwrite cursor with ESC x 4. The sequence must be
    # consumed rather than appearing as literal "x4" on the command line.
    poke 0xFCAA 1
    reg A 0x1B
    invoke_bios 0x00A2 esc_start_done
}

proc esc_start_done {} {
    reg A 0x78
    invoke_bios 0x00A2 esc_x_done
}

proc esc_x_done {} {
    reg A 0x34
    invoke_bios 0x00A2 esc_x4_done
}

proc esc_x4_done {} {
    lappend ::textctl_lines [format "ESCX4=%02X,%02X" \
        [peek 0xFCA7] [peek 0xFCAA]]
    # ESC K clears from the cursor through the end of the current text row
    # without changing the one-based cursor coordinates.
    for {set address 80} {$address < 120} {incr address} {
        debug write VRAM $address 0x41
    }
    poke 0xF3DC 3
    poke 0xF3DD 4
    reg A 0x1B
    invoke_bios 0x00A2 esc_k_start_done
}

proc esc_k_start_done {} {
    reg A 0x4B
    invoke_bios 0x00A2 esc_k_done
}

proc esc_k_done {} {
    lappend ::textctl_lines [format "ESCK=%02X,%02X,%02X,%02X,%02X" \
        [peek 0xF3DC] [peek 0xF3DD] \
        [debug read VRAM 82] [debug read VRAM 83] [debug read VRAM 119]]
    # DEL destructively removes the cell to the left and leaves the cursor
    # over the newly blank cell, as expected by Nextor's line editor.
    debug write VRAM 124 0x41
    poke 0xF3DC 4
    poke 0xF3DD 6
    reg A 0x7F
    invoke_bios 0x00A2 del_done
}

proc del_done {} {
    lappend ::textctl_lines [format "DEL=%02X,%02X,%02X" \
        [peek 0xF3DC] [peek 0xF3DD] [debug read VRAM 124]]
    poke 0xF3DC 5
    poke 0xF3DD 6
    reg A 0x1D
    invoke_bios 0x00A2 left_done
}

proc left_done {} {
    lappend ::textctl_lines [format "LEFT=%02X,%02X" \
        [peek 0xF3DC] [peek 0xF3DD]]
    record_textctl [join $::textctl_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
