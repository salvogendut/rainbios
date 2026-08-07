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

# The breakpoint fires with the CPU paused at the cartridge INIT entry, so
# these registers are the authoritative startup state (the fixture also stores
# a copy to validate its own capture).
proc init_entry_captured {} {
    set ::init_lines [list \
        [format "ENTRYPC=%04X" [reg PC]] \
        [format "ENTRYSP=%04X" [reg SP]] \
        [format "ENTRYAF=%02X,%02X" [reg A] [reg F]] \
        [format "ENTRYBC=%04X" [reg BC]] \
        [format "ENTRYDE=%04X" [reg DE]] \
        [format "ENTRYHL=%04X" [reg HL]] \
        [format "ENTRYIX=%04X" [reg IX]] \
        [format "ENTRYIY=%04X" [reg IY]]]
    debug remove_bp $::init_breakpoint
    after time 3.0 finish_cartridge_probe
}

proc finish_cartridge_probe {} {
    set handle [open $::cartridge_output w]
    foreach line $::init_lines {
        puts $handle $line
    }
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SP=%04X" [reg SP]]
    puts $handle [format "SLOT=%02X" [primary_map]]
    puts $handle [format "EXPTBL=%02X,%02X,%02X,%02X" \
        [peek 0xFCC1] [peek 0xFCC2] [peek 0xFCC3] [peek 0xFCC4]]
    puts $handle [format "SLTTBL=%02X,%02X,%02X,%02X" \
        [peek 0xFCC5] [peek 0xFCC6] [peek 0xFCC7] [peek 0xFCC8]]
    puts $handle [format "SIGNATURE=%02X,%02X,%02X,%02X,%02X" \
        [peek 0xF300] [peek 0xF301] [peek 0xF302] \
        [peek 0xF303] [peek 0xF304]]
    # Register snapshot captured by the fixture at INIT entry (F310-F31D).
    puts $handle [format "INITAF=%02X,%02X" [peek 0xF310] [peek 0xF311]]
    puts $handle [format "INITBC=%02X,%02X" [peek 0xF312] [peek 0xF313]]
    puts $handle [format "INITDE=%02X,%02X" [peek 0xF314] [peek 0xF315]]
    puts $handle [format "INITHL=%02X,%02X" [peek 0xF316] [peek 0xF317]]
    puts $handle [format "INITIX=%02X,%02X" [peek 0xF318] [peek 0xF319]]
    puts $handle [format "INITIY=%02X,%02X" [peek 0xF31A] [peek 0xF31B]]
    puts $handle [format "INITSP=%02X,%02X" [peek 0xF31C] [peek 0xF31D]]
    close $handle
    set throttle on
    after realtime 0.25 {
        screenshot -raw -size 320 $::cartridge_screenshot
        exit
    }
}

after time 0.30 {
    set ::init_breakpoint [debug set_bp 0x4010 {} {init_entry_captured}]
}
after realtime 15 exit
