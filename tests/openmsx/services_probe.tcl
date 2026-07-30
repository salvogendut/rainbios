# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists services_output]} {
    set services_output /tmp/rainbios-services.txt
}

proc primary_map {} {
    expr {[debug read "ioports" 0xA8] & 0xFF}
}

proc invoke_bios {address callback} {
    set sentinel 0x0200
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::services_callback $callback
    set ::services_breakpoint [
        debug set_bp $sentinel {} {services_call_returned}
    ]
    reg PC $address
}

proc services_call_returned {} {
    debug remove_bp $::services_breakpoint
    set callback $::services_callback
    uplevel #0 $callback
}

proc word_at {address} {
    expr {[peek $address] | ([peek [expr {$address + 1}]] << 8)}
}

proc start_probe {} {
    set ::services_handle [open $::services_output w]
    set ::jiffy_start [word_at 0xFC9E]
    poke 0xF300 0
    foreach {offset value} {
        0x5000 0x21  0x5001 0x00  0x5002 0xF3
        0x5003 0x34  0x5004 0xC9
    } {
        debug write "Probe RAM" $offset $value
    }
    foreach {address value} {
        0xFD9F 0xF7  0xFDA0 0x03  0xFDA1 0x00
        0xFDA2 0x50  0xFDA3 0xC9
    } {
        poke $address $value
    }
    after time 0.5 interrupt_done
}

proc interrupt_done {} {
    poke 0xFD9F 0xC9
    set jiffy_end [word_at 0xFC9E]
    puts $::services_handle [
        format "INTERRUPT=%04X,%04X,%02X,%02X" \
            $::jiffy_start $jiffy_end [peek 0xF300] [primary_map]
    ]
    reg B 0xE2
    reg C 1
    invoke_bios 0x0047 wrtvdp_done
}

proc wrtvdp_done {} {
    puts $::services_handle [
        format "WRTVDP=%02X,%02X" \
            [debug read "VDP regs" 1] [peek 0xF3E0]
    ]
    invoke_bios 0x006C initxt_done
}

proc initxt_done {} {
    set name_prefix {}
    for {set address 0} {$address < 8} {incr address} {
        lappend name_prefix [format %02X [debug read VRAM $address]]
    }
    puts $::services_handle [
        format "INITXT=%02X,%02X,%04X,%04X,%s,%02X" \
            [debug read "VDP regs" 0] [debug read "VDP regs" 1] \
            [word_at 0xF922] [word_at 0xF924] \
            [join $name_prefix ,] [debug read VRAM 0x0A08]
    ]
    reg HL 0x0203
    invoke_bios 0x00C6 posit_done
}

proc posit_done {} {
    reg A 0x41
    invoke_bios 0x00A2 chput_done
}

proc chput_done {} {
    puts $::services_handle [
        format "CHPUT=%02X,%02X,%02X" \
            [debug read VRAM 81] [peek 0xF3DD] [peek 0xF3DC]
    ]
    debug write VRAM 0x0000 0x11
    debug write VRAM 0x0028 0x42
    debug write VRAM 0x0398 0x55
    poke 0xF3DD 5
    poke 0xF3DC 24
    reg A 0x0A
    invoke_bios 0x00A2 scroll_done
}

proc scroll_done {} {
    puts $::services_handle [
        format "SCROLL=%02X,%02X,%02X,%02X" \
            [debug read VRAM 0x0000] [debug read VRAM 0x0398] \
            [peek 0xF3DD] [peek 0xF3DC]
    ]
    reg F 0x40
    invoke_bios 0x00C3 cls_done
}

proc cls_done {} {
    puts $::services_handle [
        format "CLS=%02X,%02X,%02X" \
            [debug read VRAM 81] [peek 0xF3DD] [peek 0xF3DC]
    ]
    debug write VRAM 0x0000 0xAA
    debug write VRAM 0x17FF 0x55
    debug write VRAM 0x2000 0x12
    debug write VRAM 0x37FF 0x34
    invoke_bios 0x0072 initgrp_done
}

proc initgrp_done {} {
    set name_prefix {}
    for {set address 0x1800} {$address < 0x1808} {incr address} {
        lappend name_prefix [format %02X [debug read VRAM $address]]
    }
    puts $::services_handle [
        format "INITGRP=%02X,%02X,%s,%02X,%02X,%02X,%02X,%02X" \
            [debug read "VDP regs" 0] [debug read "VDP regs" 1] \
            [join $name_prefix ,] \
            [debug read VRAM 0x0000] [debug read VRAM 0x17FF] \
            [debug read VRAM 0x2000] [debug read VRAM 0x37FF] \
            [debug read VRAM 0x1B00]
    ]
    poke 0xF3DD 2
    poke 0xF3DC 3
    reg A 0x41
    invoke_bios 0x00A2 graphics_chput_done
}

proc graphics_chput_done {} {
    puts $::services_handle [
        format "GRAPHICS_CHPUT=%02X,%02X,%02X,%02X" \
            [debug read VRAM 0x0208] [debug read VRAM 0x2208] \
            [peek 0xF3DD] [peek 0xF3DC]
    ]
    debug write VRAM 0x0100 0xAA
    debug write VRAM 0x2100 0xBC
    debug write VRAM 0x1700 0x55
    debug write VRAM 0x3700 0x66
    poke 0xF3DC 24
    reg A 0x0A
    invoke_bios 0x00A2 graphics_scroll_done
}

proc graphics_scroll_done {} {
    puts $::services_handle [
        format "GRAPHICS_SCROLL=%02X,%02X,%02X,%02X,%02X,%02X" \
            [debug read VRAM 0x0000] [debug read VRAM 0x2000] \
            [debug read VRAM 0x1700] [debug read VRAM 0x3700] \
            [peek 0xF3DD] [peek 0xF3DC]
    ]
    close $::services_handle
    exit
}

after time 1.0 start_probe
after realtime 15 {
    catch {close $::services_handle}
    exit
}
