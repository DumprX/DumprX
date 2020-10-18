#!/usr/bin/env bash

# Clear Screen
tput reset || clear

# Unset Every Variables That We Are Gonna Use Later
unset PROJECT_DIR INPUTDIR UTILSDIR OUTDIR TMPDIR FILEPATH FILE EXTENSION UNZIP_DIR ArcPath \
	GITHUB_TOKEN GIT_ORG TG_TOKEN CHAT_ID

# Resize Terminal Window To Atleast 30x90 For Better View
printf "\033[8;30;90t" || true

# Banner
function __bannerTop() {
	cat <<EOBT

    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║    ╔═╗╦ ╦╔═╗╔═╗╔╗╔╦═╗ ╦  ╔═╗┬┬─┐┌┬┐┬ ┬┌─┐┬─┐┌─┐  ╔╦╗┬ ┬┌┬┐┌─┐┌─┐┬─┐          ║
    ║    ╠═╝╠═╣║ ║║╣ ║║║║╔╩╦╝  ╠╣ │├┬┘││││││├─┤├┬┘├┤    ║║│ ││││├─┘├┤ ├┬┘          ║
    ║    ╩  ╩ ╩╚═╝╚═╝╝╚╝╩╩ ╚═  ╚  ┴┴└─┴ ┴└┴┘┴ ┴┴└─└─┘  ═╩╝└─┘┴ ┴┴  └─┘┴└─  v1.1.0  ║
    ║ ---------------------------------------------------------------------------- ║
    ║  Based Upon Dumpyara from AndroidDumps, Infused w/ their Firmware_extractor  ║
    ╚══════════════════════════════════════════════════════════════════════════════╝
EOBT
}

# Usage/Help
function _usage() {
	printf "  \e[1;32;40m \u2730 Usage: \$ %s <Firmware File/Extracted Folder -OR- Supported Website Link> \e[0m\n" "${0}"
	printf "\t\e[1;32m -> Firmware File: The .zip/.rar/.7z/.tar/.bin/.ozip/.kdz etc. file \e[0m\n\n"
	sleep .5s
	printf " \e[1;34m >> Supported Websites: \e[0m\n"
	printf "\e[36m\t1. Directly Accessible Download Link From Any Website\n"
	printf "\t2. Filehosters like - mega.nz | mediafire.com | zippyshare.com\n"
	printf "\t\tGoogle Drive/Docs | androidfilehost.com\e[0m\n"
	printf "\t\e[33m >> Must Wrap Website Link Inside Single-quotes ('')\e[0m\n"
	sleep .2s
	printf " \e[1;34m >> Supported File Formats For Direct Operation:\e[0m\n"
	printf "\t\e[36m *.zip | *.rar | *.tar | *.7z | *.tar.md5 | *.ozip | *.kdz | ruu_*exe\n"
	printf "\t system.new.dat | system.new.dat.br | system.new.dat.xz\n"
	printf "\t system.new.img | system.img | system-sign.img | UPDATE.APP\n"
	printf "\t *.emmc.img | *.img.ext4 | system.bin | system-p | payload.bin\n"
	printf "\t *.nb0 | .*chunk* | *.pac | *super*.img | *system*.sin\e[0m\n\n"
}

# Welcome Banner
printf "\e[32m" && __bannerTop && printf "\e[0m" && sleep 0.3s

