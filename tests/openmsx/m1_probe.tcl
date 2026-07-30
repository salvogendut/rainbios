# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists m1_output]} {
    set m1_output /tmp/rainbios-m1-probe.txt
}

after time 1.00 {
    set handle [open $::m1_output w]
    puts $handle "SP=[format %04X [reg SP]]"
    puts $handle "SLOTS=[lindex [get_selected_slot 0] 0]/[lindex [get_selected_slot 1] 0]/[lindex [get_selected_slot 2] 0]/[lindex [get_selected_slot 3] 0]"
    puts $handle "BOTTOM=[format %04X [peek16 0xFC48]]"
    puts $handle "HIMEM=[format %04X [peek16 0xFC4A]]"
    puts $handle "BIOSSLT=[format %02X [peek 0xFCC0]]"
    puts $handle "EXPTBL=[format %08X [expr {[peek 0xFCC1] | ([peek 0xFCC2] << 8) | ([peek 0xFCC3] << 16) | ([peek 0xFCC4] << 24)}]]"
    puts $handle "SLTTBL=[format %08X [expr {[peek 0xFCC5] | ([peek 0xFCC6] << 8) | ([peek 0xFCC7] << 16) | ([peek 0xFCC8] << 24)}]]"
    puts $handle "HOOKS=[format %02X [peek 0xFD9A]],[format %02X [peek 0xFD9F]],[format %02X [peek 0xFFCA]]"
    close $handle
    exit
}
