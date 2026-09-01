# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists payload_state_output]} {
    set payload_state_output /tmp/rainbios-payload-state.txt
}

proc primary_map {} {
    expr {[debug read "ioports" 0xA8] & 0xFF}
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc capture_payload_entry {} {
    # The breakpoint fires with the CPU paused at the first payload
    # instruction, so the registers reflect the documented launch state.
    set ::entry_jiffy [word_at 0xFC9E]
    set ::payload_lines [list \
        [format "PC=%04X" [reg PC]] \
        [format "SP=%04X" [reg SP]] \
        [format "AF=%02X,%02X" [reg A] [reg F]] \
        [format "BC=%04X" [reg BC]] \
        [format "DE=%04X" [reg DE]] \
        [format "HL=%04X" [reg HL]] \
        [format "IX=%04X" [reg IX]] \
        [format "IY=%04X" [reg IY]] \
        [format "SLOT=%02X" [primary_map]] \
        [format "BUF=%04X,%04X" [word_at 0xF3F8] [word_at 0xF3FA]]]
    debug remove_bp $::payload_breakpoint
    # Let the payload run a couple of frames; JIFFY must advance, proving the
    # interrupt source and IM1/EI state are live at the transfer.
    after time 2.00 check_payload_running
}

proc check_payload_running {} {
    set jiffy [word_at 0xFC9E]
    set advanced [expr {$jiffy > $::entry_jiffy ? 1 : 0}]
    lappend ::payload_lines [format "JIFFY=%04X,%d" $jiffy $advanced]
    set handle [open $::payload_state_output w]
    puts $handle [join $::payload_lines "\n"]
    close $handle
    exit
}

set ::payload_breakpoint [debug set_bp 0x4010 {} {capture_payload_entry}]
after realtime 15 exit
