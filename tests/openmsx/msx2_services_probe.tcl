# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists msx2_services_output]} {
    set msx2_services_output /tmp/rainbios-msx2-services.txt
}
if {![info exists msx2_services_screenshot]} {
    set msx2_services_screenshot /tmp/rainbios-msx2-services.png
}

proc finish_msx2_services_probe {} {
    set handle [open $::msx2_services_output w]
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SP=%04X" [reg SP]]
    puts $handle [format "SLOT=%02X" \
        [expr {[debug read "ioports" 0xA8] & 0xFF}]]
    puts $handle [format "VDP_R0=%02X" [debug read "VDP regs" 0]]
    puts $handle [format "VDP_R1=%02X" [debug read "VDP regs" 1]]
    puts $handle [format "SCRMOD=%02X" [peek 0xFCAF]]
    set vdp_registers {}
    for {set index 0} {$index < 24} {incr index} {
        lappend vdp_registers [format %02X [debug read "VDP regs" $index]]
    }
    puts $handle "VDP_REGS=[join $vdp_registers ,]"
    puts $handle [format "PALETTE2=%s" [palette]]
    # The probe's markers: SCRMOD transitions, table bases, VRAM round trip,
    # palette GETPLT result.
    puts $handle [format "M_SC5=%02X" [peek 0xF360]]
    puts $handle [format "M_NAM5=%02X,%02X" [peek 0xF361] [peek 0xF362]]
    puts $handle [format "M_PAT5=%02X,%02X" [peek 0xF363] [peek 0xF364]]
    puts $handle [format "M_ATR5=%02X,%02X" [peek 0xF365] [peek 0xF366]]
    puts $handle [format "M_SC6=%02X" [peek 0xF367]]
    puts $handle [format "M_SC7=%02X" [peek 0xF368]]
    puts $handle [format "M_SC8=%02X" [peek 0xF369]]
    puts $handle [format "M_VRAM=%02X" [peek 0xF36A]]
    puts $handle [format "M_PLTB=%02X" [peek 0xF36B]]
    puts $handle [format "M_PLTC=%02X" [peek 0xF36C]]
    puts $handle [format "M_LOWVR=%02X" [peek 0xF36D]]
    puts $handle [format "M_HIGHVR=%02X" [peek 0xF36E]]
    puts $handle [format "M_CEFONT=%02X" [peek 0xF36F]]
    puts $handle [format "M_SC5PAGES=%02X,%02X,%02X,%02X" \
        [peek 0xF370] [peek 0xF371] [peek 0xF372] [peek 0xF373]]
    puts $handle [format "M_SC8PAGES=%02X,%02X" \
        [peek 0xF374] [peek 0xF375]]
    foreach {name address} {
        VRAM_SC5_P0 0x00200 VRAM_SC5_P1 0x08200
        VRAM_SC5_P2 0x10200 VRAM_SC5_P3 0x18200
    } {
        set vram [debug read_block VRAM $address 1]
        binary scan $vram cu* vram_bytes
        puts $handle [format "%s=%02X" $name [lindex $vram_bytes 0]]
    }
    close $handle

    set throttle on
    after realtime 0.25 capture_msx2_services
}

proc capture_msx2_services {} {
    screenshot -raw -size 640 $::msx2_services_screenshot
    exit
}

after time 2.00 {
    set throttle on
    after realtime 0.4 finish_msx2_services_probe
}
