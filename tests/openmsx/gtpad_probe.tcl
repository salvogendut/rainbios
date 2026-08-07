# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists gtpad_output]} {
    set gtpad_output /tmp/rainbios-gtpad.txt
}

proc invoke_bios {address callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    set ::gtpad_callback $callback
    set ::gtpad_breakpoint [
        debug set_bp $sentinel {} {gtpad_call_returned}
    ]
    reg PC $address
}

proc gtpad_call_returned {} {
    debug remove_bp $::gtpad_breakpoint
    set callback $::gtpad_callback
    uplevel #0 $callback
}

proc record_gtpad {line} {
    set handle [open $::gtpad_output w]
    puts $handle $line
    close $handle
}

proc start_probe {} {
    # Without a touchpad, GTPAD reports no device: 00h.
    invoke_bios 0x00DB no_device_done
}

proc no_device_done {} {
    set ::no_device [reg A]
    # Plug a touchpad into connector 1. Headless openMSX cannot deliver host
    # touch, so the UPD7001 reports -SENSE (not touched) and GTPAD(0) returns
    # 00h after exercising the serial protocol without hanging; the cached
    # axes stay at their reset value.
    plug joyporta touchpad
    after time 0.1 {invoke_bios 0x00DB fetch_done}
}

proc fetch_done {} {
    set ::fetch [reg A]
    # GTPAD(1) returns the touchpad X position.
    reg A 1
    invoke_bios 0x00DB x_done
}

proc x_done {} {
    set ::padx [reg A]
    # GTPAD(2) returns the touchpad Y position.
    reg A 2
    invoke_bios 0x00DB y_done
}

proc y_done {} {
    set ::pady [reg A]
    set ::lines [list \
        [format "NODEVICE=%02X" $::no_device] \
        [format "FETCH=%02X" $::fetch] \
        [format "PADX=%02X" $::padx] \
        [format "PADY=%02X" $::pady]]
    record_gtpad [join $::lines "\n"]
    exit
}

after time 0.30 start_probe
after realtime 45 exit
