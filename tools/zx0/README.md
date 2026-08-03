# Vendored ZX0 compressor

These files are the ZX0 2.2 compressor sources by Einar Saukas, vendored from
commit `ecde3a2ae05061fe06469ed46df81a33b7de7d86` of
<https://github.com/einar-saukas/ZX0>.

RainBIOS builds this host tool from source and uses it only to compress generated
visual assets. The matching Z80 decoder is in `src/zx0_decompress.asm`. Both are
covered by the BSD 3-Clause license reproduced in `LICENSES/ZX0.txt`.
