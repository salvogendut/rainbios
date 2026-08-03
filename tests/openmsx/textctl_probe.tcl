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
    record_textctl [join $::textctl_lines "\n"]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
