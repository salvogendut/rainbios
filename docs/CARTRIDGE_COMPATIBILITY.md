<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Cartridge compatibility

This matrix records black-box smoke tests. External ROMs are neither source
inputs nor RainBIOS release artifacts, and a successful boot is not a claim
that every game or diagnostic function works.

## 2026-08-01 results

| Local fixture | SHA-256 | openMSX | 1983 |
| --- | --- | --- | --- |
| `Arkano.rom` (32 KiB) | `b14d1d94a1cc23efff146e8ad62e4364047c9023bba47642a0daa67f51122bcc` | Round 1 rendered; `PC=412Ch`, slot `D4h`, VDP `R0=02h/R1=E2h` | Round 1 rendered; `PC=0D56h`, slot `D4h`, same VDP state |
| `diag.rom` (32 KiB) | `496d77166f5d3195a47a7a8c70511860126bd0b45cd48f54928b51cc3114c3c8` | Expected CPU/slot/VDP state (`PC=5F6Ch`, `D4h`, `R0=00h/R1=F0h`), but current screenshot is one color: target fails | Menu rendered; `PC=468Ch`, slot `D4h`, `R0=00h/R1=F0h`; Screen 3 path also passes at `PC=4C95h`, `R1=E8h` |

The checks require a valid PC, a RainBIOS RAM stack, the 32 KiB primary-slot
map, the expected video mode, and a nonblank rendered frame. They do not require
the sampled PC to remain in cartridge page 1, so these are startup/UI smoke
tests rather than execution-coverage proofs. The 1983 run additionally counts
nonzero VRAM bytes. No cartridge bytes are embedded in test reports or
screenshots committed by these targets.

Run both local fixtures with:

```sh
make test-external-cartridges \
    OPENMSX='flatpak run org.openmsx.openMSX'
```

By default, the target looks under `../1983/ROMS`. Different local locations
can be supplied without changing tracked files:

```sh
make test-external-cartridges \
    ARKANO_ROM=/path/to/Arkano.rom \
    MSX_DIAGNOSTICS_ROM=/path/to/diag.rom \
    OPENMSX='flatpak run org.openmsx.openMSX'
```

The openMSX external probes sample after a fixed emulated-time interval. The
independent 1983 checks run for exactly 1,200 NTSC frames (4,500 for the Screen
3 path). The current openMSX diagnostics screenshot failure is retained as a
known compatibility regression rather than relaxed to a false pass.
