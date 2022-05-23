#!/bin/sh

# This basic program is used for unpacking .pac file of Spreadtrum Firmware used in SPD Flash Tool for flashing.
# can run in dash. dd, od, tr are used mainly
#
# Created : 2nd April 2022
# Author  : HemanthJabalpuri
#
# This file has been put into the public domain.
# You can do whatever you want with this file.

pacf="$1"
outdir="$2"

mkdir -p "$outdir"

szVersion="$(dd if="$pacf" bs=1 count=48 2>/dev/null)"
dwSize="$(dd if="$pacf" bs=1 skip=48 count=4 2>/dev/null | od -An -t d4 | tr -d ' ')"
partitionCount="$(dd if="$pacf" bs=1 skip=1076 count=4 2>/dev/null | od -An -t d4 | tr -d ' ')"

echo "--$szVersion--"
echo "--$dwSize--"
echo "--$partitionCount--"

seekoff=2124
for i in $(seq $partitionCount); do
  filename="$(dd if="$pacf" bs=1 skip=$((seekoff+516)) count=512 2>/dev/null)"
  partitionSize="$(dd if="$pacf" bs=1 skip=$((seekoff+1540)) count=4 2>/dev/null | od -An -t d4 | tr -d ' ')"
  if [ $partitionSize -eq 0 ]; then
    seekoff=$((seekoff+2580))
    continue
  fi
  partitionAddrInPac="$(dd if="$pacf" bs=1 skip=$((seekoff+1552)) count=4 2>/dev/null | od -An -t d4 | tr -d ' ')"
  echo "--$filename--"
  echo "--$partitionSize--"
  echo "--$partitionAddrInPac--"

  dd if="$pacf" of="$outdir/$filename" bs=1 skip=$partitionAddrInPac count=$partitionSize
  seekoff=$((seekoff+2580))
done
