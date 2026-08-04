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
    reg IFF 1
    reg F 0
    invoke_bios 0x00B7 breakx_clear_done
}

proc breakx_clear_done {} {
    record_keyboard [format "BREAKX0=%d,%d" \
        [expr {[reg F] & 1}] [expr {([reg IFF] & 1) != 0}]]
    reg F 0
    invoke_bios 0x00BA iscntc_clear_done
}

proc iscntc_clear_done {} {
    record_keyboard [format "ISCNTC0=%d" [expr {[reg F] & 1}]]
    # hold CTRL+STOP so KEYINT latches a break
    keymatrixdown 6 0x02
    keymatrixdown 7 0x10
    after time 0.05 breakx_pressed
}

proc breakx_pressed {} {
    reg IFF 1
    reg F 0
    invoke_bios 0x00B7 breakx_pressed_done
}

proc breakx_pressed_done {} {
    record_keyboard [format "BREAKX1=%d,%d" \
        [expr {[reg F] & 1}] [expr {([reg IFF] & 1) != 0}]]
    keymatrixup 6 0x02
    keymatrixup 7 0x10
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
    poke 0xF3DD 0x07
    poke 0xF3DC 0x05
    set ::erafnk_first [expr {
        [word_at 0xF922] + ([peek 0xF3B1] - 1) * [peek 0xF3B0]
    }]
    set ::erafnk_last [expr {$::erafnk_first + [peek 0xF3B0] - 1}]
    debug write VRAM $::erafnk_first 0x41
    debug write VRAM $::erafnk_last 0x5A
    invoke_bios 0x00CC erafnk_done
}

proc erafnk_done {} {
    record_keyboard [format "ERAFNK=%02X,%02X,%02X,%02X,%02X" \
        [peek 0xF3DE] [peek 0xF3DD] [peek 0xF3DC] \
        [debug read VRAM $::erafnk_first] [debug read VRAM $::erafnk_last]]
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
    keymatrixdown 6 0x02
    keymatrixdown 7 0x10
    invoke_bios 0x00AE pinlin_break_done
    after time 0.10 {keymatrixup 6 0x02; keymatrixup 7 0x10}
}

proc pinlin_break_done {} {
    record_keyboard [format "PINLINBRK=%02X,%d" [reg B] [expr {[reg F] & 1}]]
    # The Ctrl-STOP keys release at +0.10; wait for them so the next input
    # does not break immediately.
    after time 0.20 pinlin_mid
}

proc pinlin_mid {} {
    # M3 mid-line editing: "abcd" + left,left + X (insert) + Backspace
    # (remove X) + Delete (remove c) + Home + Z (insert at start) + Return
    # -> "Zabd"
    seed_buffer {0x61 0x62 0x63 0x64 0x1d 0x1d 0x58 0x08 0x7f 0x0b 0x5a 0x0d}
    invoke_bios 0x00AE pinlin_mid_done
}

proc pinlin_mid_done {} {
    record_keyboard [format "PINLINMID=%02X,%d,%02X,%02X,%02X,%02X" \
        [reg B] [expr {[reg F] & 1}] \
        [peek 0xF55E] [peek 0xF55F] [peek 0xF560] [peek 0xF561]]
    # PINLIN "ab" + right + "X" + Return -> "abX" (right at the end appends)
    seed_buffer {0x61 0x62 0x1c 0x58 0x0d}
    invoke_bios 0x00AE pinlin_right_done
}

proc pinlin_right_done {} {
    record_keyboard [format "PINLINRIGHT=%02X,%d,%02X,%02X,%02X" \
        [reg B] [expr {[reg F] & 1}] \
        [peek 0xF55E] [peek 0xF55F] [peek 0xF560]]
    # Reset the buffer pointers so the dead-key output starts at FBF0 again.
    invoke_bios 0x0156 pinlin_right_killed
}

proc pinlin_right_killed {} {
    invoke_bios 0x00C0 beep_done
}

