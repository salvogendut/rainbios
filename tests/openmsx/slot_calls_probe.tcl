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
    puts $::slot_handle "READHELPER=[format %02X [peek 0xF383]],[format %02X [peek 0xF384]],[format %02X [peek 0xF385]],[format %02X [peek 0xF386]],[format %02X [peek 0xF387]],[format %02X [peek 0xF388]],[format %02X [peek 0xF389]],[format %02X [peek 0xF38A]]"
    puts $::slot_handle "WRITEHELPER=[format %02X [peek 0xF38B]],[format %02X [peek 0xF38C]],[format %02X [peek 0xF38D]],[format %02X [peek 0xF38E]],[format %02X [peek 0xF38F]],[format %02X [peek 0xF390]],[format %02X [peek 0xF391]]"

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

    debug write "Probe RAM" 0x1234 0x11
    debug write "Probe RAM" 0x5234 0x22
    debug write "Probe RAM" 0x9234 0x33
    debug write "Probe RAM" 0xD234 0x44
    reg A 3
    reg F 0
    reg HL 0x1234
    invoke_bios 0x000C rdslt0_done
}

proc rdslt0_done {} {
    puts $::slot_handle [
        format "RDSLT0=%02X,%04X,%02X,%d" \
            [reg A] [reg HL] [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 3
    reg F 0
    reg HL 0x5234
    invoke_bios 0x000C rdslt1_done
}

proc rdslt1_done {} {
    puts $::slot_handle [
        format "RDSLT1=%02X,%04X,%02X,%d" \
            [reg A] [reg HL] [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 3
    reg F 0
    reg HL 0x9234
    invoke_bios 0x000C rdslt2_done
}

proc rdslt2_done {} {
    puts $::slot_handle [
        format "RDSLT2=%02X,%04X,%02X,%d" \
            [reg A] [reg HL] [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 3
    reg F 0
    reg HL 0xD234
    invoke_bios 0x000C rdslt3_done
}

proc rdslt3_done {} {
    puts $::slot_handle [
        format "RDSLT3=%02X,%04X,%02X,%d" \
            [reg A] [reg HL] [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 3
    reg E 0x55
    reg F 0
    reg HL 0x1234
    invoke_bios 0x0014 wrslt0_done
}

proc wrslt0_done {} {
    puts $::slot_handle [
        format "WRSLT0=%02X,%04X,%02X,%02X,%d" \
            [debug read "Probe RAM" 0x1234] [reg HL] [reg E] \
            [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 3
    reg E 0x66
    reg F 0
    reg HL 0x5234
    invoke_bios 0x0014 wrslt1_done
}

proc wrslt1_done {} {
    puts $::slot_handle [
        format "WRSLT1=%02X,%04X,%02X,%02X,%d" \
            [debug read "Probe RAM" 0x5234] [reg HL] [reg E] \
            [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 3
    reg E 0x77
    reg F 0
    reg HL 0x9234
    invoke_bios 0x0014 wrslt2_done
}

proc wrslt2_done {} {
    puts $::slot_handle [
        format "WRSLT2=%02X,%04X,%02X,%02X,%d" \
            [debug read "Probe RAM" 0x9234] [reg HL] [reg E] \
            [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 3
    reg E 0x88
    reg F 0
    reg HL 0xD234
    invoke_bios 0x0014 wrslt3_done
}

proc wrslt3_done {} {
    puts $::slot_handle [
        format "WRSLT3=%02X,%04X,%02X,%02X,%d" \
            [debug read "Probe RAM" 0xD234] [reg HL] [reg E] \
            [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 0x83
    reg F 0
    reg HL 0x1234
    invoke_bios 0x000C rdslt_expanded_done
}

proc rdslt_expanded_done {} {
    puts $::slot_handle [
        format "RDSLTEXP=%02X,%04X,%02X,%d" \
            [reg A] [reg HL] [primary_map] [expr {[reg F] & 1}]
    ]
    reg A 0x83
    reg E 0x99
    reg F 0
    reg HL 0x1234
    invoke_bios 0x0014 wrslt_expanded_done
}

proc wrslt_expanded_done {} {
    puts $::slot_handle [
        format "WRSLTEXP=%02X,%04X,%02X,%02X,%d" \
            [debug read "Probe RAM" 0x1234] [reg HL] [reg E] \
            [primary_map] [expr {[reg F] & 1}]
    ]

    foreach {offset value} {
        0x5000 0xDD  0x5001 0x21  0x5002 0x00  0x5003 0x51
        0x5004 0xFD  0x5005 0x21  0x5006 0x00  0x5007 0x03
        0x5008 0xCD  0x5009 0x1C  0x500A 0x00  0x500B 0xC9
        0x5100 0x3E  0x5101 0x5A
        0x5102 0x01  0x5103 0x34  0x5104 0x12
        0x5105 0x11  0x5106 0x78  0x5107 0x56
        0x5108 0x21  0x5109 0xBC  0x510A 0x9A
        0x510B 0x37  0x510C 0xC9
        0x9000 0x3E  0x9001 0xA5
        0x9002 0x01  0x9003 0x43  0x9004 0x21
        0x9005 0x11  0x9006 0x87  0x9007 0x65
        0x9008 0x21  0x9009 0xCB  0x900A 0xA9
        0x900B 0xB7  0x900C 0xC9
    } {
        debug write "Probe RAM" $offset $value
    }
    reg IX 0x5000
    reg IY 0x0300
    reg F 0
    invoke_bios 0x001C calslt1_done
}

proc calslt1_done {} {
    puts $::slot_handle [
        format "CALSLTNEST=%02X,%04X,%04X,%04X,%04X,%04X,%02X,%d" \
            [reg A] [reg BC] [reg DE] [reg HL] [reg IX] [reg IY] \
            [primary_map] [expr {[reg F] & 1}]
    ]
    reg IX 0x9000
    reg IY 0x0300
    reg F 1
    invoke_bios 0x001C calslt2_done
}

proc calslt2_done {} {
    puts $::slot_handle [
        format "CALSLT2=%02X,%04X,%04X,%04X,%04X,%04X,%02X,%d" \
            [reg A] [reg BC] [reg DE] [reg HL] [reg IX] [reg IY] \
            [primary_map] [expr {[reg F] & 1}]
    ]
    reg IX 0x5000
    reg IY 0x8300
    reg F 0
    invoke_bios 0x001C calslt_expanded_done
}

proc calslt_expanded_done {} {
    puts $::slot_handle [
        format "CALSLTEXP=%04X,%04X,%02X,%d" \
            [reg IX] [reg IY] [primary_map] [expr {[reg F] & 1}]
    ]
    reg IX 0x1000
    reg IY 0x0300
    reg F 0
    invoke_bios 0x001C calslt_page0_done
}

proc calslt_page0_done {} {
    puts $::slot_handle [
        format "CALSLT0=%04X,%04X,%02X,%d" \
            [reg IX] [reg IY] [primary_map] [expr {[reg F] & 1}]
    ]
    close $::slot_handle
    exit
}

after time 1.00 start_probe
after realtime 10 {
    catch {close $::slot_handle}
    exit
}
