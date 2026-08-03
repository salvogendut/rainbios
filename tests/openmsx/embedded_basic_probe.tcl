# SPDX-License-Identifier: BSD-3-Clause

set throttle off
set ::rom_writes 0

if {![info exists embedded_basic_output]} {
    set embedded_basic_output /tmp/rainbios-embedded-basic.txt
}
if {![info exists embedded_basic_screenshot]} {
    set embedded_basic_screenshot /tmp/rainbios-embedded-basic.png
}

proc record_embedded_rom_write {} {
    incr ::rom_writes
}

debug watchpoint create \
    -type write_mem \
    -address {0x4000 0x7fff} \
    -condition {[lindex [get_selected_slot 1] 0] == 0} \
    -command record_embedded_rom_write

after time 4.00 {
    type_via_keybuf "PRINT 2+2\r"
}

after time 6.00 {
    set handle [open $::embedded_basic_output w]
    puts $handle "ROM_WRITES=$::rom_writes"
    puts $handle [format "SLOT=%02X" [expr {[debug read ioports 0xA8] & 0xFF}]]
    puts $handle [format "HEADER=%02X,%02X" [peek 0x4000] [peek 0x4001]]
    puts $handle [format "DESCRIPTOR=%02X,%02X,%02X,%02X" \
        [peek 0x7FF0] [peek 0x7FF1] [peek 0x7FF2] [peek 0x7FF3]]
    puts $handle [get_screen]
    close $handle
    set throttle on
    after realtime 0.25 {
        screenshot -raw -size 320 $::embedded_basic_screenshot
        exit
    }
}

after realtime 15 exit
