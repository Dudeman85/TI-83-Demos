@echo off
echo Compiling...
copy programs\%1.asm casm
cd casm
spasm64.exe -E %1.asm
del %1.asm
python binpac8x.py %1.bin
move %1.bin ..\out
move %1.8xp ..\out
cd ..
echo Done!
