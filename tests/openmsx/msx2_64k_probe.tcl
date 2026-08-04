# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists msx2_64k_output]} {
    set msx2_64k_output /tmp/rainbios-msx2-64k.txt
}
if {![info exists msx2_64k_screenshot]} {
    set msx2_64k_screenshot /tmp/rainbios-msx2-64k.png
}

proc finish_msx2_64k_probe {} {
    set handle [open $::msx2_64k_output w]
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SP=%04X" [reg SP]]
    puts $handle [format "SLOT=%02X" \
        [expr {[debug read "ioports" 0xA8] & 0xFF}]]
    puts $handle [format "VDP_R0=%02X" [debug read "VDP regs" 0]]
    puts $handle [format "VDP_R1=%02X" [debug read "VDP regs" 1]]
    puts $handle [format "SCRMOD=%02X" [peek 0xFCAF]]
    puts $handle [format "M_SC5=%02X" [peek 0xF380]]
    puts $handle [format "M_SC8=%02X" [peek 0xF381]]
    # The probe's even-address 16-bit VRAM round trips.
    for {set index 0} {$index < 7} {incr index} {
        puts $handle [format "M_V%d=%02X" $index [peek [expr {0xF382 + $index}]]]
    }
    # Directly verify a couple of the VRAM markers through the debugger.
    set vram [debug read_block VRAM 0x8000 1]
    binary scan $vram cu* vram_bytes
    puts $handle [format "VRAM_8000=%02X" [lindex $vram_bytes 0]]
    set vram [debug read_block VRAM 0xFFFE 1]
    binary scan $vram cu* vram_bytes
    puts $handle [format "VRAM_FFFE=%02X" [lindex $vram_bytes 0]]
    close $handle

    set throttle on
    after realtime 0.25 capture_msx2_64k
}

proc capture_msx2_64k {} {
    screenshot -raw -size 640 $::msx2_64k_screenshot
    exit
}

after time 2.00 {
    set throttle on
    after realtime 0.4 finish_msx2_64k_probe
}
