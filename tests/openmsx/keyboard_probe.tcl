# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists keyboard_output]} {
    set keyboard_output /tmp/rainbios-keyboard.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::keyboard_callback $callback
    set ::keyboard_breakpoint [
        debug set_bp $sentinel {} {keyboard_call_returned}
    ]
    reg PC $address
}

proc keyboard_call_returned {} {
    debug remove_bp $::keyboard_breakpoint
    set callback $::keyboard_callback
    uplevel #0 $callback
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc record_keyboard {line} {
    lappend ::keyboard_lines $line
    set handle [open $::keyboard_output w]
    puts $handle [join $::keyboard_lines "\n"]
    close $handle
}

proc start_probe {} {
    set ::keyboard_lines {}
    foreach {address value} {
        0xF300 0xFB  0xF301 0x76  0xF302 0xC3
        0xF303 0x00  0xF304 0xF3
    } {
        poke $address $value
    }
    record_keyboard [
        format "INIT=%04X,%04X,%02X,%02X" \
            [word_at 0xF3F8] [word_at 0xF3FA] \
            [peek 0xFBDA] [peek 0xFBE5]
    ]
    invoke_bios 0x0156 kilbuf_done
}

proc kilbuf_done {} {
    invoke_bios 0x009C empty_done
}

proc empty_done {} {
    record_keyboard [
        format "EMPTY=%d,%04X,%04X" \
            [expr {([reg F] & 0x40) != 0}] \
            [word_at 0xF3F8] [word_at 0xF3FA]
    ]
    keymatrixdown 6 0x01
    keymatrixdown 2 0x40
    after time 0.05 sample_shift_a
    after time 0.10 release_shift_a
    after time 0.15 shifted_a_ready
}

proc sample_shift_a {} {
    reg A 2
    invoke_bios 0x0141 matrix_sampled
}

proc matrix_sampled {} {
    record_keyboard [
        format "MATRIX=%02X,%02X,%02X,%04X" \
            [reg A] [peek 0xFBDC] [peek 0xFBE7] [word_at 0xF3F8]
    ]
}

proc release_shift_a {} {
    keymatrixup 2 0x40
    keymatrixup 6 0x01
}

proc shifted_a_ready {} {
    invoke_bios 0x009C ready_done
}

proc ready_done {} {
    record_keyboard [
        format "READY=%d,%04X" \
            [expr {([reg F] & 0x40) == 0}] [word_at 0xF3F8]
    ]
    reg BC 0x1234
    reg DE 0x5678
    reg HL 0x9ABC
    invoke_bios 0x009F shifted_a_read
}

proc shifted_a_read {} {
    record_keyboard [
        format "CHAR=%02X,%04X,%04X,%04X" \
            [reg A] [reg BC] [reg DE] [reg HL]
    ]
    invoke_bios 0x009C drained_done
}

proc drained_done {} {
    record_keyboard [
        format "DRAINED=%d,%04X,%04X" \
            [expr {([reg F] & 0x40) != 0}] \
            [word_at 0xF3F8] [word_at 0xF3FA]
    ]
    keymatrixdown 8 0x01
    after time 0.05 {keymatrixup 8 0x01}
    after time 0.10 {invoke_bios 0x0156 killed_buffer}
}

proc killed_buffer {} {
    invoke_bios 0x009C killed_buffer_status
}

proc killed_buffer_status {} {
    record_keyboard [
        format "KILLED=%d,%04X,%04X" \
            [expr {([reg F] & 0x40) != 0}] \
            [word_at 0xF3F8] [word_at 0xF3FA]
    ]
    invoke_bios 0x009F blocking_wait
    after time 0.10 {keymatrixdown 7 0x80}
    after time 0.20 {keymatrixup 7 0x80}
}

proc blocking_wait {} {
    record_keyboard [format "BLOCKING=%02X" [reg A]]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
