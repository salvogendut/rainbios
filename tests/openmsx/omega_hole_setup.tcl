# SPDX-License-Identifier: BSD-3-Clause

# The original Omega decodes all eight mapper-address bits even when only its
# first 512 KiB SRAM chip is populated. Writes to segments 32-255 therefore do
# not reach RAM instead of mirroring a lower segment as openMSX MemoryMapper
# normally does. Turn writes to the two probe bytes in those segments into
# open-bus FFh values to reproduce that distinction without changing openMSX.
proc omega_hole_discard_write {} {
    set segment [debug read "Probe Mapper regs" 2]
    if {$segment >= 32} {
        set offset [expr {($segment * 0x4000) + ($::wp_last_address & 0x3FFF)}]
        debug write "Probe Mapper" $offset 0xFF
    }
}

debug set_watchpoint write_mem {0x8000 0x8001} {} \
    {omega_hole_discard_write}
