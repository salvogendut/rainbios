<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Main CHGMOD bitmap dispatch — issue #169

2026-09-09, local branch `fix/169-main-chgmod-bitmap`, based on `aa875b5`.
Issue: <https://github.com/salvogendut/rainbios/issues/169>.

## Changes

The MSX2 main BIOS now routes modes 5–8 to the existing SUB-ROM CHGMOD
provider through EXTROM. A CD-signature search guards the call and refreshes
EXBRSA. Existing slot handoff code owns mapping/restoration. MSX1 mode support
is unchanged, including its historical guarded Screen 7 path. The forwarding
body lives after the fixed Nextor keyboard-compatibility entry at `0D89h`.

Integration exposed two defects in the previously bypassed provider:

- R1 left display/VBlank disabled in modes 6–8 (and display disabled in 5).
  All four bitmap modes now return with both enabled (`R1=60h`).
- HMMV NX bytes were reversed: a width of 1/2 rather than 256/512. The clear
  now uses the correct low/high order and still waits for command completion.

The new `MAIN_CHGMOD_PROBE` cartridge variant reuses the existing bitmap,
palette, paged-VRAM and text-return workload, but enters main `005Fh` through
CALSLT. It additionally checks per-mode R0/R1 shadows and poisons/reads the
last visible bitmap byte to catch incomplete clearing. The openMSX observer
waits five seconds for these now-full-width clears instead of two.

## Validation

All local logs below are in `build/evidence/` in this RainBIOS worktree.

- `make test`: **417 host tests passed**, plus the mandatory pinned BBC BASIC
  source build/tests. `full-bitmap-fixed.log` contains the successful host
  suite followed by the separately failing 1983 main probe described below.
- New main probe against unchanged pre-fix ROM: **FAIL**, as expected,
  before the first successful bitmap transition. `main-chgmod-before.log`.
- `test-openmsx-main-chgmod` and `test-openmsx-msx2-services`: **PASS**,
  including full clear, enabled R1, palette/VRAM and font-after-command checks.
  `openmsx-bitmap-final.log` and `build/openmsx/m1/{main-chgmod,msx2-services}.txt`.
- Current-source 1983 `5fce06f`: unchanged MSX1 `test-1983-chgmod` and direct
  `test-1983-msx2-subrom-services` **PASS**. `1983-current-controls.log`.
- Actual GEOBENCH, new Omega ROM, 1983 core `5fce06f`: **PASS** Screen 6 and
  Screen 7; three Clock/Calculator launch/reuse/close cycles plus 50 80-ms Desk
  open/cancel cycles per mode with Clock seconds enabled. Final one window,
  scheduler stack maximum 53. Evidence in the GEOBENCH checkout:
  `build/msx-buttons-82/evidence/1983-rain-bitmap-{6,7}/result.json`.

### Remaining discrepancy — do not count as a pass

Tracked separately in [issue #170](https://github.com/salvogendut/rainbios/issues/170)
so merging the bitmap-dispatch fix does not erase the qualification finding.

The strengthened **main** probe fails `CE_FONT` in 1983, both installed
`c01c807` and an isolated executable built from unchanged `5fce06f` sources:
first main-RDVRM font read returns `00`, expected `38`. Other mode, clear,
palette and VRAM markers match; the probe reaches its final spin.
`1983-current-probes.log`. The original direct-SUB-ROM control passes.

A disposable observer cartridge repeated the same font read twice without
rewriting the font: both subsequent reads return `38` (`F37A/F37B`), while
the original `F36F` remains `00`. See `cefont-diagnostic.log` and the local
`cefont-probe.asm`. This localizes the discrepancy to the first read rather
than a missing font; it does **not** prove whether RainBIOS access timing or
1983's VRAM prefetch timing is responsible. openMSX returns `38` on the
original assertion. The acceptance test was not weakened or turned into a
retry. Resolve this separately before claiming complete firmware qualification.

## Reproduction and artifacts

From the RainBIOS worktree, using the distrobox toolchain:

```sh
make test BBC_BASIC_DIR=/var/home/salvogendut/Dev/bbcbasic-z80-msx
make test-openmsx-main-chgmod test-openmsx-msx2-services \
  BBC_BASIC_DIR=/var/home/salvogendut/Dev/bbcbasic-z80-msx
make test-1983-main-chgmod \
  BBC_BASIC_DIR=/var/home/salvogendut/Dev/bbcbasic-z80-msx \
  EMULATOR_1983=/path/to/1983 MODELS_1983=/path/to/1983-models.conf
```

Candidate SHA-256:

- MSX2 main: `2c5dd90e6994f409f852312bd1f4fe47439b1e19a9400fa4a8733eaa31727337`
- SUB-ROM: `7b06e3e10990d2d815cf8b9a640e689167ab47b0f90df821cb48d0e7158049a0`
- Omega: `0c33ea9d4f5efa9330071c1f240410bd61a4ae19b9db5da410e48049c8c2bd59`

The fix was prepared in a separate worktree under GEOBENCH's
`build/rainbios-169`, leaving the normal sibling RainBIOS checkout on clean
main during implementation. The user requested PR/merge on 2026-09-09;
consult the linked issue and PR for publication state. No ROM was imported
into `../1983`. No real-hardware qualification or general MSX2 firmware
completeness is claimed.
