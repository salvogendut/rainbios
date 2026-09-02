# SPDX-License-Identifier: BSD-3-Clause

if {![info exists boot_info_output]} {
    set boot_info_output /tmp/rainbios-boot-info.txt
}
if {![info exists boot_info_expect_rtc]} {
    set boot_info_expect_rtc 0
}

proc boot_info_seed_rtc {} {
    # Block 0: 02/09/26 12:34:56, weekday 3. The RTC year value is 46,
    # because the MSX convention stores an offset from 1980. Program through
    # the emulated I/O ports so openMSX updates both its registers and internal
    # time state, while keeping RainBIOS's own presence probe read-only.
    debug write ioports 0xB4 13
    debug write ioports 0xB5 0
    foreach {register value} {
        0 6  1 5  2 4  3 3  4 2  5 1  6 3
        7 2  8 0  9 9  10 0  11 6  12 4
    } {
        debug write ioports 0xB4 $register
        debug write ioports 0xB5 $value
    }
    # Block 1 register 10 selects 24-hour mode, then mode 8 restores block 0
    # with the timer enabled.
    debug write ioports 0xB4 13
    debug write ioports 0xB5 1
    debug write ioports 0xB4 10
    debug write ioports 0xB5 1
    debug write ioports 0xB4 13
    debug write ioports 0xB5 8
}

proc boot_info_row_hex {row} {
    set address [expr {(($row - 1) * 0x100) + ((16 - 1) * 8)}]
    set bytes [debug read_block VRAM $address [expr {14 * 8}]]
    binary scan $bytes H* result
    return $result
}

proc boot_info_capture {} {
    set handle [open $::boot_info_output w]
    puts $handle "RAM=[boot_info_row_hex 5]"
    puts $handle "VRAM=[boot_info_row_hex 7]"
    puts $handle "DATE=[boot_info_row_hex 10]"
    puts $handle "TIME=[boot_info_row_hex 12]"
    puts $handle [format "MAPPER=%02X" [peek 0xF345]]
    puts $handle [format "MODE=%02X" [peek 0xFAFC]]
    close $handle
    exit
}

set throttle off
after time 0.9 {boot_info_capture}
