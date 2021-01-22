#!/bin/bash

PHOTO_DIR=${1:-/home/data/photos}

find "$PHOTO_DIR" -type f -exec file -N -i -- {} + | grep -v xmp | grep -v image > non_photos.txt
