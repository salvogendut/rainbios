# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists geobench_output]} {
    set geobench_output /tmp/rainbios-geobench.txt
}
if {![info exists geobench_screenshot]} {
    set geobench_screenshot /tmp/rainbios-geobench.png
}
if {![info exists geobench_capture_time]} {
    set geobench_capture_time 15
}

proc finish_geobench_probe {} {
    set handle [open $::geobench_output w]
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SP=%04X" [reg SP]]
    puts $handle [format "SLOT=%02X" \
        [expr {[debug read "ioports" 0xA8] & 0xFF}]]
    puts $handle [format "VDP_R0=%02X" [debug read "VDP regs" 0]]
    puts $handle [format "VDP_R1=%02X" [debug read "VDP regs" 1]]
    puts $handle [format "SCRMOD=%02X" [peek 0xFCAF]]
    puts $handle [format "MAPPER=%02X,%02X,%02X,%02X" \
        [debug read "ioports" 0xFC] [debug read "ioports" 0xFD] \
        [debug read "ioports" 0xFE] [debug read "ioports" 0xFF]]
    puts $handle [format "MAPPER_GLUE=%02X,%02X" \
        [peek 0xC018] [peek 0xC020]]
    set app_pages {}
    for {set index 0} {$index < 8} {incr index} {
        lappend app_pages [format %02X [peek [expr {0x1438 + $index}]]]
    }
    puts $handle "APP_PAGES=[join $app_pages ,]"
    set vdp_registers {}
    for {set index 0} {$index < 24} {incr index} {
        lappend vdp_registers [format %02X [debug read "VDP regs" $index]]
    }
    puts $handle "VDP_REGS=[join $vdp_registers ,]"
    puts $handle "PALETTE=[palette]"
    set vram [debug read_block VRAM 0 0x20000]
    binary scan $vram cu* vram_bytes
    set vram_nonzero 0
    foreach value $vram_bytes {
        if {$value != 0} {
            incr vram_nonzero
        }
    }
    puts $handle "VRAM_NONZERO=$vram_nonzero"
    puts $handle [format "VRAM_CRC32=%08X" [zlib crc32 $vram]]
    close $handle

    set throttle on
    after realtime 0.25 capture_geobench_desktop
}

proc capture_geobench_desktop {} {
    screenshot -raw -size 640 $::geobench_screenshot
    exit
}

# The image auto-runs GeoBench. The delay is emulated time and therefore
# independent of host speed.
after time $geobench_capture_time finish_geobench_probe
after realtime 30 exit
