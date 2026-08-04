# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists msx2_cmdclock_output]} {
    set msx2_cmdclock_output /tmp/rainbios-msx2-cmdclock.txt
}
if {![info exists msx2_cmdclock_screenshot]} {
    set msx2_cmdclock_screenshot /tmp/rainbios-msx2-cmdclock.png
}

proc finish_msx2_cmdclock_probe {} {
    set handle [open $::msx2_cmdclock_output w]
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SP=%04X" [reg SP]]
    puts $handle [format "SLOT=%02X" \
        [expr {[debug read "ioports" 0xA8] & 0xFF}]]
    puts $handle [format "SCRMOD=%02X" [peek 0xFCAF]]
    set vdp_registers {}
    for {set index 0} {$index < 47} {incr index} {
        lappend vdp_registers [format %02X [debug read "VDP regs" $index]]
    }
    puts $handle "VDP_REGS=[join $vdp_registers ,]"
    # BLTVV: source pattern copied to VRAM byte 0x10.
    set vram [debug read_block VRAM 0x10 4]
    binary scan $vram cu* vram_bytes
    puts $handle [format "M_BLTVV=%02X,%02X,%02X,%02X" \
        [lindex $vram_bytes 0] [lindex $vram_bytes 1] \
        [lindex $vram_bytes 2] [lindex $vram_bytes 3]]
    # BLTVM: RAM-to-VRAM fill of colour 3 at VRAM byte 0x20.
    set vram [debug read_block VRAM 0x20 4]
    binary scan $vram cu* vram_bytes
    puts $handle [format "M_BLTVM=%02X,%02X,%02X,%02X" \
        [lindex $vram_bytes 0] [lindex $vram_bytes 1] \
        [lindex $vram_bytes 2] [lindex $vram_bytes 3]]
    # The probe's markers: BLTMV header NX and pixels, RTC round trip.
    puts $handle [format "M_BLTMV_NX=%02X" [peek 0xF388]]
    puts $handle [format "M_BLTMV_P0=%02X" [peek 0xF389]]
    puts $handle [format "M_BLTMV_P1=%02X" [peek 0xF38A]]
    puts $handle [format "M_BLTMV_P2=%02X" [peek 0xF38B]]
    puts $handle [format "M_RTC=%02X" [peek 0xF387]]
    close $handle

    set throttle on
    after realtime 0.25 capture_msx2_cmdclock
}

proc capture_msx2_cmdclock {} {
    screenshot -raw -size 640 $::msx2_cmdclock_screenshot
    exit
}

after time 2.00 {
    set throttle on
    after realtime 0.4 finish_msx2_cmdclock_probe
}
