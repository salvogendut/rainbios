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
    keymatrixdown 6 0x08
    after time 0.05 {keymatrixup 6 0x08}
    after time 0.10 caps_on_a_press
}

proc caps_on_a_press {} {
    keymatrixdown 2 0x40
    after time 0.05 {keymatrixup 2 0x40}
    after time 0.10 {invoke_bios 0x009F caps_on_read}
}

proc caps_on_read {} {
    record_keyboard [format "CAPSON=%02X" [reg A]]
    keymatrixdown 6 0x08
    after time 0.05 {keymatrixup 6 0x08}
    after time 0.10 caps_off_a_press
}

proc caps_off_a_press {} {
    keymatrixdown 2 0x40
    after time 0.05 {keymatrixup 2 0x40}
    after time 0.10 {invoke_bios 0x009F caps_off_read}
}

proc caps_off_read {} {
    record_keyboard [format "CAPSOFF=%02X" [reg A]]
    # ---- M3 break / function-key / auto-repeat slice ----
    # FNKSTR holds the default "LIST" prefix after boot + INIFNK
    record_keyboard [format "FNK=%02X,%02X,%02X" \
        [peek 0xF87F] [peek 0xF880] [peek 0xF881]]
    record_keyboard [format "CNSDFG=%02X" [peek 0xF3DE]]
    reg F 0
    invoke_bios 0x00B7 breakx_clear_done
}

proc breakx_clear_done {} {
    record_keyboard [format "BREAKX0=%d" [expr {[reg F] & 1}]]
    reg F 0
    invoke_bios 0x00BA iscntc_clear_done
}

proc iscntc_clear_done {} {
    record_keyboard [format "ISCNTC0=%d" [expr {[reg F] & 1}]]
    # hold CTRL+STOP so KEYINT latches a break
    keymatrixdown 6 0x80
    keymatrixdown 7 0x08
    after time 0.05 breakx_pressed
}

proc breakx_pressed {} {
    reg F 0
    invoke_bios 0x00B7 breakx_pressed_done
}

proc breakx_pressed_done {} {
    record_keyboard [format "BREAKX1=%d" [expr {[reg F] & 1}]]
    keymatrixup 6 0x80
    keymatrixup 7 0x08
    reg F 0
    invoke_bios 0x00BA iscntc_break_done
}

proc iscntc_break_done {} {
    record_keyboard [format "ISCNTC1=%d,%02X" \
        [expr {[reg F] & 1}] [peek 0xFC9B]]
    reg F 0
    invoke_bios 0x00BA iscntc_drained_done
}

proc iscntc_drained_done {} {
    record_keyboard [format "ISCNTC2=%d" [expr {[reg F] & 1}]]
    invoke_bios 0x00CC erafnk_done
}

proc erafnk_done {} {
    record_keyboard [format "ERAFNK=%02X" [peek 0xF3DE]]
    invoke_bios 0x00CF dspfnk_done
}

proc dspfnk_done {} {
    record_keyboard [format "DSPFNK=%02X" [peek 0xF3DE]]
    invoke_bios 0x00C9 fnksb_done
}

proc fnksb_done {} {
    record_keyboard [format "FNKSB=%02X" [peek 0xF3DE]]
    invoke_bios 0x00D2 totext_done
}

proc totext_done {} {
    record_keyboard [format "TOTEXT=%02X,%02X" [peek 0xFCAF] [peek 0xF3DE]]
    # hold 'a' (row 2 bit 6) well past the repeat delay
    keymatrixdown 2 0x40
    after time 2.0 repeat_release
}

proc repeat_release {} {
    keymatrixup 2 0x40
    after time 0.05 repeat_count
}

proc repeat_count {} {
    record_keyboard [format "REPEAT=%02X,%02X,%02X" \
        [peek 0xFBF0] [peek 0xFBF1] [peek 0xFBF2]]
    # ---- M3 line-input slice ----
    # PINLIN "abc" + Return from a seeded buffer
    seed_buffer {0x61 0x62 0x63 0x0D}
    invoke_bios 0x00AE pinlin_abc_done
}

proc seed_buffer {chars} {
    set i 0
    foreach ch $chars {
        poke [expr {0xFBF0 + $i}] $ch
        incr i
    }
    poke 0xF3F8 [expr {(0xFBF0 + $i) & 0xFF}]
    poke 0xF3F9 [expr {(0xFBF0 + $i) >> 8}]
    poke 0xF3FA 0xF0
    poke 0xF3FB 0xFB
}

proc pinlin_abc_done {} {
    record_keyboard [format "PINLIN=%02X,%d,%02X,%02X,%02X" \
        [reg B] [expr {[reg F] & 1}] \
        [peek 0xF55E] [peek 0xF55F] [peek 0xF560]]
    # PINLIN "ab" + Backspace + "c" + Return -> "ac"
    seed_buffer {0x61 0x62 0x08 0x63 0x0D}
    invoke_bios 0x00AE pinlin_bs_done
}

proc pinlin_bs_done {} {
    record_keyboard [format "PINLINBS=%02X,%02X,%02X" \
        [reg B] [peek 0xF55E] [peek 0xF55F]]
    # QINLIN seeds the prompt and returns "?" + space + "abc"
    seed_buffer {0x61 0x62 0x63 0x0D}
    invoke_bios 0x00B4 qinlin_done
}

proc qinlin_done {} {
    record_keyboard [format "QINLIN=%02X,%d,%02X,%02X,%02X,%02X" \
        [reg B] [expr {[reg F] & 1}] \
        [peek 0xF55E] [peek 0xF55F] [peek 0xF560] [peek 0xF6AA]]
    # PINLIN ends with carry set on a Ctrl-STOP break
    seed_buffer {}
    keymatrixdown 6 0x80
    keymatrixdown 7 0x08
    invoke_bios 0x00AE pinlin_break_done
    after time 0.10 {keymatrixup 6 0x80; keymatrixup 7 0x08}
}

proc pinlin_break_done {} {
    record_keyboard [format "PINLINBRK=%02X,%d" [reg B] [expr {[reg F] & 1}]]
    invoke_bios 0x00C0 beep_done
}

proc beep_done {} {
    record_keyboard "BEEP=OK"
    exit
}

after time 1.0 start_probe
after realtime 15 exit
