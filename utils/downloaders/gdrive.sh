#!/usr/bin/env bash

# New all-in-one gdrive downloader, from https://github.com/GitHub30/gdrive.sh/blob/master/gdrive.sh
# GitHub30/gdrive.sh is licensed under the
# MIT License

function _usage() {
    echo -e "\e[36;1m\n  $(basename ${0}) Example Usage:\e[0m\n"
    echo -e "\e[32;1m    user@machine:\e[0m\e[34;1m~/Downloads\e[0m$ ${0} '1mC0h7QokENsY4N-rgqVNGxmaiDwtxJvxqMHxjGt4llA'"
    echo -e "\e[32;1m    user@machine:\e[0m\e[34;1m~/Downloads\e[0m$ ${0} 'https://docs.google.com/document/d/1mC0h7QokENsY4N-rgqVNGxmaiDwtxJvxqMHxjGt4llA/edit?usp=sharing'"
    echo -e "\e[32;1m    user@machine:\e[0m\e[34;1m~/Downloads\e[0m$ ${0} 'https://drive.google.com/drive/folders/1PDR-BTlbj1bWXZ867HwcS5XVNwhaTo2y?usp=sharing'"
    echo -e "\n\e[32m    Provide any Google Drive/Docs File/Folder URL or Just file_id from URL\e[0m\n"
}

id="$1"
if [ ! "$id" ] || [ $# = 0 ]; then
    _usage
    sleep 1s && exit 1
else
    case "$id" in
        'https://drive.google.com/open?id='*) id=$(echo "$id" | awk -F'=|&' '{printf"%s",$2}' 2>/dev/null);;
        'https://drive.google.com/file/d/'*|'https://docs.google.com/file/d/'*|'https://drive.google.com/drive/folders/'*) id=$(echo "$id" | awk -F'/|\?' '{printf"%s",$6}' 2>/dev/null);;
    esac
    printf "Downloading From %s, Please Wait...\n" "$1"
    if echo "$1" | grep -q '^https://drive.google.com/drive/folders/'; then
        api_key="AIzaSyC1qbk75NzWBvSaDh6KnsjjA9pIrP4lYIE"
        json=$(curl -s https://takeout-pa.clients6.google.com/v1/exports?key=$api_key -H 'origin: https://drive.google.com' -H 'content-type: application/json' -d '{"archiveFormat":null,"archivePrefix":null,"conversions":null,"items":[{"id":"'${id}'"}],"locale":null}')
        echo "$json" | grep -A100000 exportJob | grep -e percentDone -e status
        export_job_id=$(echo "$json" | grep -A100000 exportJob | awk -F'"' '$0~/^    "id"/{print$4}')
        storage_paths=''
        until [ "$storage_paths" ]; do
            json=$(curl -s "https://takeout-pa.clients6.google.com/v1/exports/$export_job_id?key=$api_key" -H 'origin: https://drive.google.com')
            echo "$json" | grep -B2 -A100000 exportJob | grep -e percentDone -e status
            storage_paths=$(echo "$json" | grep -A100000 exportJob | awk -F'"' '$0~/^        "storagePath"/{print$4}')
            sleep .5s
        done
        for storage_path in ${storage_paths}; do
            curl --progress-bar -s -OJ "$storage_path"
        done
        filenames=$(echo "$json" | grep -A100000 exportJob | awk -F'"' '$0~/^        "fileName"/{print$4}')
        for filename in ${filenames}; do
            unzip -o "$filename"
        done
        rm ${filenames}
    fi
    url="https://drive.google.com/uc?export=download&id=$id"
    curl -sOJLc /tmp/cookie "$url"
    filename=$(basename "$url")
    test -f "$filename" && rm "$filename"
    confirm="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"
    if [ "$confirm" ]; then
        curl --progress-bar -s -OJLb /tmp/cookie "$url&confirm=$confirm"
    fi
fi

