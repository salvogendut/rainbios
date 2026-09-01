# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists msx2_output]} {
    set msx2_output /tmp/rainbios-msx2.txt
}
if {![info exists msx2_screenshot]} {
    set msx2_screenshot /tmp/rainbios-msx2.png
}

proc finish_msx2_probe {} {
    set handle [open $::msx2_output w]
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SP=%04X" [reg SP]]
    puts $handle [format "SLOT=%02X" \
        [expr {[debug read "ioports" 0xA8] & 0xFF}]]
    puts $handle [format "VDP_R0=%02X" [debug read "VDP regs" 0]]
    puts $handle [format "VDP_R1=%02X" [debug read "VDP regs" 1]]
    puts $handle [format "IDBYT1=%02X" [peek 0x002B]]
    puts $handle [format "IDBYT2=%02X" [peek 0x002C]]
    puts $handle [format "VERSION=%02X" [peek 0x002D]]
    puts $handle [format "EXBRSA=%02X" [peek 0xFAF8]]
    puts $handle [format "SCRMOD=%02X" [peek 0xFCAF]]
    set vdp_registers {}
    for {set index 0} {$index < 24} {incr index} {
        lappend vdp_registers [format %02X [debug read "VDP regs" $index]]
    }
    puts $handle "VDP_REGS=[join $vdp_registers ,]"
    puts $handle [format "RG8SAV=%02X" [peek 0xFFE7]]
    set vram [debug read_block VRAM 0 0x20000]
    binary scan $vram cu* vram_bytes
    set vram_nonzero 0
    foreach value $vram_bytes {
        if {$value != 0} {
            incr vram_nonzero
        }
    }
    puts $handle "VRAM_NONZERO=$vram_nonzero"
    close $handle

    set throttle on
    after realtime 0.25 capture_msx2_boot
}

proc capture_msx2_boot {} {
    screenshot -raw -size 640 $::msx2_screenshot
    exit
}

# Report in emulated time while the MSX2 bootstrap is still active
# closes, so the captured frame is the rendered boot logo.
after time 3.00 {
    set throttle on
    after realtime 0.4 finish_msx2_probe
}
