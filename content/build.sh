#!/bin/bash

cp -r images output
rst2s5.py --theme medium-white presentation.txt ./output/presentation.html
