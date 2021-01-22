#!/bin/bash

PHOTO_DIR=${1:-/home/data/photos}
NON_PHOTO_DIR=${2:-/home/data/non-photos}


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

echo "Finding non-photos files, rename and move them to non-photos dir"
while IFS= read -r line
do
    ## take some action on ${line}
    echo ""
    echo "${line}"
    abspath=$(echo "${line}"| awk -F ': ' '{print $1}')
    mime=$(echo "${line}"| awk -F ': ' '{print $2}')
    relpath=${abspath#"${PHOTO_DIR}/"}
    fname=$(basename ${relpath})
    fdir=$(dirname ${relpath})
    ftype=$(echo "${mime}"| awk -F '/' '{print $1}')
    ext=$(jq -r ".\"${mime}\".extensions[0]" mime.json)
    dstdir="${NON_PHOTO_DIR}/${ftype}/${fdir}"
    dstpath="${dstdir}/${fname%.*}.${ext}"
    mkdir -p "${dstdir}"
    mv "${abspath}" "${dstpath}"
    mv "${abspath}.xmp" "${dstpath}.xmp"
    echo "Moved ${abspath} => ${dstpath}"
done < <(find "${PHOTO_DIR}" -type f -not -name "*.xmp" -exec file -N --mime-type -- {} + | grep -v image)
