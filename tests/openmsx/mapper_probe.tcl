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
    # Page 3 maps segment 0 in the 3,2,1,0 baseline. Map the highest segment of
    # a 4 MiB mapper into page 3, plant a marker, then return to segment 0 and
    # confirm it is gone.
    debug write "ioports" 0xFF 255
    poke 0xC000 0x7A
    set seg255 [peek 0xC000]
    debug write "ioports" 0xFF 0
    set seg0 [peek 0xC000]
    puts $handle [format "SEG255=%02X" $seg255]
    puts $handle [format "SEG0=%02X" $seg0]
    close $handle
    exit
}

# Capture during the boot-logo interval, before the automatic BASIC launch
# legitimately maps page 1 into RAM.
after time 0.9 start_probe
after realtime 15 {
    catch {close $::mapper_handle}
    exit
}
