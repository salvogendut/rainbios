# Source-isolated development policy

RainBIOS is intended to be an independently maintainable open-source
implementation. This policy is an engineering provenance rule, not legal
advice.

## Implementation inputs

Firmware implementation may be based on:

- publicly distributed MSX interface documentation and hardware data sheets;
- behavior observed by running software on hardware or in an emulator, when
  use of the tested firmware is authorized;
- original compatibility tests that describe inputs and externally visible
  outputs;
- open-source code whose license is compatible with this repository, provided
  adaptation is explicit and all required attribution is retained.

Firmware implementation must not be based on:

- proprietary or otherwise non-redistributable BIOS source code;
- disassembly, decompilation, or annotated listings of proprietary ROMs;
- copied or mechanically transformed proprietary tables, fonts, messages,
  logos, audio, or other assets;
- recollection-based rewrites of a proprietary routine after studying its
  implementation.

The proprietary source trees adjacent to this repository are quarantined from
RainBIOS implementation work. Their presence is not permission to derive code
from them.

## Compatibility observations

Black-box comparison should record:

- the public API or hardware behavior under test;
- initial register, memory, slot, and device state;
- the invocation or event;
- resulting registers, flags, memory, ports, and timing within a stated
  tolerance;
- the model and version of the test environment.

Tests should compare behavior, not ROM bytes or internal control flow. Test
fixtures must not contain proprietary ROM fragments. Proprietary firmware
paths and hashes belong in local configuration, never in the repository.

When stricter separation is needed, one contributor records a behavior-only
test specification and a contributor who has not inspected the proprietary
implementation writes the firmware routine.

## Open-source prior art

Consultation of open-source firmware is allowed, but it changes the provenance
from a fully independent implementation to an attributed open-source
adaptation for the affected code. Record the project, revision, license,
files or documentation consulted, and purpose in `docs/REFERENCES.md`.

Do not silently transplant code. Preserve per-file notices where required and
prefer a clean implementation from interface documentation when that is
reasonably straightforward.

## Review checklist

A firmware change is ready to merge when:

- its behavior is tied to an allowed source or an original experiment;
- it contains no proprietary expression or extracted asset;
- open-source attribution is complete;
- tests cover normal behavior and relevant edge cases;
- the ABI status table and roadmap remain truthful.
