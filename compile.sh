#!/bin/bash

echo "Compiling..."

if [ -z "$1" ]; then
    echo "Error: No input file specified."
    echo "Usage: $0 <filename>"
    exit 1
fi
if [ ! -f "programs/$1" ]; then
    echo "Error: File 'programs/$1' not found."
    exit 1
fi

name="${1%.*}"
mkdir -p out
cp "programs/$1" casm
cd casm
#Compiler
./spasm -E "$1"
rm "$1"
#Linker
python3 binpac8x.py "$name.bin"
mv "$name.bin" ../out/
mv "$name.8xp" ../out/
cd ..

echo "Done!"
