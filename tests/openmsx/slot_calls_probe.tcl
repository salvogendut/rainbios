# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists slot_output]} {
    set slot_output /tmp/rainbios-slot-calls.txt
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
    set ::slot_callback $callback
    set ::slot_breakpoint [
        debug set_bp $sentinel {} {slot_call_returned}
    ]
    reg PC $address
}

proc slot_call_returned {} {
    debug remove_bp $::slot_breakpoint
    set callback $::slot_callback
    uplevel #0 $callback
}

proc start_probe {} {
    set ::slot_handle [open $::slot_output w]
    puts $::slot_handle "HELPER=[format %02X [peek 0xF380]],[format %02X [peek 0xF381]],[format %02X [peek 0xF382]]"

    debug write "ioports" 0xA8 0xE4
    reg A 0x11
    reg F 0xA5
    reg BC 0x2345
    reg DE 0x6789
    reg HL 0xABCD
    invoke_bios 0x0138 rslreg_done
}

proc rslreg_done {} {
    puts $::slot_handle [format "RSLREG=%02X,%04X,%04X,%04X,%02X,%02X" \
        [reg A] [reg BC] [reg DE] [reg HL] [reg F] [primary_map]]

    reg A 0xE4
    reg F 0xA4
    reg BC 0x1357
    reg DE 0x2468
    reg HL 0x9ABC
    invoke_bios 0x013B wslreg_done
}

proc wslreg_done {} {
    puts $::slot_handle [format "WSLREG=%02X,%04X,%04X,%04X,%02X,%02X" \
        [reg A] [reg BC] [reg DE] [reg HL] [reg F] [primary_map]]

    debug write "ioports" 0xA8 0xF0
    reg A 1
    reg HL 0x4000
    invoke_bios 0x0024 enaslt1_done
}

proc enaslt1_done {} {
    puts $::slot_handle [
        format "ENASLT1=%02X,%d" [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 2
    reg HL 0x8000
    invoke_bios 0x0024 enaslt2_done
}

proc enaslt2_done {} {
    puts $::slot_handle [
        format "ENASLT2=%02X,%d" [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 2
    reg HL 0x0000
    invoke_bios 0x0024 enaslt0_done
}

proc enaslt0_done {} {
    puts $::slot_handle [
        format "ENASLT0=%02X,%d" [primary_map] [expr {[reg F] & 1}]
    ]
    debug write "ioports" 0xA8 0xE4
    reg A 1
    reg HL 0xC000
    invoke_bios 0x0024 enaslt3_done
}

proc enaslt3_done {} {
    puts $::slot_handle [
        format "ENASLT3=%02X,%d" [primary_map] [expr {[reg F] & 1}]
    ]
    debug write "ioports" 0xA8 0xF0
    reg A 0x81
    reg F 0
    reg HL 0x8000
    invoke_bios 0x0024 expanded_done
}

proc expanded_done {} {
    puts $::slot_handle [
        format "EXPANDED=%02X,%d" [primary_map] [expr {[reg F] & 1}]
    ]
    close $::slot_handle
    exit
}

after time 1.00 start_probe
after realtime 10 {
    catch {close $::slot_handle}
    exit
}
