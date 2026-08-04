# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists msx2_subrom_output]} {
    set msx2_subrom_output /tmp/rainbios-msx2-subrom.txt
}
if {![info exists msx2_subrom_screenshot]} {
    set msx2_subrom_screenshot /tmp/rainbios-msx2-subrom.png
}

proc finish_msx2_subrom_probe {} {
    set handle [open $::msx2_subrom_output w]
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SP=%04X" [reg SP]]
    puts $handle [format "SLOT=%02X" \
        [expr {[debug read "ioports" 0xA8] & 0xFF}]]
    puts $handle [format "VERSION=%02X" [peek 0x002D]]
    puts $handle [format "EXBRSA=%02X" [peek 0xFAF8]]
    puts $handle [format "MARKER_CHKSLZ=%02X" [peek 0xF360]]
    puts $handle [format "MARKER_EXBRSA=%02X" [peek 0xF361]]
    puts $handle [format "MARKER_EXTROM=%02X" [peek 0xF362]]
    puts $handle [format "MARKER_SUBROM=%02X" [peek 0xF363]]
    close $handle

    set throttle on
    after realtime 0.25 capture_msx2_subrom
}

proc capture_msx2_subrom {} {
    screenshot -raw -size 640 $::msx2_subrom_screenshot
    exit
}

after time 2.00 {
    set throttle on
    after realtime 0.4 finish_msx2_subrom_probe
}
