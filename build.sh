#!/bin/bash

rm -rf output
mkdir -p output/images
cp -r content/images output
rst2s5.py --theme medium-white content/presentation.txt output/presentation.html
