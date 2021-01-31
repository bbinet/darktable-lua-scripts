#!/bin/bash

IMPORT_DIR="${1:-/home/data/A_IMPORTER/video}"
VIDEOS_DIR="${2:-/home/data/videos}"

if [ ! -e "mime.json" ]
then
    echo "Downloading mime-type database in mime.json"
    wget -O mime.json https://raw.githubusercontent.com/jshttp/mime-db/master/src/nginx-types.json
fi

if ! grep -q "video/mp2t" /etc/magic
then
    echo "Add video/mp2t mimetype detection to /etc/magic"
    echo "
4 byte 0x47
>5 beshort 0x4000
>>7 byte ^0xF
>>>196 byte 0x47
>>>>388 byte 0x47
>>>>>580 byte 0x47 M2TS MPEG transport stream, v2
!:mime video/mp2t
" | sudo tee -a /etc/magic
fi

#exiftool -m -r -p '$directory/$filename,$DateTimeOriginal,$CreateDate,$ModifyDate,$FileModifyDate' -q -f $IMPORT_DIR > _videos.csv
while IFS=, read -r srcpath dt tags
do
    if [ -z "$srcpath" ] || [ -z "$dt" ]
    then
        echo "Skip line... can't parse: $srcpath,$dt,$tags"
        continue
    fi
    if [ ! -f "$srcpath" ]
    then
        echo "Skip file: $srcpath does not exist"
        continue
    fi
    mime=$(file -N --mime-type -- "$srcpath" | awk -F ': ' '{print $2}')
    ext=$(jq -r ".\"${mime}\".extensions[0]" mime.json)
    exiftool -q -m "-FileModifyDate=$dt" $srcpath
    dtpath=$(exiftool -m -d '%Y/%m/%d/%H%M%S' -p '$FileModifyDate' -q -f $srcpath)
    subdirs=$(dirname $dtpath)
    bname=$(basename $dtpath)
    dstdir="${VIDEOS_DIR}/${subdirs}"
    dstpath="${dstdir}/${bname}.${ext}"
    i=0
    while [ -f "${dstpath}" ]
    do
	i=$((i+1))
        dstpath="${dstdir}/${bname}_${i}.${ext}"
    done
    echo "Moving \"${srcpath}\" => \"${dstpath}\""
    mkdir -p "$dstdir"
    echo "{\"datetime\": \"$dtpath\", \"tags\": \"$tags\"}" > "${dstpath}.json"
    mv "${srcpath}" "${dstpath}"
done < videos.csv
