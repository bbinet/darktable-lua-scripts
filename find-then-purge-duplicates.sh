#!/bin/bash
# sudo apt install jdupes

if [ -z "${1}" ]
then
    echo "Usage: $0 </path/to/dir>"
    exit 1
fi

DUPLICATES_DIR="${1}"
DUPLICATES_TXT="/tmp/${DUPLICATES_DIR//\//_}_duplicates.txt"

if [ -f "${DUPLICATES_TXT}" ]
then
    echo "/!\ We will now force remove all files from "${DUPLICATES_TXT}" except the first ones"
    echo "Hit Enter key to proceed, or Ctrl+C to abort..."
    read
    while read -r line; do
	#if grep -v "^$"; then
	if [ -z "$line" ]
	then
	    unset keep
	    echo ">>>>>>>>>>>"
	else
	    if [ -z "$keep" ]
	    then
		keep="$line"
		echo "keep => $line"
	    else
		echo "rm -f \"$line\""
		rm -f "$line"
		rm -f "${line}.json" # also try to delete video json side files
	    fi
	fi
    done < "${DUPLICATES_TXT}"
    rm -f "${DUPLICATES_TXT}"
else
    jdupes -r "$DUPLICATES_DIR" | tee "${DUPLICATES_TXT}"
    echo "List of duplicates have been saved to ${DUPLICATES_TXT} file."
    echo "Please edit this file and place the file you want to keep as the first item in the list of duplicates."
    echo ""
    echo "When done, run this script again:"
    echo "$ $0 $@"
fi
