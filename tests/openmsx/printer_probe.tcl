# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists printer_output]} {
    set printer_output /tmp/rainbios-printer.txt
}
if {![info exists printer_log]} {
    set printer_log /tmp/rainbios-printer.log
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::printer_callback $callback
    set ::printer_breakpoint [
        debug set_bp $sentinel {} {printer_call_returned}
    ]
    reg PC $address
}

proc printer_call_returned {} {
    debug remove_bp $::printer_breakpoint
    set callback $::printer_callback
    uplevel #0 $callback
}

proc record_printer {line} {
    set handle [open $::printer_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    # No printer plugged: the port reports busy, so LPTSTT returns 00h (Z set).
    invoke_bios 0x00A8 no_printer_done
}

proc no_printer_done {} {
    set ::no_printer [reg A]
    set ::no_printer_z [expr {([reg F] & 0x40) != 0}]
    # Attach the printer logger, then the port reports ready and every
    # LPTOUT byte is captured to the log file.
    set printerlogfilename $::printer_log
    plug printerport logger
    after time 0.1 {invoke_bios 0x00A8 printer_ready_done}
}

proc printer_ready_done {} {
    set ::ready [reg A]
    set ::ready_z [expr {([reg F] & 0x40) != 0}]
    # LPTOUT 'A' then 'B': carry must be clear after each.
    reg A 0x41
    invoke_bios 0x00A5 first_write_done
}

proc first_write_done {} {
    set ::carry1 [expr {[reg F] & 1}]
    reg A 0x42
    invoke_bios 0x00A5 second_write_done
}

proc second_write_done {} {
    set ::carry2 [expr {[reg F] & 1}]
    # Printer position work area (LPTPOS) remains 0: no break occurred.
    set ::lptpos [peek 0xF415]
    set ::lines [list \
        [format "NOPRINTER=%02X,%d" $::no_printer $::no_printer_z] \
        [format "READY=%02X,%d" $::ready $::ready_z] \
        [format "WRITE1=%d" $::carry1] \
        [format "WRITE2=%d" $::carry2] \
        [format "LPTPOS=%02X" $::lptpos]]
    record_printer [join $::lines "\n"]
    exit
}

after time 0.30 start_probe
after realtime 45 exit
