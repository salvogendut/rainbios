# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists cartridge_output]} {
    set cartridge_output /tmp/rainbios-cartridge.txt
}
if {![info exists cartridge_screenshot]} {
    set cartridge_screenshot /tmp/rainbios-cartridge.png
}

proc primary_map {} {
    expr {[debug read "ioports" 0xA8] & 0xFF}
}

proc finish_cartridge_probe {} {
    set handle [open $::cartridge_output w]
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SP=%04X" [reg SP]]
    puts $handle [format "SLOT=%02X" [primary_map]]
    puts $handle [format "SIGNATURE=%02X,%02X,%02X,%02X,%02X" \
        [peek 0xF300] [peek 0xF301] [peek 0xF302] \
        [peek 0xF303] [peek 0xF304]]
    close $handle
    set throttle on
    after realtime 0.25 {
        screenshot -raw -size 320 $::cartridge_screenshot
        exit
    }
}

after time 3.0 finish_cartridge_probe
after realtime 15 exit
