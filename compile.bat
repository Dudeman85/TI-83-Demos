@echo off
echo Compiling...

if "%~1"=="" (
    echo Error: No input file specified.
    echo Usage: %~nx0 ^<filename^>
    exit /b 1
)
if not exist "programs\%~1" (
    echo Error: File 'programs\%~1' not found.
    exit /b 1
)

set "name=%~n1"
if not exist "out" mkdir out
copy "programs\%~1" "casm\" >nul
cd casm
:: Compiler
spasm64.exe -E "%~1"
del "%~1"
:: Linker
python binpac8x.py "%name%.bin"
move "%name%.bin" "..\out\" >nul
move "%name%.8xp" "..\out\" >nul
cd ..

echo Done!