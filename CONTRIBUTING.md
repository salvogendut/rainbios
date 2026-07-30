# Contributing

Read `docs/DEVELOPMENT_POLICY.md` before working on firmware code.

Every compatibility change should include:

1. the public specification or independently observed behavior being
   implemented;
2. a focused automated test where practical;
3. an update to `docs/abi/main-bios.csv` when an entry point changes status;
4. a reference-log entry when a new external source is consulted.

Keep implementation commits small enough that provenance and behavior can be
reviewed together. Do not commit third-party ROMs, ROM fragments, proprietary
source, disassemblies, extracted fonts, screenshots containing substantial
copyrighted content, or generated output based on those materials.

Code copied or adapted from compatible open-source software must retain the
notices its license requires and must be identified in the commit and source
file. Interface addresses and hardware constants should still cite the public
document or open-source reference used to verify them.

Before submitting a change, run:

```sh
make test
```
