# SPDX-License-Identifier: BSD-3-Clause

set throttle off
set renderer none

if {![info exists controller_output]} {
    set controller_output /tmp/rainbios-controller.txt
}
set handle [open $controller_output w]
close $handle

proc invoke_controller {address selector callback} {
    set sentinel 0xF300
    set stack 0xF360
    poke $stack [expr {$sentinel & 0xFF}]
    poke [expr {$stack + 1}] [expr {$sentinel >> 8}]
    reg SP $stack
    reg A $selector
    set ::controller_callback $callback
    set ::controller_breakpoint [
        debug set_bp $sentinel {} {controller_call_returned}
    ]
    reg PC $address
}

proc controller_call_returned {} {
    debug remove_bp $::controller_breakpoint
    set callback $::controller_callback
    uplevel #0 $callback
}

proc record_controller {line} {
    lappend ::controller_lines $line
    set handle [open $::controller_output w]
    puts $handle [join $::controller_lines "\n"]
    close $handle
}

proc start_probe {} {
    set ::controller_lines {}
    poke 0xF300 0xC9
    invoke_controller 0x0096 7 psg_mixer_initialized
}

proc psg_mixer_initialized {} {
    set ::psg_mixer [reg A]
    invoke_controller 0x0096 15 psg_initialized
}

proc psg_initialized {} {
    set ::psg_initial [reg A]
    invoke_controller 0x00D5 0 stick_keys_neutral
}

proc stick_keys_neutral {} {
    set ::stick_keys [list [reg A]]
    set ::stick_masks {0x20 0xA0 0x80 0xC0 0x40 0x50 0x10 0x30}
    set ::stick_index 0
    stick_keys_next
}

proc stick_keys_next {} {
    if {$::stick_index == [llength $::stick_masks]} {
        record_controller [format \
            "STICK_KEYS=%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X" \
            {*}$::stick_keys]
        keymatrixdown 8 0x01
        reg BC 0x1234
        reg DE 0x5678
        reg HL 0x9ABC
        invoke_controller 0x00D8 0 trigger_space
        return
    }
    set ::stick_mask [lindex $::stick_masks $::stick_index]
    keymatrixdown 8 $::stick_mask
    invoke_controller 0x00D5 0 stick_key_sampled
}

proc stick_key_sampled {} {
    lappend ::stick_keys [reg A]
    keymatrixup 8 $::stick_mask
    incr ::stick_index
    stick_keys_next
}

proc trigger_space {} {
    record_controller [format "TRIGGER_KEY=%02X,%04X,%04X,%04X" \
        [reg A] [reg BC] [reg DE] [reg HL]]
    keymatrixup 8 0x01
    reg E 0xBC
    invoke_controller 0x0093 15 psg_port1_seeded
}

proc psg_port1_seeded {} {
    unplug joyporta
    plug joyporta circuit-designer-rd-dongle
    # The joystick matrix is captured by the per-frame interrupt snapshot, so
    # wait a frame before GTSTCK reads it.
    after time 0.03 stick_port1_active_wait
}

proc stick_port1_active_wait {} {
    invoke_controller 0x00D5 1 stick_port1_active
}

proc stick_port1_active {} {
    set ::stick_ports [list [reg A]]
    invoke_controller 0x0096 15 stick_port1_r15
}

proc stick_port1_r15 {} {
    set ::psg_port_b [list [reg A]]
    unplug joyporta
    after time 0.03 stick_port1_neutral_wait
}

proc stick_port1_neutral_wait {} {
    invoke_controller 0x00D5 1 stick_port1_neutral
}

proc stick_port1_neutral {} {
    lappend ::stick_ports [reg A]
    reg E 0x93
    invoke_controller 0x0093 15 psg_port2_seeded
}

proc psg_port2_seeded {} {
    unplug joyportb
    after time 0.03 stick_port2_neutral_wait
}

proc stick_port2_neutral_wait {} {
    invoke_controller 0x00D5 2 stick_port2_neutral
}

proc stick_port2_neutral {} {
    lappend ::stick_ports [reg A]
    invoke_controller 0x0096 15 stick_port2_r15
}

proc stick_port2_r15 {} {
    lappend ::psg_port_b [reg A]
    record_controller [format "STICK_PORTS=%02X,%02X,%02X" \
        {*}$::stick_ports]
    invoke_controller 0x00D8 1 trigger_port1_neutral
}

proc trigger_port1_neutral {} {
    set ::trigger_ports [list [reg A]]
    invoke_controller 0x00D8 4 trigger_port2_neutral
}

proc trigger_port2_neutral {} {
    lappend ::trigger_ports [reg A]
    record_controller [format "TRIGGER_PORTS=%02X,%02X" \
        {*}$::trigger_ports]
    invoke_controller 0x00DB 12 empty_mouse_requested
}

proc empty_mouse_requested {} {
    set ::mouse_empty [list [reg A]]
    invoke_controller 0x00DB 13 empty_mouse_x
}

proc empty_mouse_x {} {
    lappend ::mouse_empty [reg A]
    invoke_controller 0x00DB 14 empty_mouse_y
}

proc empty_mouse_y {} {
    lappend ::mouse_empty [reg A]
    record_controller [format "MOUSE_EMPTY=%02X,%02X,%02X" \
        {*}$::mouse_empty]
    unplug joyporta
    plug joyporta mouse
    invoke_controller 0x00DB 12 mouse_port1_requested
}

proc mouse_port1_requested {} {
    set ::mouse_idle [list [reg A]]
    invoke_controller 0x00DB 13 mouse_port1_x
}

proc mouse_port1_x {} {
    lappend ::mouse_idle [reg A]
    invoke_controller 0x00DB 14 mouse_port1_y
}

proc mouse_port1_y {} {
    lappend ::mouse_idle [reg A]
    unplug joyporta
    unplug joyportb
    plug joyportb mouse
    invoke_controller 0x00DB 16 mouse_port2_requested
}

proc mouse_port2_requested {} {
    lappend ::mouse_idle [reg A]
    invoke_controller 0x00DB 17 mouse_port2_x
}

proc mouse_port2_x {} {
    lappend ::mouse_idle [reg A]
    invoke_controller 0x00DB 18 mouse_port2_y
}

proc mouse_port2_y {} {
    lappend ::mouse_idle [reg A]
    record_controller [format "MOUSE_IDLE=%02X,%02X,%02X,%02X,%02X,%02X" \
        {*}$::mouse_idle]
    invoke_controller 0x00D8 2 mouse_button_neutral
}

proc mouse_button_neutral {} {
    record_controller [format "MOUSE_BUTTON=%02X,%02X" \
        [reg A] [debug read ioports 0xA2]]
    invoke_controller 0x00DE 1 gtpdl1_done
}

proc gtpdl1_done {} {
    lappend ::gtpdl [reg A]
    invoke_controller 0x00DE 5 gtpdl5_done
}

proc gtpdl5_done {} {
    lappend ::gtpdl [reg A]
    invoke_controller 0x00DE 9 gtpdl9_done
}

proc gtpdl9_done {} {
    lappend ::gtpdl [reg A]
    record_controller [format "PADDLE=%02X,%02X,%02X" {*}$::gtpdl]
    invoke_controller 0x0096 15 psg_final
}

proc psg_final {} {
    lappend ::psg_port_b [reg A]
    record_controller [format "PSG_INIT=%02X,%02X" \
        $::psg_mixer $::psg_initial]
    record_controller [format "PSG_PORT_B=%02X,%02X,%02X" \
        {*}$::psg_port_b]
    exit
}

after time 1.0 start_probe
after realtime 30 exit
