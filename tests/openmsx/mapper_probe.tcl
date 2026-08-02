# SPDX-License-Identifier: BSD-3-Clause

set throttle off

if {![info exists mapper_output]} {
    set mapper_output /tmp/rainbios-mapper.txt
}

proc start_probe {} {
    set handle [open $::mapper_output w]
    puts $handle [format "MAPPER_SEGMENTS=%02X" [peek 0xF345]]
    puts $handle [format "BASELINE_MAP=%02X" \
        [expr {[debug read "ioports" 0xA8] & 0xFF}]]
    # Page 3 maps segment 0 in the 3,2,1,0 baseline. Map segment 7 into page 3,
    # plant a marker, then return to segment 0 and confirm it is gone: the
    # mapper must expose distinct memory beyond the fixed 64 KiB baseline.
    debug write "ioports" 0xFF 7
    poke 0xC000 0x7A
    set seg7 [peek 0xC000]
    debug write "ioports" 0xFF 0
    set seg0 [peek 0xC000]
    puts $handle [format "SEG7=%02X" $seg7]
    puts $handle [format "SEG0=%02X" $seg0]
    close $handle
    exit
}

after time 3.0 start_probe
after realtime 15 {
    catch {close $::mapper_handle}
    exit
}
