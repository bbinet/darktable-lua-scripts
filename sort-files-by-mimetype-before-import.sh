#!/bin/bash

NOT_SORTED_DIR=${1:-/home/data/NOT_SORTED}
NOT_SORTED_DIR=${NOT_SORTED_DIR%/}
SORTED_DIR=${2:-/home/data/A_IMPORTER}
SORTED_DIR=${SORTED_DIR%/}

if [ -z "$NOT_SORTED_DIR" ]
then
    echo "Please specify directory to process as first argument"
    exit 1
fi

if [ ! -e "mime.json" ]
then
    echo "Downloading mime-type database in mime.json"
    wget -O mime.json https://raw.githubusercontent.com/jshttp/mime-db/master/src/nginx-types.json
fi

if ! grep -q "video/mp2t" /etc/magic
then
    echo "Add video/mpeg and video/mp2t mimetype detection to /etc/magic"
    echo "
0	 belong		    0x00000001
>4	 byte&0x1F	    0x07	   JVT NAL sequence, H.264 video
>>5      byte               66             \b, baseline
>>5      byte               77             \b, main
>>5      byte               88             \b, extended
>>7      byte               x              \b @ L %u
0        belong&0xFFFFFF00  0x00000100
>3       byte               0xBA           MPEG sequence
!:mime  video/mpeg

4 byte 0x47
>5 beshort 0x4000
>>7 byte ^0xF
>>>196 byte 0x47
>>>>388 byte 0x47
>>>>>580 byte 0x47 M2TS MPEG transport stream, v2
!:mime video/mp2t
" | sudo tee -a /etc/magic
fi

# ensure all files are owned by clemence
sudo chown -R clemence: "${SORTED_DIR}"

echo "Finding files, rename, sort and move them to directory: $SORTED_DIR/"
while IFS= read -r line
do
    ## take some action on ${line}
    echo ""
    echo "${line}"
    abspath=$(echo "${line}"| awk -F ': ' '{print $1}')
    mime=$(echo "${line}"| awk -F ': ' '{print $2}')
    relpath=${abspath#"${NOT_SORTED_DIR}/"}
    fname=$(basename ${relpath})
    fdir=$(dirname ${relpath})
    ftype=$(echo "${mime}"| awk -F '/' '{print $1}')
    ext=$(jq -r ".\"${mime}\".extensions[0]" mime.json)
    dstdir="${SORTED_DIR}/${ftype}/${fdir}"
    dstpath="${dstdir}/${fname%.*}.${ext}"
    mkdir -p "${dstdir}"
    mv "${abspath}" "${dstpath}"
    mv "${abspath}.xmp" "${dstpath}.xmp"
    echo "Moved ${abspath} => ${dstpath}"
done < <(find "${NOT_SORTED_DIR}" -type f -not -name "*.xmp" -exec file -N --mime-type -- {} +)
