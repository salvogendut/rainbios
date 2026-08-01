# SPDX-License-Identifier: BSD-3-Clause
#
# Controller test double for the fault-injection cartridge. The shared WD2793
# driver is redirected to a RAM window at 0xE000; this script plays the
# controller there. Because STATUS and COMMAND alias the same address on the
# WD2793, a static RAM value cannot model every fault, so a write watchpoint
# reacts to each command and programs the LINES/STATUS/TRACK registers the
# driver reads next, keyed by the scenario mailbox at 0xE008. The runner
# wraps this script in a file that defines disk_fault_output, disk_fault_pass
# and disk_fault_fails before sourcing it.

set throttle off

if {![info exists disk_fault_output]} {
    set disk_fault_output /tmp/rainbios-disk-fault.txt
}
if {![info exists disk_fault_pass]} {
    set disk_fault_pass 0x43D2
}
if {![info exists disk_fault_fails]} {
    set disk_fault_fails {}
}

# Runs after the driver writes a WD2793 command. Pokes the registers the
# driver reads next; the poke does not re-enter this watchpoint.
proc double_command_write {} {
    set command [peek 0xE000]
    set scenario [peek 0xE008]
    if {$command == 0x1C} {
        # Seek command: IRQ asserts immediately unless deliberately stuck.
        if {$scenario == 0} {
            poke 0xE001 [peek 0xE003]
            poke 0xE000 0x00
            poke 0xE007 0x00
        } elseif {$scenario == 1} {
            poke 0xE000 0x00
            poke 0xE007 0x40
        } elseif {$scenario == 2} {
            poke 0xE000 0x80
            poke 0xE007 0x40
        } elseif {$scenario == 3} {
            poke 0xE000 0x80
            poke 0xE007 0x00
        } elseif {$scenario == 4} {
            poke 0xE000 0x08
            poke 0xE007 0x00
        } elseif {$scenario == 5} {
            poke 0xE000 0x10
            poke 0xE007 0x00
        } elseif {$scenario == 6} {
            poke 0xE001 0xFF
            poke 0xE000 0x00
            poke 0xE007 0x00
        }
    } elseif {$command == 0x84} {
        # Read command: DRQ/IRQ polarity per scenario.
        if {$scenario == 7} {
            poke 0xE007 0xC0
        } elseif {$scenario == 8} {
            poke 0xE007 0x40
        } elseif {$scenario == 9} {
            poke 0xE000 0x00
            poke 0xE007 0x80
        } elseif {$scenario == 10} {
            poke 0xE000 0x08
            poke 0xE007 0x00
        } elseif {$scenario == 11} {
            poke 0xE000 0x04
            poke 0xE007 0x00
        } elseif {$scenario == 12} {
            poke 0xE000 0x10
            poke 0xE007 0x00
        } elseif {$scenario == 13} {
            poke 0xE000 0x80
            poke 0xE007 0x00
        } elseif {$scenario == 14} {
            poke 0xE000 0x02
            poke 0xE007 0x00
        } else {
            poke 0xE000 0x00
            poke 0xE007 0x00
        }
    } else {
        # Force interrupt: retire any pending transfer.
        poke 0xE007 0xC0
    }
}

proc write_disk_fault_report {status} {
    set handle [open $::disk_fault_output w]
    puts $handle "STATUS=$status"
    puts $handle [format "PC=%04X" [reg PC]]
    puts $handle [format "SCENARIO=%02X" [peek 0xE008]]
    puts $handle [format "SLOT=%02X" [expr {[debug read "ioports" 0xA8] & 0xFF}]]
    close $handle
}

proc disk_fault_succeeded {} {
    write_disk_fault_report PASS
    exit
}

proc disk_fault_failed {name} {
    write_disk_fault_report FAIL
    set handle [open $::disk_fault_output a]
    puts $handle "LABEL=$name"
    close $handle
    exit
}

proc disk_fault_timed_out {} {
    write_disk_fault_report TIMEOUT
    exit
}

debug set_watchpoint write_mem 0xE000 {} {double_command_write}
debug set_bp $::disk_fault_pass \
    {[lindex [get_selected_slot 1] 0] == 1} \
    {disk_fault_succeeded}
foreach entry $::disk_fault_fails {
    regexp -- {([^=]+)=(0x[0-9A-Fa-f]+)} $entry _ name address
    debug set_bp $address \
        {[lindex [get_selected_slot 1] 0] == 1} \
        [list disk_fault_failed $name]
}

after realtime 120 disk_fault_timed_out
