# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists external_output]} {
    set external_output /tmp/rainbios-external-cartridge.txt
}
if {![info exists external_screenshot]} {
    set external_screenshot /tmp/rainbios-external-cartridge.png
}

proc finish_external_probe {} {
    set handle [open $::external_output w]
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SP=%04X" [reg SP]]
    puts $handle [
        format "SLOT=%02X" [expr {[debug read "ioports" 0xA8] & 0xFF}]
    ]
    puts $handle [format "VDP_R0=%02X" [debug read "VDP regs" 0]]
    puts $handle [format "VDP_R1=%02X" [debug read "VDP regs" 1]]
    close $handle
    set throttle on
    after time 0.25 {
        screenshot -raw -size 320 $::external_screenshot
        exit
    }
}

# Emulated-time delays keep the probe point deterministic regardless of host
# speed, so the captured registers and screenshot always land on the same
# game state instead of a wall-clock-dependent frame.
after time 90 finish_external_probe
after time 95 exit
