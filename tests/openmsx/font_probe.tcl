# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists font_output]} {
    set font_output /tmp/rainbios-font.txt
}

proc dump_font {} {
    set handle [open $::font_output w]
    foreach code {0x41 0x42 0x5A 0x61 0x62 0x7A 0x67 0x70 0x81 0x82 0x85 0x98} {
        set base [expr {$code * 8}]
        set bytes {}
        for {set index 0} {$index < 8} {incr index} {
            lappend bytes [format "%02X" [debug read VRAM [expr {$base + $index}]]]
        }
        puts $handle [format "%02X=%s" $code [join $bytes ","]]
    }
    close $handle
    exit
}

keymatrixdown 8 0x01
after time 0.80 {keymatrixup 8 0x01}
after time 1.00 dump_font
after realtime 15 exit
