# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists payload_menu_output]} {
    set payload_menu_output /tmp/rainbios-payload-menu.txt
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc primary_map {} {
    expr {[debug read "ioports" 0xA8] & 0xFF}
}

proc record_payload_menu {line} {
    lappend ::payload_menu_lines $line
    set handle [open $::payload_menu_output w]
    puts $handle [join $::payload_menu_lines "\n"]
    close $handle
}

proc inspect_discovery {} {
    set ::payload_menu_lines {}
    record_payload_menu [
        format "DISCOVERY=%02X,%04X,%d" \
            [peek 0xF393] [word_at 0xF394] \
            [lindex [get_selected_slot 1] 0]
    ]
    keymatrixdown 8 0x01
    after time 0.10 {keymatrixup 8 0x01}
    after time 0.40 inspect_menu
}

proc inspect_menu {} {
    set text [get_screen]
    record_payload_menu [
        format "MENU=%d,%d" \
            [peek 0xFCAF] \
            [expr {[string first "BBC BASIC PAYLOAD READY" $text] >= 0}]
    ]
    set ::payload_entry_breakpoint [
        debug set_bp 0x4010 {} {payload_entry_reached}
    ]
    keymatrixdown 0 0x08
    after time 0.10 {keymatrixup 0 0x08}
    after time 0.50 inspect_selection_stall
}

proc payload_entry_reached {} {
    debug remove_bp $::payload_entry_breakpoint
    record_payload_menu [
        format "LAUNCH=%02X,%04X,%02X,%04X,%04X,%04X,%04X,%04X" \
            [primary_map] [reg SP] [reg A] [reg BC] [reg DE] [reg HL] \
            [reg IX] [reg IY]
    ]
    exit
}

proc inspect_selection_stall {} {
    record_payload_menu [
        format "STALL=%04X,%02X,%04X,%04X,%02X" \
            [reg PC] [primary_map] [word_at 0xF3F8] [word_at 0xF3FA] \
            [peek 0xFBDA]
    ]
    exit
}

after time 1.00 inspect_discovery
after realtime 15 exit
