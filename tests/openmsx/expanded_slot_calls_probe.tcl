# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists expanded_output]} {
    set expanded_output /tmp/rainbios-expanded-slot-calls.txt
}

proc primary_map {} {
    expr {[debug read "ioports" 0xA8] & 0xFF}
}

proc main_slttbl1 {} {
    debug read "Main RAM" 0xFCC7
}

proc hardware_selector1 {} {
    set old [primary_map]
    debug write "ioports" 0xA8 [expr {($old & 0x3F) | 0x80}]
    set value [expr {(~[peek 0xFFFF]) & 0xFF}]
    debug write "ioports" 0xA8 $old
    return $value
}

proc reset_expanded_slot {} {
    set old [primary_map]
    debug write "ioports" 0xA8 [expr {($old & 0x3F) | 0x80}]
    poke 0xFFFF 0
    debug write "ioports" 0xA8 0x50
    debug write "Main RAM" 0xFCC7 0
}

proc invoke_bios {address callback} {
    set sentinel 0x0200
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::expanded_callback $callback
    set ::expanded_breakpoint [
        debug set_bp $sentinel {} {expanded_call_returned}
    ]
    reg PC $address
}

proc expanded_call_returned {} {
    debug remove_bp $::expanded_breakpoint
    set callback $::expanded_callback
    uplevel #0 $callback
}

proc start_probe {} {
    set ::expanded_handle [open $::expanded_output w]
    puts $::expanded_handle [format \
        "INIT=%02X,%02X,%02X,%02X/%02X,%02X,%02X,%02X/%02X/%02X" \
        [peek 0xFCC1] [peek 0xFCC2] [peek 0xFCC3] [peek 0xFCC4] \
        [peek 0xFCC5] [peek 0xFCC6] [peek 0xFCC7] [peek 0xFCC8] \
        [primary_map] [hardware_selector1]]

    debug write "Expanded RAM 1" 0x1234 0x11
    debug write "Expanded RAM 2" 0x5234 0x22
    debug write "Expanded RAM 3" 0x9234 0x33
    debug write "Expanded RAM 1" 0xD234 0x44

    reg A 0x86
    reg E 0xA1
    reg F 0
    reg HL 0x1234
    invoke_bios 0x000C rdslt0_done
}

