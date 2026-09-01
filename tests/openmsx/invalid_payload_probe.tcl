# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists invalid_payload_output]} {
    set invalid_payload_output /tmp/rainbios-invalid-payload.txt
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc record_invalid_payload {line} {
    set handle [open $::invalid_payload_output w]
    puts $handle $line
    close $handle
}

proc capture_internal_fallback {} {
    debug remove_bp $::internal_fallback_breakpoint
    record_invalid_payload [
        format "FALLBACK=%02X,%04X,%02X%02X%02X%02X,%d" \
            [peek 0xF301] [word_at 0xF302] \
            [peek 0xF300] [peek 0xF301] [peek 0xF302] [peek 0xF303] \
            [lindex [get_selected_slot 1] 0]
    ]
    exit
}

set ::internal_fallback_breakpoint [
    debug set_bp 0x4010 {[lindex [get_selected_slot 1] 0] == 3} \
        {capture_internal_fallback}
]
after realtime 15 exit
