# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists cls_output]} {
    set cls_output /tmp/rainbios-cls.txt
}

proc read_cls_result {} {
    if {[peek 0xf39e] != 255} {
        after time 0.5 read_cls_result
        return
    }
    set handle [open $::cls_output w]
    puts $handle "SCREEN0_NAME=[peek 0xf3a0]"
    puts $handle "SCREEN0_CSRX=[peek 0xf3a1]"
    puts $handle "SCREEN0_CSRY=[peek 0xf3a2]"
    puts $handle "SCREEN2_PATTERN=[peek 0xf3a3]"
    puts $handle "SCREEN2_COLOUR=[peek 0xf3a4]"
    puts $handle "SCREEN2_CSRX=[peek 0xf3a5]"
    puts $handle "SCREEN2_CSRY=[peek 0xf3a6]"
    puts $handle "BAKCLR=[peek 0xf3ea]"
    puts $handle "BASIC=[expr {[string first {BBC BASIC (Z80)} [get_screen]] >= 0}]"
    close $handle
    exit
}

after time 4.0 read_cls_result
after realtime 20 exit
