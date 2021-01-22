#!/bin/bash
# sudo apt install jdupes

PHOTO_DIR=${1:-/home/data/photos}

jdupes -r "$PHOTO_DIR" > duplicates.txt
