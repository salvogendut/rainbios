# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists bbcbasic_quote_output]} {
    set bbcbasic_quote_output /tmp/rainbios-bbcbasic-quote.txt
}

# Boot RainBIOS_MSX1, which launches the embedded BBC BASIC console after the
# storage/boot scan and the Space-key window. Then type a double quote through
# the physical keyboard matrix (Shift + apostrophe) followed by a letter, so
# the BBC BASIC line editor echoes "A on the command line. The quote must
# arrive as the literal 0x22 character, not latch a dead key.
after time 8.00 {
    keymatrixdown 6 0x01
    keymatrixdown 2 0x01
}
after time 8.10 {
    keymatrixup 2 0x01
    keymatrixup 6 0x01
}
after time 8.20 {keymatrixdown 2 0x40}
after time 8.30 {keymatrixup 2 0x40}

after time 10.00 {
    set handle [open $::bbcbasic_quote_output w]
    puts $handle [get_screen]
    close $handle
    exit
}

after realtime 15 exit
