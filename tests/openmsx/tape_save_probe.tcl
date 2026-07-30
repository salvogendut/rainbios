# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists tape_save_output]} {
    set tape_save_output /tmp/rainbios-tape-save.txt
}
if {![info exists tape_save_image]} {
    set tape_save_image /tmp/rainbios-tape-save.wav
}

proc write_tape_save_report {status} {
    cassetteplayer eject
    set handle [open $::tape_save_output w]
    puts $handle "STATUS=$status"
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "MARKER=%02X" [peek 0xF3AC]]
    if {[file exists $::tape_save_image]} {
        puts $handle "TAPE_SIZE=[file size $::tape_save_image]"
    } else {
        puts $handle "TAPE_SIZE=0"
    }
    puts $handle [get_screen]
    close $handle
}

proc tape_save_succeeded {} {
    write_tape_save_report SUCCESS
    exit
}

proc tape_save_failed {} {
    write_tape_save_report FAILURE
    exit
}

proc tape_save_prompt_ready {} {
    debug remove_bp $::tape_save_prompt_breakpoint
    cassetteplayer new $::tape_save_image
    poke 0xF3A4 0xFF
    type_via_keybuf "10 ?&F3AC=90:PRINT \"SAVE OK\"\rSAVE \"SAVET\"\r"
}

proc tape_save_returned {} {
    debug remove_bp $::tape_save_return_breakpoint
    type_via_keybuf "?&F3AC=90\r"
}

if {[get_pluggable_for_connector cassetteport] eq ""} {
    plug cassetteport cassetteplayer
}
set ::tape_save_prompt_breakpoint [
    debug set_bp 0x09D0 \
        {[lindex [get_selected_slot 1] 0] == 1} \
        {tape_save_prompt_ready}
]
set ::tape_save_return_breakpoint [
    debug set_bp 0x4B04 \
        {[lindex [get_selected_slot 1] 0] == 1} \
        {tape_save_returned}
]
debug set_bp 0x4400 \
    {[lindex [get_selected_slot 1] 0] == 2} \
    {tape_save_succeeded}
debug set_bp 0x4300 \
    {[lindex [get_selected_slot 1] 0] == 2} \
    {tape_save_failed}

after realtime 30 {
    write_tape_save_report TIMEOUT
    exit
}
