#!/bin/sh

cd build
../make_core.py ../core.json ../vt100.kg1
../make_core.py ../core_mini.json ../vt100.kg2
../make_core.py ../core_minig.json ../vt100.kg3
cd ..