proc rdslt0_done {} {
    puts $::expanded_handle [format "RDSLT0=%02X,%04X,%02X,%02X/%02X/%d" \
        [reg A] [reg HL] [reg E] [primary_map] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reg A 0x8A
    reg E 0xA2
    reg F 0
    reg HL 0x5234
    invoke_bios 0x000C rdslt1_done
}

proc rdslt1_done {} {
    puts $::expanded_handle [format "RDSLT1=%02X,%04X,%02X,%02X/%02X/%d" \
        [reg A] [reg HL] [reg E] [primary_map] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reg A 0x8E
    reg E 0xA3
    reg F 0
    reg HL 0x9234
    invoke_bios 0x000C rdslt2_done
}

proc rdslt2_done {} {
    puts $::expanded_handle [format "RDSLT2=%02X,%04X,%02X,%02X/%02X/%d" \
        [reg A] [reg HL] [reg E] [primary_map] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reg A 0x86
    reg E 0xA4
    reg F 0
    reg HL 0xD234
    invoke_bios 0x000C rdslt3_done
}

proc rdslt3_done {} {
    puts $::expanded_handle [format "RDSLT3=%02X,%04X,%02X,%02X/%02X/%d" \
        [reg A] [reg HL] [reg E] [primary_map] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reg A 0x86
    reg E 0x51
    reg F 0
    reg HL 0x1234
    invoke_bios 0x0014 wrslt0_done
}

proc wrslt0_done {} {
    puts $::expanded_handle [format "WRSLT0=%02X,%04X,%02X,%02X/%02X/%d" \
        [debug read "Expanded RAM 1" 0x1234] [reg HL] [reg E] \
        [primary_map] [hardware_selector1] [expr {[reg F] & 1}]]
    reg A 0x8A
    reg E 0x62
    reg F 0
    reg HL 0x5234
    invoke_bios 0x0014 wrslt1_done
}

proc wrslt1_done {} {
    puts $::expanded_handle [format "WRSLT1=%02X,%04X,%02X,%02X/%02X/%d" \
        [debug read "Expanded RAM 2" 0x5234] [reg HL] [reg E] \
        [primary_map] [hardware_selector1] [expr {[reg F] & 1}]]
    reg A 0x8E
    reg E 0x73
    reg F 0
    reg HL 0x9234
    invoke_bios 0x0014 wrslt2_done
}

proc wrslt2_done {} {
    puts $::expanded_handle [format "WRSLT2=%02X,%04X,%02X,%02X/%02X/%d" \
        [debug read "Expanded RAM 3" 0x9234] [reg HL] [reg E] \
        [primary_map] [hardware_selector1] [expr {[reg F] & 1}]]
    reg A 0x86
    reg E 0x84
    reg F 0
    reg HL 0xD234
    invoke_bios 0x0014 wrslt3_done
}

proc wrslt3_done {} {
    puts $::expanded_handle [format "WRSLT3=%02X,%04X,%02X,%02X/%02X/%d" \
        [debug read "Expanded RAM 1" 0xD234] [reg HL] [reg E] \
        [primary_map] [hardware_selector1] [expr {[reg F] & 1}]]
    reg A 0x86
    reg F 0
    reg HL 0x0000
    invoke_bios 0x0024 enaslt0_done
}

proc enaslt0_done {} {
    puts $::expanded_handle [format "ENASLT0=%02X/%02X/%02X/%d" \
        [primary_map] [main_slttbl1] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reset_expanded_slot
    reg A 0x8A
    reg F 0
    reg HL 0x4000
    invoke_bios 0x0024 enaslt1_done
}

proc enaslt1_done {} {
    puts $::expanded_handle [format "ENASLT1=%02X/%02X/%02X/%d" \
        [primary_map] [main_slttbl1] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reset_expanded_slot
    reg A 0x8E
    reg F 0
    reg HL 0x8000
    invoke_bios 0x0024 enaslt2_done
}

proc enaslt2_done {} {
    puts $::expanded_handle [format "ENASLT2=%02X/%02X/%02X/%d" \
        [primary_map] [main_slttbl1] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reset_expanded_slot
    reg A 0x86
    reg F 0
    reg HL 0xC000
    invoke_bios 0x0024 enaslt3_done
}

proc enaslt3_done {} {
    puts $::expanded_handle [format "ENASLT3=%02X/%02X/%02X/%d" \
        [primary_map] [main_slttbl1] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reset_expanded_slot

    # Mapper kernels patch the saved page-2/page-3 selectors in the standard
    # expanded CALSLT frame. Restore deliberately changed values to prove that
    # the frame fields do not overlap either caller return address.
    foreach {offset value} {
        0x5000 0x21  0x5001 0x03  0x5002 0x00
        0x5003 0x39  0x5004 0x36  0x5005 0x54
        0x5006 0x21  0x5007 0x09  0x5008 0x00
        0x5009 0x39  0x500A 0x36  0x500B 0x54
        0x500C 0x23  0x500D 0x36  0x500E 0x40
        0x500F 0x3A  0x5010 0xC7  0x5011 0xFC
        0x5012 0x32  0x5013 0x00  0x5014 0xF3
        0x5015 0x3E  0x5016 0x5A
        0x5017 0x01  0x5018 0x34  0x5019 0x12
        0x501A 0x11  0x501B 0x78  0x501C 0x56
        0x501D 0x21  0x501E 0xBC  0x501F 0x9A
        0x5020 0x37  0x5021 0xC9
    } {
        debug write "Expanded RAM 2" $offset $value
    }
    reg IX 0x5000
    reg IY 0x8A00
    reg F 0
    invoke_bios 0x001C calslt_done
}

proc calslt_done {} {
    puts $::expanded_handle [format \
        "CALSLT=%02X,%04X,%04X,%04X,%04X,%04X,%02X/%02X/%02X/%02X/%d" \
        [reg A] [reg BC] [reg DE] [reg HL] [reg IX] [reg IY] \
        [debug read "Main RAM" 0xF300] \
        [primary_map] [main_slttbl1] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reset_expanded_slot
    foreach {offset value} {
        0x9000 0x8A  0x9001 0x00  0x9002 0x50  0x9003 0xC9
        0xF360 0x00  0xF361 0x90  0xF362 0x00  0xF363 0x02
    } {
        debug write "Main RAM" $offset $value
    }
    reg SP 0xF360
    reg F 0
    set ::expanded_callback callf_done
    set ::expanded_breakpoint [
        debug set_bp 0x0200 {} {expanded_call_returned}
    ]
    reg PC 0x0030
}

proc callf_done {} {
    puts $::expanded_handle [format \
        "CALLF=%02X,%04X,%04X,%04X,%04X,%04X,%02X/%02X/%02X/%02X/%d" \
        [reg A] [reg BC] [reg DE] [reg HL] [reg IX] [reg IY] \
        [debug read "Main RAM" 0xF300] \
        [primary_map] [main_slttbl1] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reset_expanded_slot

    # Page-0 expanded target in Expanded RAM 2 (slot 2.2): the selector write is
    # safe because the target primary differs from the page-0 primary, and
    # CLPRIM switches page 0 from page-3 RAM.
    foreach {offset value} {
        0x1000 0x3E  0x1001 0x6A  0x1002 0x01  0x1003 0x34  0x1004 0x12
        0x1005 0x11  0x1006 0x78  0x1007 0x56  0x1008 0x21  0x1009 0xBC
        0x100A 0x9A  0x100B 0xC9
    } {
        debug write "Expanded RAM 2" $offset $value
    }
    reg A 0x11
    reg BC 0x2222
    reg DE 0x3333
    reg HL 0x4444
    reg IX 0x1000
    reg IY 0x8A00
    reg F 0
    invoke_bios 0x001C p0_expanded_done
}

proc p0_expanded_done {} {
    puts $::expanded_handle [format \
        "CALSLT0EXP=%02X,%04X,%04X,%04X,%02X/%02X/%02X/%d" \
        [reg A] [reg BC] [reg DE] [reg HL] \
        [primary_map] [main_slttbl1] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reset_expanded_slot

    # Page-3 target in a different slot (Expanded RAM 2, slot 2.2) while page 3
    # maps Main RAM: the page-3 return frame is installed in the target's RAM.
    foreach {offset value} {
        0xC000 0x3E  0xC001 0xA5  0xC002 0x01  0xC003 0x21  0xC004 0x43
        0xC005 0x11  0xC006 0x87  0xC007 0x65  0xC008 0x21  0xC009 0xCB
        0xC00A 0xA9  0xC00B 0x37  0xC00C 0xC9
    } {
        debug write "Expanded RAM 2" $offset $value
    }
    reg A 0x44
    reg BC 0x5555
    reg DE 0x6666
    reg HL 0x7777
    reg IX 0xC000
    reg IY 0x8A00
    reg F 0
    invoke_bios 0x001C p3_expanded_done
}

proc p3_expanded_done {} {
    puts $::expanded_handle [format \
        "CALSLT3EXP=%02X,%04X,%04X,%04X,%02X/%02X/%02X/%d" \
        [reg A] [reg BC] [reg DE] [reg HL] \
        [primary_map] [main_slttbl1] [hardware_selector1] \
        [expr {[reg F] & 1}]]

    # Page-3 primary target in Main RAM (slot 1) while page 3 maps the expanded
    # slot: same page-3 return-frame path with no selector to restore. Map page 3
    # to a populated subslot so the probe's return sentinel lands in real RAM.
    foreach {offset value} {
        0xC000 0x3E  0xC001 0xB5  0xC002 0x01  0xC003 0x21  0xC004 0x43
        0xC005 0x11  0xC006 0x87  0xC007 0x65  0xC008 0x21  0xC009 0xCB
        0xC00A 0xA9  0xC00B 0x37  0xC00C 0xC9
    } {
        debug write "Main RAM" $offset $value
    }
    debug write "ioports" 0xA8 0x90
    poke 0xFFFF 0x80
    debug write "Main RAM" 0xFCC7 0x80
    debug write "ioports" 0xA8 0x90
    reg A 0x44
    reg BC 0x5555
    reg DE 0x6666
    reg HL 0x7777
    reg IX 0xC000
    reg IY 0x0100
    reg F 0
    invoke_bios 0x001C p3_primary_done
}

proc p3_primary_done {} {
    puts $::expanded_handle [format \
        "CALSLT3PRIM=%02X,%04X,%04X,%04X,%02X/%02X/%02X/%d" \
        [reg A] [reg BC] [reg DE] [reg HL] \
        [primary_map] [main_slttbl1] [hardware_selector1] \
        [expr {[reg F] & 1}]]
    reset_expanded_slot
    reg A 0x83
    reg F 0
    reg HL 0x8000
    invoke_bios 0x0024 invalid_done
}

proc invalid_done {} {
    puts $::expanded_handle [format "INVALID=%02X/%02X/%d" \
        [primary_map] [main_slttbl1] [expr {[reg F] & 1}]]
    close $::expanded_handle
    exit
}

after time 1.00 start_probe
after realtime 15 {
    catch {close $::expanded_handle}
    exit
}
