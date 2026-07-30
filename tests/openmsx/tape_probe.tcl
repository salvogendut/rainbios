# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists tape_output]} {
    set tape_output /tmp/rainbios-tape.txt
}
proc write_tape_report {} {
    set handle [open $::tape_output w]
    puts $handle [
        format "MARKER=%02X,%02X,%02X,%02X" \
            [peek 0xF300] [peek 0xF301] [peek 0xF302] [peek 0xF303]
    ]
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "PERIOD=%02X" [peek 0xF398]]
    puts $handle "POSITION=[cassetteplayer getpos]"
    puts $handle "LENGTH=[cassetteplayer getlength]"
    puts $handle [
        format "TRACE=%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X" \
            [peek 0xF310] [peek 0xF311] [peek 0xF312] [peek 0xF313] \
            [peek 0xF314] [peek 0xF315] [peek 0xF316] [peek 0xF317]
    ]
    close $handle
}

after time 8.00 {
    write_tape_report
    exit
}

after realtime 30 {
    write_tape_report
    exit
}