proc beep_done {} {
    record_keyboard "BEEP=OK"
    # M3 dead keys: grave ` + 'a' -> 0x85, acute ' + 'e' -> 0x82,
    # grave ` + 'b' -> 0x62 (not combinable), acute ' + 'y' -> 0x79
    # Hold each accent key long enough for a scan, then release before the
    # next key so DEADST latches before the letter edge arrives.
    after time 0.10 {keymatrixdown 2 0x02}
    after time 0.16 {keymatrixup 2 0x02}
    after time 0.24 {keymatrixdown 2 0x40}
    after time 0.30 {keymatrixup 2 0x40}
    after time 0.38 {keymatrixdown 2 0x01}
    after time 0.44 {keymatrixup 2 0x01}
    after time 0.52 {keymatrixdown 3 0x04}
    after time 0.58 {keymatrixup 3 0x04}
    after time 0.66 {keymatrixdown 2 0x02}
    after time 0.72 {keymatrixup 2 0x02}
    after time 0.80 {keymatrixdown 2 0x80}
    after time 0.86 {keymatrixup 2 0x80}
    after time 0.94 {keymatrixdown 2 0x01}
    after time 1.00 {keymatrixup 2 0x01}
    after time 1.08 {keymatrixdown 5 0x40}
    after time 1.14 {keymatrixup 5 0x40}
    after time 1.22 deadkey_done
}

proc deadkey_done {} {
    record_keyboard [format "DEADKEY=%02X,%02X,%02X,%02X" \
        [peek 0xFBF0] [peek 0xFBF1] [peek 0xFBF2] [peek 0xFBF3]]
    # M3 key click: with CLIKSW on, a key press drives the PPI click bit high
    # for a few frames, then low.
    poke 0xF3DB 1
    keymatrixdown 2 0x40
    after time 0.03 click_high
}

proc click_high {} {
    record_keyboard [format "CLICK1=%02X" \
        [expr {[debug read "ioports" 0xAA] & 0xFF}]]
    after time 0.05 click_low
}

proc click_low {} {
    keymatrixup 2 0x40
    record_keyboard [format "CLICK2=%02X" \
        [expr {[debug read "ioports" 0xAA] & 0xFF}]]
    # M3 cursor/edit-key contract: pressing every row-8 key together enqueues
    # SPACE/HOME/INSERT/DEL/LEFT/UP/DOWN/RIGHT in bit order, and CHGET returns
    # the standard MSX control codes (MSX2 Technical Handbook Appendix 8).
    invoke_bios 0x0156 cursor_edit_kilbuf
}

proc cursor_edit_kilbuf {} {
    keymatrixdown 8 0xFF
    after time 0.05 {keymatrixup 8 0xFF}
    after time 0.10 cursor_edit_read
}

proc cursor_edit_read {} {
    invoke_bios 0x009F [list cursor_edit_read_cb 0]
}

proc cursor_edit_read_cb {index} {
    record_keyboard [format "CURSOR%02X=%02X" $index [reg A]]
    incr index
    if {$index < 8} {
        invoke_bios 0x009F [list cursor_edit_read_cb $index]
    } else {
        edit_keys_start
    }
}

proc edit_keys_start {} {
    # Row 7 editing keys ESC/TAB/BS/CR (bits 2/3/5/7) give 1B/09/08/0D.
    # STOP (bit 4) is deliberately excluded: it latches a break.
    invoke_bios 0x0156 edit_keys_kilbuf
}

proc edit_keys_kilbuf {} {
    keymatrixdown 7 0xAC
    after time 0.05 {keymatrixup 7 0xAC}
    after time 0.10 edit_keys_read
}

proc edit_keys_read {} {
    invoke_bios 0x009F [list edit_keys_read_cb 0]
}

proc edit_keys_read_cb {index} {
    record_keyboard [format "EDIT%02X=%02X" $index [reg A]]
    incr index
    if {$index < 4} {
        invoke_bios 0x009F [list edit_keys_read_cb $index]
    } else {
        # M3 GICINI: after the PSG registers, the PLAY statement work area is
        # initialized (QUEUES -> QUETAB, interpreter free, counters and voice
        # queues cleared).
        invoke_bios 0x0090 gicini_done
    }
}

proc gicini_done {} {
    record_keyboard [
        format "GICINI=%04X,%02X,%02X,%02X,%02X,%02X" \
            [word_at 0xF3F3] [peek 0xF3F5] \
            [peek 0xFB3F] [peek 0xFB40] \
            [peek 0xFB41] [peek 0xF975]
    ]
    exit
}

after time 1.0 start_probe
after realtime 15 exit
