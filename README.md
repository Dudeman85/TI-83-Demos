# TI-83+ Demos
Put .asm programs in /programs, outputs are put in /out

Useful resources: [TI-83 ASM Tutorial](https://tutorials.eeems.ca/ASMin28Days/lesson/toc.html),
[z80 Instruction Set](https://tutorials.eeems.ca/ASMin28Days/ref/z80is.html)

## Build system setup
1. Download [BinPac8x](https://www.ticalc.org/archives/files/fileinfo/429/42915.html) linker (requires Python)
2. Download [spasm]() compiler
3. Put binpac8x.py and spasm into the casm folder
4. Run compile.bat or compile.sh with the name of the program in the programs folder
5. Use [TI Connect](https://education.ti.com/en/products/computer-software/ti-connect-sw) or TiLP (sudo apt install tilp2) to transfer program to calculator
6. (Optional) Wabbitemu emulator: [Windows](https://github.com/sputt/wabbitemu), [Linux](https://github.com/alberthdev/wxwabbitemu)