# Function Input Check
if [[ $# = 0 ]]; then
	printf "\n  \e[1;31;40m \u2620 Error: No Input Is Given.\e[0m\n\n"
	sleep .5s && _usage && sleep 1s && exit 1
elif [[ "${1}" = "" ]]; then
	printf "\n  \e[1;31;40m ! BRUH: Enter Firmware Path.\e[0m\n\n"
	sleep .5s && _usage && sleep 1s && exit 1
elif [[ "${1}" = " " || -n "$2" ]]; then
	printf "\n  \e[1;31;40m ! BRUH: Enter Only Firmware File Path.\e[0m\n\n"
	sleep .5s && _usage && sleep 1s && exit 1
else
	_usage			# Output Usage By Default
fi

# Set Base Project Directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
if echo "${PROJECT_DIR}" | grep " "; then
	printf "\nProject Directory Path Contains Empty Space,\nPlace The Script In A Proper UNIX-Formatted Folder\n\n"
	sleep 1s && exit 1
fi

# Sanitize And Generate Folders
INPUTDIR="${PROJECT_DIR}"/input		# Firmware Download/Preload Directory
UTILSDIR="${PROJECT_DIR}"/utils		# Contains Supportive Programs
OUTDIR="${PROJECT_DIR}"/out			# Contains Final Extracted Files
TMPDIR="${OUTDIR}"/tmp				# Temporary Working Directory

rm -rf "${TMPDIR}" 2>/dev/null
mkdir -p "${OUTDIR}" "${TMPDIR}" 2>/dev/null

## See README.md File For Program Credits
# Set Utility Program Alias
SDAT2IMG="${UTILSDIR}"/sdat2img.py
SIMG2IMG="${UTILSDIR}"/bin/simg2img
UNSIN="${UTILSDIR}"/unsin
PAYLOAD_EXTRACTOR="${UTILSDIR}"/ota_payload_extractor/extract_android_ota_payload.py
DTB_EXTRACTOR="${UTILSDIR}"/extract-dtb.py
DTC="${UTILSDIR}"/dtc
VMLINUX2ELF="${UTILSDIR}"/vmlinux_to_elf/main.py
KALLSYMS_FINDER="${UTILSDIR}"/vmlinux_to_elf/kallsyms_finder.py
OZIPDECRYPT="${UTILSDIR}"/oppo_ozip_decrypt/ozipdecrypt.py
LPUNPACK="${UTILSDIR}"/lpunpack
SPLITUAPP="${UTILSDIR}"/splituapp.py
PACEXTRACTOR="${UTILSDIR}"/pacextractor
NB0_EXTRACT="${UTILSDIR}"/nb0-extract
KDZ_EXTRACT="${UTILSDIR}"/kdztools/unkdz.py
DZ_EXTRACT="${UTILSDIR}"/kdztools/undz.py
RUUDECRYPT="${UTILSDIR}"/RUU_Decrypt_Tool
EXTRACT_IKCONFIG="${UTILSDIR}"/extract-ikconfig
UNPACKBOOT="${UTILSDIR}"/unpackboot.sh
# Set Names of Downloader Utility Programs
BADOWN="${UTILSDIR}"/downloaders/badown.sh
GDRIVE="${UTILSDIR}"/downloaders/gdrive.sh
AFHDL="${UTILSDIR}"/downloaders/afh_dl.py

# Partition List That Are Currently Supported
PARTITIONS="system system_ext system_other systemex vendor cust odm oem factory product xrom modem dtbo boot tz oppo_product preload_common opproduct reserve india my_preload my_odm my_stock my_operator my_country my_product my_company my_engineering my_heytap"
EXT4PARTITIONS="system vendor cust odm oem factory product xrom systemex oppo_product preload_common"
OTHERPARTITIONS="tz.mbn:tz tz.img:tz modem.img:modem NON-HLOS:modem boot-verified.img:boot dtbo-verified.img:dtbo"

# NOTE: $(pwd) is ${PROJECT_DIR}
if echo "${1}" | grep -q "${PROJECT_DIR}/input/" && [[ $(find "${INPUTDIR}" -maxdepth 1 -type f -size +300M -print | wc -l) -eq 1 ]]; then
	printf "Input Directory Exists And Contains File\n"
	cd "${INPUTDIR}"/ || exit
	# Input File Variables
	FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f 2>/dev/null)	# INPUTDIR's FILEPATH is Always File
	FILE=${FILEPATH##*/}
	EXTENSION=${FILEPATH##*.}
	if echo "${EXTENSION}" | grep -q "zip\|rar\|7z\|tar$"; then
		UNZIP_DIR=${FILE%.*}			# Strip The File Extention With %.*
	fi
else
	# Attempt To Download File/Folder From Internet
	if echo "${1}" | grep -q -e '^\(https\?\|ftp\)://.*$' >/dev/null; then
		URL=${1}
		mkdir -p "${INPUTDIR}" 2>/dev/null
		cd "${INPUTDIR}"/ || exit
		rm -rf "${INPUTDIR:?}"/* 2>/dev/null
		if echo "${URL}" | grep -q "mega.nz\|zippyshare.com\|mediafire.com"; then
			( "${BADOWN}" "${URL}" ) || exit 1
		elif echo "${URL}" | grep -q "androidfilehost.com"; then
			( python3 "${AFHDL}" -l "${URL}" ) || exit 1
		elif echo "${URL}" | grep -q "drive.google.com\|docs.google.com"; then
			( "${GDRIVE}" "${URL}" ) || exit 1
		else
			aria2c --log-level=error -l - -x16 -s8 "${URL}" || { wget -q --show-progress --progress=bar:force "${URL}" || exit 1; }
		fi
		unset URL
		for f in *; do detox -r "${f}" 2>/dev/null; done		# Detox Filename
		# Input File Variables
		FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f 2>/dev/null)	# Single File
		[[ $(echo "${FILEPATH}" | tr ' ' '\n' | wc -l) -gt 1 ]] && FILEPATH=$(find "$(pwd)" -maxdepth 2 -type d) 	# Base Folder
	else
		# For Local File/Folder, Do Not Use Input Directory
		FILEPATH=$(printf "%s\n" "$1")		# Relative Path To Script
		FILEPATH=$(realpath "${FILEPATH}")	# Absolute Path
		if echo "${1}" | grep " "; then
			if [[ -w "${FILEPATH}" ]]; then
				detox -r "${FILEPATH}" 2>/dev/null
				FILEPATH=$(echo "${FILEPATH}" | inline-detox)
			fi
		fi
		[[ ! -e "${FILEPATH}" ]] && { echo -e "Input File/Folder Doesn't Exist" && exit 1; }
	fi
	# Input File Variables
	FILE=${FILEPATH##*/}
	EXTENSION=${FILEPATH##*.}
	if echo "${EXTENSION}" | grep -q "zip\|rar\|7z\|tar$"; then
		UNZIP_DIR=${FILE%.*}			# Strip The File Extention With %.*
	fi
	if [[ -d "${FILEPATH}" || "${EXTENSION}" == "" ]]; then
		printf "Directory Detected.\n"
		# TODO: Need To Add Check-Firmware Function, Then Move To OUTDIR/TMPDIR
		# UPDATE:: Local Folder With Extracted {system,vendor}.img Or {system,vendor}.new.dat* Is Currently Supported
		if find "${FILEPATH}" -maxdepth 1 -type f | grep -q ".*.tar$\|.*.zip\|.*.rar\|.*.7z"; then
			printf "Supplied Folder Has Compressed Archive That Needs To Re-Load\n"
			# Set From Download Directory
			ArcPath=$(find "${INPUTDIR}"/ -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print)
			# If Empty, Set From Original Local Folder
			[[ -z "${ArcPath}" ]] && ArcPath=$(find "${FILEPATH}"/ -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print)
			if ! echo "${ArcPath}" | grep -q " "; then
				# Assuming There're Only One Archive To Re-Load And Process
				cd "${PROJECT_DIR}"/ || exit
				( bash "${0}" "${ArcPath}" ) || exit 1
				exit
			elif echo "${ArcPath}" | grep -q " "; then
				printf "More Than One Archive File Is Available In %s Folder.\nPlease Use Direct Archive Path Along With This Toolkit\n" "${FILEPATH}" && exit 1
			fi
		elif find "${FILEPATH}" -maxdepth 1 -type f | grep ".*system.ext4.tar.*\|.*chunk\|system\/build.prop\|system.new.dat\|system_new.img\|system.img\|system-sign.img\|system.bin\|payload.bin\|.*rawprogram*\|system.sin\|.*system_.*\.sin\|system-p\|super\|UPDATE.APP\|.*.pac\|.*.nb0" | grep -q -v ".*chunk.*\.so$"; then
			printf "Copying Everything Into %s For Further Operations." "${TMPDIR}"
			cp -a "${FILEPATH}"/* "${TMPDIR}"/
			unset FILEPATH
		else
			printf "\e[31m BRUH: This type of firmware is not supported.\e[0m\n"
			cd "${PROJECT_DIR}"/ || exit
			rm -rf "${TMPDIR}" "${OUTDIR}"
			exit 1
		fi
	fi
fi

cd "${PROJECT_DIR}"/ || exit

# Function for extracting superimage
function superimage_extract() {
	printf "Creating super.img.raw ...\n"
	"${SIMG2IMG}" super.img super.img.raw 2>/dev/null
	if [[ ! -s super.img.raw && -f super.img ]]; then
		mv super.img super.img.raw
	fi
	for partition in ${PARTITIONS}; do
		( "${LPUNPACK}" --partition="${partition}"_a super.img.raw || "${LPUNPACK}" --partition="${partition}" super.img.raw ) 2>/dev/null
		[[ -f "${partition}"_a.img ]] && mv "${partition}"_a.img "${partition}".img
		if [[ -f "${FILE}" ]]; then
			foundpartitions=$(7z l -ba "${FILE}" | gawk '{print $NF}' | grep "${partition}".img)
			7z e -y -- "${FILE}" "${foundpartitions}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
		fi
	done
	rm -rf super.img.raw
}

printf "Extracting firmware on: %s\n" "${OUTDIR}"

cd "${TMPDIR}"/ || exit

# Oppo .ozip Check
if [[ $(head -c12 "${FILEPATH}" 2>/dev/null | tr -d '\0') == "OPPOENCRYPT!" ]] || [[ "${EXTENSION}" == "ozip" ]]; then
	printf "Oppo/Realme ozip Detected.\n"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/"${FILE}" 2>/dev/null || cp -a "${FILEPATH}" "${TMPDIR}"/"${FILE}"
	printf "Decrypting ozip And Making A Zip...\n"
	python3 "${OZIPDECRYPT}" "${TMPDIR}"/"${FILE}"
	[[ -d "${TMPDIR}"/out ]] && 7z a -r "${INPUTDIR}"/"${FILE%.*}".zip "${TMPDIR}"/out/*
	if [[ -f "${FILE%.*}".zip ]]; then
		mkdir -p "${INPUTDIR}" 2>/dev/null
		mv "${FILE%.*}".zip "${INPUTDIR}"/
	fi
	rm -rf "${TMPDIR:?}"/*
	printf "Re-Loading The Decrypted Zip File.\n"
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${INPUTDIR}"/"${FILE%.*}".zip ) || exit 1
	exit
fi
# LG KDZ Check
if echo "${FILEPATH}" | grep -q ".*.kdz" || [[ "${EXTENSION}" == "kdz" ]]; then
	printf "LG KDZ Detected.\n"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/ 2>/dev/null || cp -a "${FILEPATH}" "${TMPDIR}"/
	python3 "${KDZ_EXTRACT}" -f "${FILE}" -x -o "./" 2>/dev/null
	DZFILE=$(ls -- *.dz)
	printf "Extracting All Partitions As Individual Images.\n"
	python3 "${DZ_EXTRACT}" -f "${DZFILE}" -s -o "./" 2>/dev/null
	rm -f "${TMPDIR}"/"${FILE}" "${TMPDIR}"/"${DZFILE}" 2>/dev/null
	# dzpartitions="gpt_main persist misc metadata vendor system system_other product userdata gpt_backup tz boot dtbo vbmeta cust oem odm factory modem NON-HLOS"
	find "${TMPDIR}" -maxdepth 1 -type f -name "*.image" | while read -r i; do mv "${i}" "${i/.image/.img}" 2>/dev/null; done
	find "${TMPDIR}" -maxdepth 1 -type f -name "*_a.img" | while read -r i; do mv "${i}" "${i/_a.img/.img}" 2>/dev/null; done
	find "${TMPDIR}" -maxdepth 1 -type f -name "*_b.img" -exec rm -rf {} \;
fi
# HTC RUU Check
if echo "${FILEPATH}" | grep -i "^ruu_" | grep -q -i "exe$" || [[ "${EXTENSION}" == "exe" ]]; then
	printf "HTC RUU Detected.\n"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/ || cp -a "${FILEPATH}" "${TMPDIR}"/
	printf "Etracting System And Firmware Partitions...\n"
	"${RUUDECRYPT}" -s "${FILE}" 2>/dev/null
	"${RUUDECRYPT}" -f "${FILE}" 2>/dev/null
	find "${TMPDIR}"/OUT* -name "*.img" -exec mv {} "${TMPDIR}"/ \;
fi

# Extract & Move Raw Otherpartitons To OUTDIR
if [[ -f "${FILEPATH}" ]]; then
	for otherpartition in ${OTHERPARTITIONS}; do
		filename=$(echo "${otherpartition}" | cut -d':' -f1)
		outname=$(echo "${otherpartition}" | cut -d':' -f2)
		if 7z l -ba "${FILEPATH}" | grep -q "${filename}"; then
			printf "%s Detected For %s\n" "${filename}" "${outname}"
			foundfile=$(7z l -ba "${FILEPATH}" | grep "${filename}" | awk '{print $NF}')
			7z e -y -- "${FILEPATH}" "${foundfile}" 2>/dev/null >> "${TMPDIR}"/zip.log
			output=$(ls -- *"${filename}"*) 2>/dev/null
			[[ ! -e "${TMPDIR}"/"${outname}".img ]] && mv "${output}" "${TMPDIR}"/"${outname}".img
			"${SIMG2IMG}" "${TMPDIR}"/"${outname}".img "${OUTDIR}"/"${outname}".img 2>/dev/null
			[[ ! -s "${OUTDIR}"/"${outname}".img && -f "${TMPDIR}"/"${outname}".img ]] && mv "${outname}".img "${OUTDIR}"/"${outname}".img
		fi
	done
fi

# Extract/Put Image/Extra Files In TMPDIR
if 7z l -ba "${FILEPATH}" | grep -q "system.new.dat" || [[ $(find "${TMPDIR}" -type f -name "system.new.dat*" -print | wc -l) -ge 1 ]]; then
	printf "A-only DAT-Formatted OTA detected.\n"
	for partition in ${PARTITIONS}; do
		if [[ -f "${FILEPATH}" ]]; then
			7z e -y "${FILEPATH}" "${partition}".new.dat* "${partition}".transfer.list "${partition}".img 2>/dev/null >> "${TMPDIR}"/zip.log
		else
			find "${TMPDIR}" -type f \( -name "${partition}.new.dat*" -o -name "${partition}.transfer.list" -o -name "${partition}.img" \) -exec mv {} . \;
		fi
		# Join Split Compressed dat Files, If Any
		for e in "br xz"; do
			if [[ -f "${partition}".new.dat."${e}".1 ]]; then
				printf "Joining %s-compressed Split dat Files...\n" "${e}"
				cat "${partition}".new.dat."${e}".{0..999} 2>/dev/null >> "${partition}".new.dat."${e}"
				rm -rf "${partition}".new.dat."${e}".{0..999} 2>/dev/null
			fi
		done
		# Fallback, Join Split Normal dat Files
		if [[ -f "${partition}".new.dat.1 ]]; then
			printf "Joining Split dat Files...\n"
			cat "${partition}".new.dat.{0..999} 2>/dev/null >> "${partition}".new.dat
			rm -rf "${partition}".new.dat.{0..999} 2>/dev/null
		fi
		# Check: If dat* Is Compressed, Then Uncompress
		find . -maxdepth 1 -type f -name "*.new.dat.*" | cut -d'/' -f'2-' | while read -r i; do
			line=$(echo "${i}" | cut -d'.' -f1)
			if echo "${i}" | grep -q ".*.dat\.xz"; then
				printf "Converting xz %s dat To Normal\n" "${partition}"
				7z e -y "${i}" 2>/dev/null >> "${TMPDIR}"/zip.log
				rm -rf "${i}"
			fi
			if echo "${i}" | grep -q ".*.dat\.br"; then
				printf "Converting brotli %s dat To Normal\n" "${partition}"
				brotli -d "${i}"
				rm -rf "${i}"
			fi
			printf "Converting To %s Image...\n" "${partition}"
			python3 "${SDAT2IMG}" "${line}".transfer.list "${line}".new.dat "${TMPDIR}"/"${line}".img > "${TMPDIR}"/extract.log
			rm -rf "${line}".transfer.list "${line}".new.dat
		done
	done
elif 7z l -ba "${FILEPATH}" | grep -q ".*.nb0" || [[ $(find "${TMPDIR}" -type f -name "*.nb0*" | wc -l) -ge 1 ]]; then
	printf "nb0-Formatted Firmware Detected.\n"
	if [[ -f "${FILEPATH}" ]]; then
		to_extract=$(7z l -ba "${FILEPATH}" | grep ".*.nb0" | gawk '{print $NF}')
		7z e -y -- "${FILEPATH}" "${to_extract}" 2>/dev/null >> "${TMPDIR}"/zip.log
	else
		find "${TMPDIR}" -type f -name "*.nb0*" -exec mv {} . \; 2>/dev/null
	fi
	"${NB0_EXTRACT}" "${to_extract}" "${TMPDIR}"
elif 7z l -ba "${FILEPATH}" | grep system | grep chunk | grep -q -v ".*\.so$" || [[ $(find "${TMPDIR}" -type f -name "*system*chunk*" | wc -l) -ge 1 ]]; then
	printf "Chunk Detected.\n"
	for partition in ${PARTITIONS}; do
		if [[ -f "${FILEPATH}" ]]; then
			foundpartitions=$(7z l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "${partition}".img)
			7z e -y -- "${FILEPATH}" *"${partition}"*chunk* */*"${partition}"*chunk* "${foundpartitions}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
		else
			find "${TMPDIR}" -type f -name "*${partition}*chunk*" -exec mv {} . \; 2>/dev/null
			find "${TMPDIR}" -type f -name "*${partition}*.img" -exec mv {} . \; 2>/dev/null
		fi
		rm -f -- *"${partition}"_b*
		rm -f -- *"${partition}"_other*
		romchunk=$(find . -maxdepth 1 -type f -name "*${partition}*chunk*" | cut -d'/' -f'2-' | sort)
		if echo "${romchunk}" | grep -q "sparsechunk"; then
			if [[ ! -f "${partition}".img ]]; then
				"${SIMG2IMG}" "${romchunk}" "${partition}".img.raw 2>/dev/null
				mv "${partition}".img.raw "${partition}".img
			fi
			rm -rf -- *"${partition}"*chunk* 2>/dev/null
		fi
	done
elif 7z l -ba "${FILEPATH}" | gawk '{print $NF}' | grep -q "system_new.img\|^system.img\|\/system.img\|\/system_image.emmc.img\|^system_image.emmc.img" || [[ $(find "${TMPDIR}" -type f -name "system*.img" | wc -l) -ge 1 ]]; then
	printf "Image File detected.\n"
	if [[ -f "${FILEPATH}" ]]; then
		7z x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	fi
	for f in "${TMPDIR}"/*; do detox -r "${f}" 2>/dev/null; done
	find "${TMPDIR}" -mindepth 2 -type f -name "*_image.emmc.img" | while read -r i; do mv "${i}" "${i/_image.emmc.img/.img}" 2>/dev/null; done
	find "${TMPDIR}" -mindepth 2 -type f -name "*_new.img" | while read -r i; do mv "${i}" "${i/_new.img/.img}" 2>/dev/null; done
	find "${TMPDIR}" -mindepth 2 -type f -name "*.img.ext4" | while read -r i; do mv "${i}" "${i/.img.ext4/.img}" 2>/dev/null; done
	find "${TMPDIR}" -mindepth 2 -type f -name "*.img" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	### Keep some files, add script here to retain them
	find "${TMPDIR}" -type f -iname "*Android_scatter.txt" -exec mv {} "${OUTDIR}"/ \;
	find "${TMPDIR}" -type f -iname "*Release_Note.txt" -exec mv {} "${OUTDIR}"/ \;
	find "${TMPDIR}" -type f ! -name "*img*" -exec rm -rf {} \;	# delete other files
	find "${TMPDIR}" -maxdepth 3 -type f -name "*.img" -exec mv {} . \; 2>/dev/null
elif 7z l -ba "${FILEPATH}" | grep -q "system.sin\|.*system_.*\.sin" || [[ $(find "${TMPDIR}" -type f -name "system*.sin" | wc -l) -ge 1 ]]; then
	printf "sin Image Detected.\n"
	[[ -f "${FILEPATH}" ]] && 7z x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	# Remove Unnecessary Filename Part
	to_remove=$(find . -type f | grep ".*boot_.*\.sin" | gawk '{print $NF}' | sed -e 's/boot_\(.*\).sin/\1/')
	[[ -z "$to_remove" ]] && to_remove=$(find . -type f | grep ".*cache_.*\.sin" | gawk '{print $NF}' | sed -e 's/cache_\(.*\).sin/\1/')
	[[ -z "$to_remove" ]] && to_remove=$(find . -type f | grep ".*vendor_.*\.sin" | gawk '{print $NF}' | sed -e 's/vendor_\(.*\).sin/\1/')
	find "${TMPDIR}" -mindepth 2 -type f -name "*.sin" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	find "${TMPDIR}" -maxdepth 1 -type f -name "*_${to_remove}.sin" | while read -r i; do mv "${i}" "${i/_${to_remove}.sin/.sin}" 2>/dev/null; done	# proper names
	"${UNSIN}" -d "${TMPDIR}"
	find "${TMPDIR}" -maxdepth 1 -type f -name "*.ext4" | while read -r i; do mv "${i}" "${i/.ext4/.img}" 2>/dev/null; done	# proper names
elif 7z l -ba "${FILEPATH}" | grep ".pac$" || [[ $(find "${TMPDIR}" -type f -name "*.pac" | wc -l) -ge 1 ]]; then
	printf "pac Detected.\n"
	[[ -f "${FILEPATH}" ]] && 7z x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	for f in "${TMPDIR}"/*; do detox -r "${f}"; done
	pac_list=$(find . -type f -name "*.pac" | cut -d'/' -f'2-' | sort)
	for file in ${pac_list}; do
		"${PACEXTRACTOR}" -f "${file}"
	done
elif 7z l -ba "${FILEPATH}" | grep -q "system.bin" || [[ $(find "${TMPDIR}" -type f -name "system.bin" | wc -l) -ge 1 ]]; then
	printf "bin Images Detected\n"
	[[ -f "${FILEPATH}" ]] && 7z x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	find "${TMPDIR}" -mindepth 2 -type f -name "*.bin" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	find "${TMPDIR}" -maxdepth 1 -type f -name "*.bin" | while read -r i; do mv "${i}" "${i/\.bin/.img}" 2>/dev/null; done	# proper names
elif 7z l -ba "${FILEPATH}" | grep -q "system-p" || [[ $(find "${TMPDIR}" -type f -name "system-p*" | wc -l) -ge 1 ]]; then
	printf "P-Suffix Images Detected\n"
	for partition in ${PARTITIONS}; do
		if [[ -f "${FILEPATH}" ]]; then
			foundpartitions=$(7z l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "${partition}-p")
			7z e -y -- "${FILEPATH}" "${foundpartitions}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
		else
			foundpartitions=$(find . -type f -name "*${partition}-p*" | cut -d'/' -f'2-')
		fi
	[[ -n "${foundpartitions}" ]] && mv "$(ls "${partition}"-p*)" "${partition}".img
	done
elif 7z l -ba "${FILEPATH}" | grep -q "system-sign.img" || [[ $(find "${TMPDIR}" -type f -name "system-sign.img" | wc -l) -ge 1 ]]; then
	printf "Signed Images Detected\n"
	[[ -f "${FILEPATH}" ]] && 7z x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	for f in "${TMPDIR}"/*; do detox -r "${f}"; done
	for partition in ${PARTITIONS}; do
		[[ -e "${TMPDIR}"/"${partition}".img ]] && mv "${TMPDIR}"/"${partition}".img "${OUTDIR}"/"${partition}".img
	done
	find "${TMPDIR}" -mindepth 2 -type f -name "*-sign.img" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	find "${TMPDIR}" -type f ! -name "*-sign.img" -exec rm -rf {} \;	# delete other files
	find "${TMPDIR}" -maxdepth 1 -type f -name "*-sign.img" | while read -r i; do mv "${i}" "${i/-sign.img/.img}" 2>/dev/null; done	# proper .img names
	sign_list=$(find . -maxdepth 1 -type f -name "*.img" | cut -d'/' -f'2-' | sort)
	for file in ${sign_list}; do
		rm -rf "${TMPDIR}"/x.img >/dev/null 2>&1
		MAGIC=$(head -c4 "${TMPDIR}"/"${file}" | tr -d '\0')
		if [[ "${MAGIC}" == "SSSS" ]]; then
			printf "Cleaning %s with SSSS header\n" "${file}"
			# This Is For little_endian Arch
			offset_low=$(od -A n -x -j 60 -N 2 "${TMPDIR}"/"${file}" | sed 's/ //g')
			offset_high=$(od -A n -x -j 62 -N 2 "${TMPDIR}"/"${file}" | sed 's/ //g')
			offset_low=0x${offset_low:0-4}
			offset_high=0x${offset_high:0-4}
			offset_low=$(printf "%d" "${offset_low}")
			offset_high=$(printf "%d" "${offset_high}")
			offset=$((65536*offset_high+offset_low))
			dd if="${TMPDIR}"/"${file}" of="${TMPDIR}"/x.img iflag=count_bytes,skip_bytes bs=8192 skip=64 count=${offset} >/dev/null 2>&1
		else	# Header With BFBF Magic Or Another Unknowed Header
			dd if="${TMPDIR}"/"${file}" of="${TMPDIR}"/x.img bs=$((0x4040)) skip=1 >/dev/null 2>&1
		fi
	done
elif 7z l -ba "${FILEPATH}" | grep -q "super.img" || [[ $(find "${TMPDIR}" -type f -name "super.img" | wc -l) -ge 1 ]]; then
	printf "Super Image Detected\n"
	#mv -f "${FILEPATH}" "${TMPDIR}"/
	if [[ -f "${FILEPATH}" ]]; then
		foundsupers=$(7z l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "super.img")
		7z e -y -- "${FILEPATH}" "${foundsupers}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
	fi
	superchunk=$(find . -maxdepth 1 -type f -name "*super*chunk*" | cut -d'/' -f'2-' | sort)
	if echo "${superchunk}" | grep -q "sparsechunk"; then
		"${SIMG2IMG}" "${superchunk}" super.img.raw 2>/dev/null
		rm -rf -- *super*chunk*
	fi
	( [[ -f super.img ]] && superimage_extract ) || exit 1
elif 7z l -ba "${FILEPATH}" | grep tar.md5 | gawk '{print $NF}' | grep -q AP_ || [[ $(find "${TMPDIR}" -type f -name "*AP_*tar.md5" | wc -l) -ge 1 ]]; then
	printf "AP tarmd5 Detected\n"
	#mv -f "${FILEPATH}" "${TMPDIR}"/
	[[ -f "${FILEPATH}" ]] && 7z e -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	printf "Extracting Images...\n"
	for i in ./*.tar.md5; do
		tar -xf "${i}" || exit 1
		rm -fv "${i}" || exit 1
		printf "Extracted %s\n" "${i}"
	done
	for i in *.lz4; do
		lz4 -dc "${i}" > "${i/.lz4/}" || exit 1
		rm -fv "${i}" || exit 1
		printf "Extracted %s\n" "${i}"
	done
	( [[ -f super.img ]] && superimage_extract ) || exit 1
	if [[ ! -f system.img ]]; then
		printf "Extract failed\n"
		rm -rf "${TMPDIR}" && exit 1
	fi
elif 7z l -ba "${FILEPATH}" | grep -q payload.bin || [[ $(find "${TMPDIR}" -type f -name "payload.bin" | wc -l) -ge 1 ]]; then
	printf "AB OTA Payload Detected\n"
	[[ -f "${FILEPATH}" ]] && 7z e -y "${FILEPATH}" payload.bin 2>/dev/null >> "${TMPDIR}"/zip.log
	python3 "${PAYLOAD_EXTRACTOR}" payload.bin "${TMPDIR}"
	rm -f payload.bin
elif 7z l -ba "${FILEPATH}" | grep ".*.rar\|.*.zip\|.*.7z\|.*.tar$" || [[ $(find "${TMPDIR}" -type f \( -name "*.rar" -o -name "*.zip" -o -name "*.7z" -o -name "*.tar" \) | wc -l) -ge 1 ]]; then
	printf "Rar/Zip/7Zip/Tar Archived Firmware Detected\n"
	if [[ -f "${FILEPATH}" ]]; then
		mkdir -p "${TMPDIR}"/"${UNZIP_DIR}" 2>/dev/null
		7z e -y "${FILEPATH}" -o"${TMPDIR}"/"${UNZIP_DIR}" 2>/dev/null >> "${TMPDIR}"/zip.log
		for f in "${TMPDIR}"/"${UNZIP_DIR}"/*; do detox -r "${UNZIP_DIR}"/"${f}" 2>/dev/null; done
	fi
	zip_list=$(find ./"${UNZIP_DIR}" -type f -size +300M \( -name "*.rar" -o -name "*.zip" -o -name "*.7z" -o -name "*.tar" \) | cut -d'/' -f'2-' | sort)
	mkdir -p "${INPUTDIR}" 2>/dev/null
	rm -rf "${INPUTDIR:?}"/* 2>/dev/null
	for file in ${zip_list}; do
		mv "${TMPDIR}"/"${UNZIP_DIR}"/"${file}" "${INPUTDIR}"/
		rm -rf "${TMPDIR:?}"/*
		cd "${PROJECT_DIR}"/ || exit
		( bash "${0}" "${INPUTDIR}"/"${file}" ) || exit 1
		exit
	done
	rm -rf "${TMPDIR:?}"/"${UNZIP_DIR}"
	exit 0
elif 7z l -ba "${FILEPATH}" | grep -q "UPDATE.APP" || [[ $(find "${TMPDIR}" -type f -name "UPDATE.APP") ]]; then
	printf "Huawei UPDATE.APP Detected\n"
	[[ -f "${FILEPATH}" ]] && 7z x "${FILEPATH}" UPDATE.APP 2>/dev/null >> "${TMPDIR}"/zip.log
	find "${TMPDIR}" -type f -name "UPDATE.APP" -exec mv {} . \;
	python3 "${SPLITUAPP}" -f "UPDATE.APP" -l super || (
	for partition in ${PARTITIONS}; do
		python3 "${SPLITUAPP}" -f "UPDATE.APP" -l "${partition/.img/}" || printf "%s not found in UPDATE.APP\n" "${partition}"
	done )
	find output/ -type f -name "*.img" -exec mv {} . \;	# Partitions Are Extracted In "output" Folder
	[[ -f super.img ]] && superimage_extract
fi

# $(pwd) == "${TMPDIR}"

# Process All otherpartitions From TMPDIR Now
for otherpartition in ${OTHERPARTITIONS}; do
	filename=$(echo "${otherpartition}" | cut -d':' -f1)
	outname=$(echo "${otherpartition}" | cut -d':' -f2)
	if [[ -f "${filename}" ]]; then
		printf "%s Detected For %s\n" "${filename}" "${outname}"
		output=$(ls -- *"${filename}"*) 2>/dev/null
		[[ ! -e "${TMPDIR}"/"${outname}".img ]] && mv "${output}" "${TMPDIR}"/"${outname}".img
		"${SIMG2IMG}" "${TMPDIR}"/"${outname}".img "${OUTDIR}"/"${outname}".img 2>/dev/null
		[[ ! -s "${OUTDIR}"/"${outname}".img && -f "${TMPDIR}"/"${outname}".img ]] && mv "${outname}".img "${OUTDIR}"/"${outname}".img
	fi
done

# Process All partitions From TMPDIR Now
for partition in ${PARTITIONS}; do
	[[ -f "${partition}".img ]] && "${SIMG2IMG}" "${partition}".img "${OUTDIR}"/"${partition}".img 2>/dev/null
	[[ ! -s "${OUTDIR}"/"${partition}".img && -f "${TMPDIR}"/"${partition}".img ]] && mv "${TMPDIR}"/"${partition}".img "${OUTDIR}"/"${partition}".img
	if [[ "${EXT4PARTITIONS}" =~ (^|[[:space:]])"${partition}"($|[[:space:]]) && -f "${OUTDIR}"/"${partition}".img ]]; then
		MAGIC=$(head -c12 "${OUTDIR}"/"${partition}".img | tr -d '\0')
		offset=$(LANG=C grep -aobP -m1 '\x53\xEF' "${OUTDIR}"/"${partition}".img | head -1 | gawk '{print $1 - 1080}')
		if echo "${MAGIC}" | grep -q "MOTO"; then
			[[ "$offset" == 128055 ]] && offset=131072
			printf "MOTO header detected on %s in %s\n" "${partition}" "${offset}"
		elif echo "${MAGIC}" | grep -q "ASUS"; then
			printf "ASUS header detected on %s in %s\n" "${partition}" "${offset}"
		else
			offset=0
		fi
		if [[ ! "${offset}" == "0" ]]; then
			dd if="${OUTDIR}"/"${partition}".img of="${OUTDIR}"/"${partition}".img-2 ibs=$offset skip=1 2>/dev/null
			mv -f "${OUTDIR}"/"${partition}".img-2 "${OUTDIR}"/"${partition}".img
		fi
	fi
	[[ ! -s "${OUTDIR}"/"${partition}".img && -f "${OUTDIR}"/"${partition}".img ]] && rm "${OUTDIR}"/"${partition}".img
done

cd "${OUTDIR}"/ || exit
rm -rf "${TMPDIR:?}"/*

# Extract boot.img
if [[ -f "${OUTDIR}"/boot.img ]]; then
	# Extract dts
	mkdir -p "${OUTDIR}"/bootimg "${OUTDIR}"/bootdts 2>/dev/null
	python3 "${DTB_EXTRACTOR}" "${OUTDIR}"/boot.img -o "${OUTDIR}"/bootimg >/dev/null
	find "${OUTDIR}"/bootimg -name '*.dtb' -type f | gawk -F'/' '{print $NF}' | while read -r i; do "${DTC}" -q -s -f -I dtb -O dts -o bootdts/"${i/\.dtb/.dts}" bootimg/"${i}"; done 2>/dev/null
	bash "${UNPACKBOOT}" "${OUTDIR}"/boot.img "${OUTDIR}"/boot >/dev/null
	printf "Boot extracted\n"
	# extract-ikconfig
	mkdir -p "${OUTDIR}"/bootRE
	bash "${EXTRACT_IKCONFIG}" "${OUTDIR}"/boot.img > "${OUTDIR}"/bootRE/ikconfig >/dev/null 2>&1
	[[ ! -s "${OUTDIR}"/bootRE/ikconfig ]] && rm -f "${OUTDIR}"/bootRE/ikconfig 2>/dev/null
	# vmlinux-to-elf
	python3 "${KALLSYMS_FINDER}" "${OUTDIR}"/boot.img > "${OUTDIR}"/bootRE/boot_kallsyms.txt >/dev/null 2>&1
	printf "boot_kallsyms.txt generated\n"
	python3 "${VMLINUX2ELF}" "${OUTDIR}"/boot.img "${OUTDIR}"/bootRE/boot.elf >/dev/null 2>&1
	printf "boot.elf generated\n"
fi

# Extract dtbo
if [[ -f "${OUTDIR}"/dtbo.img ]]; then
	mkdir -p "${OUTDIR}"/dtbo "${OUTDIR}"/dtbodts 2>/dev/null
	python3 "${DTB_EXTRACTOR}" "${OUTDIR}"/dtbo.img -o "${OUTDIR}"/dtbo >/dev/null
	find "${OUTDIR}"/dtbo -name '*.dtb' -type f | gawk -F'/' '{print $NF}' | while read -r i; do "${DTC}" -q -s -f -I dtb -O dts -o dtbodts/"${i/\.dtb/.dts}" dtbo/"${i}"; done 2>/dev/null
	printf "dtbo extracted\n"
fi

# Extract Files From All Usable PARTITIONS
for p in ${PARTITIONS}; do
	if ! echo "${p}" | grep -q "boot\|dtbo\|tz"; then
		if [[ -e "${p}.img" ]]; then
			mkdir "${p}" 2>/dev/null || rm -rf "${p:?}"/*
			printf "Extracting %s partition\n" "${p}"
			7z x "${p}".img -y -o"${p}"/ >/dev/null 2>&1
			rm "${p}".img >/dev/null 2>&1
		fi
	fi
done
# Remove Unnecessary Image Leftover From OUTDIR
for q in *.img; do
	if ! echo "${q}" | grep -q "boot\|dtbo\|tz"; then
		rm -f "${q}" 2>/dev/null
	fi
done

# Oppo/Realme Devices Have Some Images In A Euclid Folder In Their Vendor, Extract Those For Props
if [[ -d "vendor/euclid" ]]; then
	pushd vendor/euclid || exit 1
	for f in *.img; do
		[[ -f "${f}" ]] || continue
		7z x "${f}" -o"${f/.img/}"
		rm -fv "${f}"
	done
	popd || exit 1
fi

# board-info.txt
find "${OUTDIR}"/modem -type f -exec strings {} \; 2>/dev/null | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> "${OUTDIR}"/board-info.txt
find "${OUTDIR}"/tz* -type f -exec strings {} \; 2>/dev/null | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> "${OUTDIR}"/board-info.txt
if [ -e "${OUTDIR}"/vendor/build.prop ]; then
	strings "${OUTDIR}"/vendor/build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> "${OUTDIR}"/board-info.txt
fi
sort -u -o "${OUTDIR}"/board-info.txt "${OUTDIR}"/board-info.txt

# copy file names
chown "$(whoami)" ./* -R
chmod -R u+rwX ./*		#ensure final permissions
find . -type f | cut -d'/' -f'2-' | grep -v ".git/" > "${TMPDIR}"/all_filenames.txt
printf "Calculating Data File Sizes, Please Wait...\n"
while read -r i; do
	du -b "${i}" >> "${TMPDIR}"/sized_files.txt
done < "${TMPDIR}"/all_filenames.txt
sort -nr < "${TMPDIR}"/sized_files.txt > "${OUTDIR}"/all_files.txt

# set variables
[[ $(find "$(pwd)"/system "$(pwd)"/vendor "$(pwd)"/*product -maxdepth 2 -type f -name "build*.prop" 2>/dev/null | sort -u | gawk '{print $NF}') ]] || { printf "No system/vendor/product build*.prop found, pushing cancelled.\n" && exit 1; }

flavor=$(grep -oP "(?<=^ro.build.flavor=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${flavor}" ]] && flavor=$(grep -oP "(?<=^ro.vendor.build.flavor=).*" -hs vendor/build*.prop)
[[ -z "${flavor}" ]] && flavor=$(grep -oP "(?<=^ro.system.build.flavor=).*" -hs {system,system/system}/build*.prop)
[[ -z "${flavor}" ]] && flavor=$(grep -oP "(?<=^ro.build.type=).*" -hs {system,system/system}/build*.prop)
release=$(grep -oP "(?<=^ro.build.version.release=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${release}" ]] && release=$(grep -oP "(?<=^ro.vendor.build.version.release=).*" -hs vendor/build*.prop)
[[ -z "${release}" ]] && release=$(grep -oP "(?<=^ro.system.build.version.release=).*" -hs {system,system/system}/build*.prop)
id=$(grep -oP "(?<=^ro.build.id=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${id}" ]] && id=$(grep -oP "(?<=^ro.vendor.build.id=).*" -hs vendor/build*.prop)
[[ -z "${id}" ]] && id=$(grep -oP "(?<=^ro.system.build.id=).*" -hs {system,system/system}/build*.prop)
incremental=$(grep -oP "(?<=^ro.build.version.incremental=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${incremental}" ]] && incremental=$(grep -oP "(?<=^ro.vendor.build.version.incremental=).*" -hs vendor/build*.prop)
[[ -z "${incremental}" ]] && incremental=$(grep -oP "(?<=^ro.system.build.version.incremental=).*" -hs {system,system/system}/build*.prop)
tags=$(grep -oP "(?<=^ro.build.tags=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${tags}" ]] && tags=$(grep -oP "(?<=^ro.vendor.build.tags=).*" -hs vendor/build*.prop)
[[ -z "${tags}" ]] && tags=$(grep -oP "(?<=^ro.system.build.tags=).*" -hs {system,system/system}/build*.prop)
platform=$(grep -oP "(?<=^ro.board.platform=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${platform}" ]] && platform=$(grep -oP "(?<=^ro.vendor.board.platform=).*" -hs vendor/build*.prop)
[[ -z "${platform}" ]] && platform=$(grep -oP "(?<=^ro.system.board.platform=).*" -hs {system,system/system}/build*.prop)
manufacturer=$(grep -oP "(?<=^ro.product.manufacturer=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -oP "(?<=^ro.vendor.product.manufacturer=).*" -hs vendor/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -oP "(?<=^ro.system.product.manufacturer=).*" -hs {system,system/system}/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -oP "(?<=^ro.system.product.manufacturer=).*" -hs vendor/euclid/*/build.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -oP "(?<=^ro.product.manufacturer=).*" -hs oppo_product/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -oP "(?<=^ro.product.manufacturer=).*" -hs my_product/build*.prop)
fingerprint=$(grep -oP "(?<=^ro.build.fingerprint=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs vendor/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -oP "(?<=^ro.system.build.fingerprint=).*" -hs {system,system/system}/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -oP "(?<=^ro.product.build.fingerprint=).*" -hs product/build.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -oP "(?<=^ro.product.build.fingerprint=).*" -hs product/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -oP "(?<=^ro.build.fingerprint=).*" -hs my_product/build.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -oP "(?<=^ro.system.build.fingerprint=).*" -hs my_product/build.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs my_product/build.prop)
brand=$(grep -oP "(?<=^ro.product.brand=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.product.vendor.brand=).*" -hs vendor/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.vendor.product.brand=).*" -hs vendor/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.product.system.brand=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.product.system.brand=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.product.odm.brand=).*" -hs vendor/odm/etc/build*.prop)
[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.product.brand=).*" -hs oppo_product/build*.prop)
[[ -z "${brand}" ]] && brand=$(grep -oP "(?<=^ro.product.brand=).*" -hs my_product/build*.prop)
[[ -z "${brand}" ]] && brand=$(echo "$fingerprint" | cut -d'/' -f1)
codename=$(grep -oP "(?<=^ro.product.device=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.product.vendor.device=).*" -hs vendor/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.vendor.product.device=).*" -hs vendor/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.product.system.device=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.product.system.device=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.product.device=).*" -hs oppo_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.product.device=).*" -hs my_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.product.system.device=).*" -hs my_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.product.vendor.device=).*" -hs my_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(echo "$fingerprint" | cut -d'/' -f3 | cut -d':' -f1)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.build.fota.version=).*" -hs {system,system/system}/build*.prop | cut -d'-' -f1 | head -1)
description=$(grep -oP "(?<=^ro.build.description=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${description}" ]] && description=$(grep -oP "(?<=^ro.vendor.build.description=).*" -hs vendor/build*.prop)
[[ -z "${description}" ]] && description=$(grep -oP "(?<=^ro.system.build.description=).*" -hs {system,system/system}/build*.prop)
[[ -z "${description}" ]] && description=$(grep -oP "(?<=^ro.product.build.description=).*" -hs product/build.prop)
[[ -z "${description}" ]] && description=$(grep -oP "(?<=^ro.product.build.description=).*" -hs product/build*.prop)
[[ -z "${description}" ]] && description="${flavor} ${release} ${id} ${incremental} ${tags}"
branch=$(echo "${description}" | tr ' ' '-')
repo=$(echo "${brand}"_"${codename}"_dump | tr '[:upper:]' '[:lower:]')
platform=$(echo "${platform}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
top_codename=$(echo "${codename}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
manufacturer=$(echo "${manufacturer}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)

# Repo README File
printf "## %s\n- Manufacturer: %s\n- Platform: %s\n- Codename: %s\n- Brand: %s\n- Flavor: %s\n- Release: %s\n- Id: %s\n- Incremental: %s\n- Tags: %s\n- Fingerprint: %s\n- Branch: %s\n- Repo: %s\n" "${description}" "${manufacturer}" "${platform}" "${codename}" "${brand}" "${flavor}" "${release}" "${id}" "${incremental}" "${tags}" "${fingerprint}" "${branch}" "${repo}" > "${OUTDIR}"/README.md
printf "\n\n>Dumped by [Phoenix Firmware Dumper](https://github.com/DroidDumps/phoenix_firmware_dumper)\n" >> "${OUTDIR}"/README.md
cat "${OUTDIR}"/README.md

rm -rf "${TMPDIR}" 2>/dev/null

if [[ -s "${PROJECT_DIR}"/.github_token ]]; then
	GITHUB_TOKEN=$(< "${PROJECT_DIR}"/.github_token)	# Write Your Github Token In a Text File
	[[ -z "$(git config --get user.email)" ]] && git config user.email "DroidDumps@github.com"
	[[ -z "$(git config --get user.name)" ]] && git config user.name "DroidDumps"
	if [[ -s "${PROJECT_DIR}"/.github_orgname ]]; then
		GIT_ORG=$(< "${PROJECT_DIR}"/.github_orgname)	# Set Your Github Organization Name
	else
		GIT_USER="$(git config --get user.name)"
		GIT_ORG="${GIT_USER}"				# Otherwise, Your Username will be used
	fi
	# Check if already dumped or not
	curl -sf "https://raw.githubusercontent.com/${GIT_ORG}/${repo}/${branch}/all_files.txt" 2>/dev/null && { printf "Firmware already dumped!\nGo to https://github.com/%s/%s/tree/%s\n" "${GIT_ORG}" "${repo}" "${branch}" && exit 1; }
	# Remove The Journal File Inside System/Vendor
	find . -mindepth 2 -type d -name "\[SYS\]" -exec rm -rf {} \; 2>/dev/null
	# Files larger than 76MB will be split into 47MB parts as *.aa, *.ab, etc.
	mkdir -p "${TMPDIR}" 2>/dev/null
	find . -size +76M | cut -d'/' -f'2-' >| "${TMPDIR}"/.largefiles
	if [[ -s "${TMPDIR}"/.largefiles ]]; then
		printf '#!/bin/bash\n\n' > join_split_files.sh
		while read -r l; do
			split -b 47M "${l}" "${l}".
			rm -f "${l}" 2>/dev/null
			printf "cat %s.* 2>/dev/null >> %s\n" "${l}" "${l}" >> join_split_files.sh
			printf "rm -f %s.* 2>/dev/null\n" "${l}" >> join_split_files.sh
		done < "${TMPDIR}"/.largefiles
		chmod a+x join_split_files.sh 2>/dev/null
	fi
	rm -rf "${TMPDIR}" 2>/dev/null
	printf "Starting Git Init...\n"
	git init		# Insure Your Github Authorization Before Running This Script
	git config --global http.postBuffer 524288000		# A Simple Tuning to Get Rid of curl (18) error while `git push`
	git checkout -b "${branch}"
	find . \( -name "*sensetime*" -o -name "*.lic" \) | cut -d'/' -f'2-' >| .gitignore
	[[ ! -s .gitignore ]] && rm .gitignore
	git add --all
	if [[ "${GIT_ORG}" == "${GIT_USER}" ]]; then
		curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{"name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/user/repos" >/dev/null 2>&1
	else
		curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{ "name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/orgs/${GIT_ORG}/repos" >/dev/null 2>&1
	fi
	curl -s -X PUT -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.mercy-preview+json" -d '{ "names": ["'"${manufacturer}"'","'"${platform}"'","'"${top_codename}"'"]}' "https://api.github.com/repos/${GIT_ORG}/${repo}/topics" 	# Update Repository Topics
	git remote add origin https://github.com/${GIT_ORG}/${repo}.git
	git commit -asm "Add ${description}"
	git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}" || (
		git update-ref -d HEAD
		git reset system/ vendor/
		git checkout -b "${branch}"
		git commit -asm "Add extras for ${description}"
		git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}"
		git add vendor/
		git commit -asm "Add vendor for ${description}"
		git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}"
		git add system/system/app/ system/system/priv-app/ || git add system/app/ system/priv-app/
		git commit -asm "Add apps for ${description}"
		git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}"
		git add system/
		git commit -asm "Add system for ${description}"
		git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}"
	)
	# Telegram channel post
	if [[ -s "${PROJECT_DIR}"/.tg_token ]]; then
		TG_TOKEN=$(< "${PROJECT_DIR}"/.tg_token)
		if [[ -s "${PROJECT_DIR}"/.tg_chat ]]; then		# TG Channel ID
			CHAT_ID=$(< "${PROJECT_DIR}"/.tg_chat)
		else
			CHAT_ID="@phoenix_droid_dumps"
		fi
		commit_head=$(git log --format=format:%H | head -n 1)
		commit_link="https://github.com/${GIT_ORG}/${repo}/commit/${commit_head}"
		printf "Sending telegram notification...\n"
		printf "<b>Brand: %s</b>" "${brand}" >| "${OUTDIR}"/tg.html
		{
			printf "\n<b>Device: %s</b>" "${codename}"
			printf "\n<b>Version:</b> %s" "${release}"
			printf "\n<b>Fingerprint:</b> %s" "${fingerprint}"
			printf "\n<b>GitHub Link:</b>"
			printf "\n<a href=\"%s\">Commit</a>" "${commit_link}"
			printf "\n<a href=\"https://github.com/%s/%s/tree/%s/\">%s</a>" "${GIT_ORG}" "${repo}" "${branch}" "${codename}"
		} >> "${OUTDIR}"/tg.html
		TEXT=$(< "${OUTDIR}"/tg.html)
		rm -rf "${OUTDIR}"/tg.html
		curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" >/dev/null
	fi
	exit 0
else
	printf "Dumping done locally.\n"
	exit
fi

