# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists invalid_payload_output]} {
    set invalid_payload_output /tmp/rainbios-invalid-payload.txt
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc record_invalid_payload {line} {
    lappend ::invalid_payload_lines $line
    set handle [open $::invalid_payload_output w]
    puts $handle [join $::invalid_payload_lines "\n"]
    close $handle
}

proc inspect_invalid_discovery {} {
    set ::invalid_payload_lines {}
    record_invalid_payload [
        format "DISCOVERY=%02X,%04X,%02X%02X%02X%02X,%d" \
            [peek 0xF393] [word_at 0xF394] \
            [peek 0xF300] [peek 0xF301] [peek 0xF302] [peek 0xF303] \
            [lindex [get_selected_slot 1] 0]
    ]
    keymatrixdown 8 0x01
    after time 0.10 {keymatrixup 8 0x01}
    after time 0.40 inspect_invalid_menu
}

proc inspect_invalid_menu {} {
    set text [get_screen]
    record_invalid_payload [
        format "MENU=%d,%d" \
            [peek 0xFCAF] \
            [expr {[string first "NO VALID BASIC PAYLOAD" $text] >= 0}]
    ]
    keymatrixdown 0 0x08
    after time 0.10 {keymatrixup 0 0x08}
    after time 0.40 inspect_invalid_guard
}

proc inspect_invalid_guard {} {
    record_invalid_payload [
        format "GUARDED=%d,%02X%02X%02X%02X" \
            [lindex [get_selected_slot 1] 0] \
            [peek 0xF300] [peek 0xF301] [peek 0xF302] [peek 0xF303]
    ]
    exit
}

after time 1.00 inspect_invalid_discovery
after realtime 15 exit
