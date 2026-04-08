#!/bin/bash

# Clear Screen
tput reset 2>/dev/null || clear

# Unset Every Variables That We Are Gonna Use Later
unset PROJECT_DIR INPUTDIR UTILSDIR OUTDIR TMPDIR FILEPATH FILE EXTENSION UNZIP_DIR ArcPath \
	GITHUB_TOKEN GIT_ORG TG_TOKEN CHAT_ID

# Resize Terminal Window To Atleast 30x90 For Better View
printf "\033[8;30;90t" || true

# Banner
function __bannerTop() {
	local GREEN='\033[0;32m'
	local NC='\033[0m'
	echo -e \
	${GREEN}"
	██████╗░██╗░░░██╗███╗░░░███╗██████╗░██████╗░██╗░░██╗
	██╔══██╗██║░░░██║████╗░████║██╔══██╗██╔══██╗╚██╗██╔╝
	██║░░██║██║░░░██║██╔████╔██║██████╔╝██████╔╝░╚███╔╝░
	██║░░██║██║░░░██║██║╚██╔╝██║██╔═══╝░██╔══██╗░██╔██╗░
	██████╔╝╚██████╔╝██║░╚═╝░██║██║░░░░░██║░░██║██╔╝╚██╗
	╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝
	"${NC}
}

# Usage/Help
function _usage() {
	printf "  \e[1;32;40m \u2730 Usage: \$ %s <Firmware File/Extracted Folder -OR- Supported Website Link> \e[0m\n" "${0}"
	printf "\t\e[1;32m -> Firmware File: The .zip/.rar/.7z/.tar/.bin/.ozip/.kdz etc. file \e[0m\n\n"
	sleep .5s
	printf " \e[1;34m >> Supported Websites: \e[0m\n"
	printf "\e[36m\t1. Directly Accessible Download Link From Any Website\n"
	printf "\t2. Filehosters like - mega.nz | mediafire | gdrive | onedrive | androidfilehost\e[0m\n"
	printf "\t\e[33m >> Must Wrap Website Link Inside Single-quotes ('')\e[0m\n"
	sleep .2s
	printf " \e[1;34m >> Supported File Formats For Direct Operation:\e[0m\n"
	printf "\t\e[36m *.zip | *.rar | *.7z | *.tar | *.tar.gz | *.tgz | *.tar.md5\n"
	printf "\t *.ozip | *.ofp | *.ops | *.kdz | ruu_*exe\n"
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

EXTERNAL_TOOLS=(
	bkerler/oppo_ozip_decrypt
	bkerler/oppo_decrypt
	ShivamKumarJha/android_tools
	HemanthJabalpuri/pacextractor
)

for tool_slug in "${EXTERNAL_TOOLS[@]}"; do
	if ! [[ -d "${UTILSDIR}"/"${tool_slug#*/}" ]]; then
		git clone -q https://github.com/"${tool_slug}".git "${UTILSDIR}"/"${tool_slug#*/}"
	else
		git -C "${UTILSDIR}"/"${tool_slug#*/}" pull
	fi
done

# Retrive 'extract-ikconfig' from torvalds/linux
if ! [[ -f "${UTILSDIR}"/extract-ikconfig ]]; then
    curl -s -Lo "${UTILSDIR}"/extract-ikconfig https://raw.githubusercontent.com/torvalds/linux/refs/heads/master/scripts/extract-ikconfig
    chmod +x "${UTILSDIR}"/extract-ikconfig
fi

## See README.md File For Program Credits
# Set Utility Program Alias
SDAT2IMG="${UTILSDIR}"/sdat2img.py
SIMG2IMG="${UTILSDIR}"/bin/simg2img
PACKSPARSEIMG="${UTILSDIR}"/bin/packsparseimg
UNSIN="${UTILSDIR}"/unsin
PAYLOAD_EXTRACTOR="${UTILSDIR}"/bin/payload-dumper-go
OZIPDECRYPT="${UTILSDIR}"/oppo_ozip_decrypt/ozipdecrypt.py
OFP_QC_DECRYPT="${UTILSDIR}"/oppo_decrypt/ofp_qc_decrypt.py
OFP_MTK_DECRYPT="${UTILSDIR}"/oppo_decrypt/ofp_mtk_decrypt.py
OPSDECRYPT="${UTILSDIR}"/oppo_decrypt/opscrypto.py
LPUNPACK="${UTILSDIR}"/lpunpack
SPLITUAPP="${UTILSDIR}"/splituapp.py
PACEXTRACTOR="${UTILSDIR}"/pacextractor/python/pacExtractor.py
NB0_EXTRACT="${UTILSDIR}"/nb0-extract
KDZ_EXTRACT="${UTILSDIR}"/kdztools/unkdz.py
DZ_EXTRACT="${UTILSDIR}"/kdztools/undz.py
RUUDECRYPT="${UTILSDIR}"/RUU_Decrypt_Tool
EXTRACT_IKCONFIG="${UTILSDIR}"/extract-ikconfig
MAGISKBOOT="${UTILSDIR}"/bin/magiskboot
AML_EXTRACT="${UTILSDIR}"/aml-upgrade-package-extract
AFPTOOL_EXTRACT="${UTILSDIR}"/bin/afptool
RK_EXTRACT="${UTILSDIR}"/bin/rkImageMaker
TRANSFER="${UTILSDIR}"/bin/transfer

if ! command -v 7zz > /dev/null 2>&1; then
	BIN_7ZZ="${UTILSDIR}"/bin/7zz
else
	BIN_7ZZ=7zz
fi

if ! command -v uvx > /dev/null 2>&1; then
	export PATH="${HOME}/.local/bin:${PATH}"
fi

# Set Names of Downloader Utility Programs
MEGAMEDIADRIVE_DL="${UTILSDIR}"/downloaders/mega-media-drive_dl.sh

# EROFS
FSCK_EROFS=${UTILSDIR}/bin/fsck.erofs

# Partition List That Are Currently Supported
PARTITIONS="system system_ext system_other systemex vendor cust odm oem factory product xrom modem dtbo dtb boot vendor_boot recovery tz oppo_product preload_common opproduct reserve india my_preload my_odm my_stock my_operator my_country my_product my_company my_engineering my_heytap my_custom my_manifest my_carrier my_region my_bigball my_version special_preload system_dlkm vendor_dlkm odm_dlkm init_boot vendor_kernel_boot odmko socko nt_log mi_ext hw_product product_h preas preavs"
EXT4PARTITIONS="system vendor cust odm oem factory product xrom systemex oppo_product preload_common hw_product product_h preas preavs"
OTHERPARTITIONS="tz.mbn:tz tz.img:tz modem.img:modem NON-HLOS:modem boot-verified.img:boot recovery-verified.img:recovery dtbo-verified.img:dtbo"

# NOTE: $(pwd) is ${PROJECT_DIR}
if echo "${1}" | grep -q "${PROJECT_DIR}/input" && [[ $(find "${INPUTDIR}" -maxdepth 1 -type f -size +10M -print | wc -l) -gt 1 ]]; then
	FILEPATH=$(printf "%s\n" "$1")		# Relative Path To Script
	FILEPATH=$(realpath "${FILEPATH}")	# Absolute Path
	printf "Copying Everything Into %s For Further Operations." "${TMPDIR}"
	cp -a "${FILEPATH}"/* "${TMPDIR}"/
	unset FILEPATH
elif echo "${1}" | grep -q "${PROJECT_DIR}/input/" && [[ $(find "${INPUTDIR}" -maxdepth 1 -type f -size +300M -print | wc -l) -eq 1 ]]; then
	printf "Input Directory Exists And Contains File\n"
	cd "${INPUTDIR}"/ || exit
	# Input File Variables
	FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f -size +300M 2>/dev/null)	# INPUTDIR's FILEPATH is Always File
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
		if echo "${URL}" | grep -q "mega.nz\|mediafire.com\|drive.google.com"; then
			( "${MEGAMEDIADRIVE_DL}" "${URL}" ) || exit 1
		elif echo "${URL}" | grep -q "androidfilehost.com"; then
			( uvx -q afh-dl -l "${URL}" ) || exit 1
		elif echo "${URL}" | grep -q "/we.tl/"; then
			( "${TRANSFER}" "${URL}" ) || exit 1
		else
			if echo "${URL}" | grep -q "1drv.ms"; then URL=${URL/ms/ws}; fi
			aria2c -x16 -s8 --console-log-level=warn --summary-interval=0 --check-certificate=false "${URL}" || {
				wget -q --show-progress --progress=bar:force --no-check-certificate "${URL}" || exit 1
			}
		fi
		unset URL
		for f in *; do detox -r "${f}" 2>/dev/null; done		# Detox Filename
		# Input File Variables
		FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f 2>/dev/null)	# Single File
		printf "\nWorking with %s\n\n" "${FILEPATH##*/}"
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
		if find "${FILEPATH}" -maxdepth 1 -type f | grep -v "compatibility.zip" | grep -q ".*.tar$\|.*.zip\|.*.rar\|.*.7z"; then
			printf "Supplied Folder Has Compressed Archive That Needs To Re-Load\n"
			# Set From Download Directory
			ArcPath=$(find "${INPUTDIR}"/ -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print | grep -v "compatibility.zip")
			# If Empty, Set From Original Local Folder
			[[ -z "${ArcPath}" ]] && ArcPath=$(find "${FILEPATH}"/ -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print | grep -v "compatibility.zip")
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

# Function for Extracting Super Images
function superimage_extract() {
    if [ -f super.img ]; then
        echo "Extracting Partitions from the Super Image..."
        ${SIMG2IMG} super.img super.img.raw 2>/dev/null
    fi
    if [[ ! -s super.img.raw ]] && [ -f super.img ]; then
        mv super.img super.img.raw
    fi
    for partition in $PARTITIONS; do
        ($LPUNPACK --partition="$partition"_a super.img.raw || $LPUNPACK --partition="$partition" super.img.raw) 2>/dev/null
        if [ -f "$partition"_a.img ]; then
            mv "$partition"_a.img "$partition".img
        else
            foundpartitions=$(${BIN_7ZZ} l -ba "${FILEPATH}" | rev | gawk '{ print $1 }' | rev | grep $partition.img)
            ${BIN_7ZZ} e -y "${FILEPATH}" $foundpartitions dummypartition 2>/dev/null >> $TMPDIR/zip.log
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
	uv run --with-requirements "${UTILSDIR}/oppo_decrypt/requirements.txt" "${OZIPDECRYPT}" "${TMPDIR}"/"${FILE}"
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
	if [[ -f "${FILE%.*}".zip ]]; then
		mv "${FILE%.*}".zip "${INPUTDIR}"/
	elif [[ -d "${TMPDIR}"/out ]]; then
		mv "${TMPDIR}"/out/* "${INPUTDIR}"/
	fi
	rm -rf "${TMPDIR:?}"/*
	printf "Re-Loading The Decrypted Content.\n"
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/" 2>/dev/null || bash "${0}" "${INPUTDIR}"/"${FILE%.*}".zip ) || exit 1
	exit
fi
# Oneplus .ops Check
if ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q ".*.ops" 2>/dev/null; then
	printf "Oppo/Oneplus ops Firmware Detected Extracting...\n"
	foundops=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep ".*.ops")
	${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundops}" */"${foundops}" 2>/dev/null >> "${TMPDIR}"/zip.log
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
	mv "$(echo "${foundops}" | gawk -F['/'] '{print $NF}')" "${INPUTDIR}"/
	sleep 1s
	printf "Reloading the extracted OPS\n"
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/${foundops}" 2>/dev/null) || exit 1
	exit
fi
if [[ "${EXTENSION}" == "ops" ]]; then
	printf "Oppo/Oneplus ops Detected.\n"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/"${FILE}" 2>/dev/null || cp -a "${FILEPATH}" "${TMPDIR}"/"${FILE}"
	printf "Decrypting ops & extracing...\n"
	uv run --with-requirements "${UTILSDIR}/oppo_decrypt/requirements.txt" "${OPSDECRYPT}" decrypt "${TMPDIR}"/"${FILE}"
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
	mv "${TMPDIR}"/extract/* "${INPUTDIR}"/
	rm -rf "${TMPDIR:?}"/*
	printf "Re-Loading The Decrypted Content.\n"
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/" 2>/dev/null || bash "${0}" "${INPUTDIR}"/"${FILE%.*}".zip ) || exit 1
	exit
fi
# Oppo .ofp Check
if ${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep -q ".*.ofp" 2>/dev/null; then
	printf "Oppo ofp Detected.\n"
	foundofp=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep ".*.ofp")
	${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundofp}" */"${foundofp}" 2>/dev/null >> "${TMPDIR}"/zip.log
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
	mv "$(echo "${foundofp}" | gawk -F['/'] '{print $NF}')" "${INPUTDIR}"/
	sleep 1s
	printf "Reloading the extracted OFP\n"
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/${foundofp}" 2>/dev/null) || exit 1
	exit
fi
if [[ "${EXTENSION}" == "ofp" ]]; then
	printf "Oppo ofp Detected.\n"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/"${FILE}" 2>/dev/null || cp -a "${FILEPATH}" "${TMPDIR}"/"${FILE}"
	printf "Decrypting ofp & extracing...\n"
	uv run --with-requirements "${UTILSDIR}/oppo_decrypt/requirements.txt" "$OFP_QC_DECRYPT" "${TMPDIR}"/"${FILE}" out
	if [[ ! -f "${TMPDIR}"/out/boot.img || ! -f "${TMPDIR}"/out/userdata.img ]]; then
		uv run --with-requirements "${UTILSDIR}/oppo_decrypt/requirements.txt" "$OFP_MTK_DECRYPT" "${TMPDIR}"/"${FILE}" out
		if [[ ! -f "${TMPDIR}"/out/boot.img || ! -f "${TMPDIR}"/out/userdata.img ]]; then
			printf "ofp decryption error.\n" && exit 1
		fi
	fi
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
	if [[ -d "${TMPDIR}"/out ]]; then
		mv "${TMPDIR}"/out/* "${INPUTDIR}"/
	fi
	rm -rf "${TMPDIR:?}"/*
	printf "Re-Loading The Decrypted Contents.\n"
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/" ) || exit 1
	exit
fi
# Xiaomi .tgz Check
if [[ "${FILE##*.}" == "tgz" || "${FILE#*.}" == "tar.gz" ]]; then
	printf "Xiaomi gzipped tar archive found.\n"
	mkdir -p "${INPUTDIR}" 2>/dev/null
	if [[ -f "${INPUTDIR}"/"${FILE}" ]]; then
		tar xzvf "${INPUTDIR}"/"${FILE}" -C "${INPUTDIR}"/ --transform='s/.*\///'
		rm -rf -- "${INPUTDIR:?}"/"${FILE}"
	elif [[ -f "${FILEPATH}" ]]; then
		tar xzvf "${FILEPATH}" -C "${INPUTDIR}"/ --transform='s/.*\///'
	fi
	find "${INPUTDIR}"/ -type d -empty -delete     # Delete Empth Folder Leftover
	rm -rf "${TMPDIR:?}"/*
	printf "Re-Loading The Extracted Contents.\n"
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/" ) || exit 1
	exit
fi
# LG KDZ Check
if echo "${FILEPATH}" | grep -q ".*.kdz" || [[ "${EXTENSION}" == "kdz" ]]; then
	printf "LG KDZ Detected.\n"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/ 2>/dev/null || cp -a "${FILEPATH}" "${TMPDIR}"/
	uv run -q --with zstandard "${KDZ_EXTRACT}" -f "${FILE}" -x -o "./" 2>/dev/null
	DZFILE=$(ls -- *.dz)
	printf "Extracting All Partitions As Individual Images.\n"
	uv run -q --with zstandard "${DZ_EXTRACT}" -f "${DZFILE}" -s -o "./" 2>/dev/null
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
	printf "Extracting System And Firmware Partitions...\n"
	"${RUUDECRYPT}" -s "${FILE}" 2>/dev/null
	"${RUUDECRYPT}" -f "${FILE}" 2>/dev/null
	find "${TMPDIR}"/OUT* -name "*.img" -exec mv {} "${TMPDIR}"/ \;
fi

# Amlogic upgrade package (AML) Check
if [[ $(${BIN_7ZZ} l -ba "${FILEPATH}" | grep -i aml) ]]; then
	echo "AML Detected"
	cp "${FILEPATH}" ${TMPDIR}
	FILE="${TMPDIR}/$(basename ${FILEPATH})"
	${BIN_7ZZ} e -y "${FILEPATH}" >> ${TMPDIR}/zip.log
	"${AML_EXTRACT}" $(find . -type f -name "*aml*.img")
	rename 's/.PARTITION$/.img/' *.PARTITION
	rename 's/_aml_dtb.img$/dtb.img/' *.img
	rename 's/_a.img/.img/' *.img
	if [[ -f super.img ]]; then
		superimage_extract || exit 1
	fi
	for partition in $PARTITIONS; do
		[[ -e "${TMPDIR}/${partition}.img" ]] && mv "${TMPDIR}/${partition}.img" "${OUTDIR}/${partition}.img"
	done
	rm -rf ${TMPDIR}
fi

# Extract & Move Raw Otherpartitons To OUTDIR
if [[ -f "${FILEPATH}" ]]; then
	for otherpartition in ${OTHERPARTITIONS}; do
		filename=${otherpartition%:*} && outname=${otherpartition#*:}
		if ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "${filename}"; then
			printf "%s Detected For %s\n" "${filename}" "${outname}"
			foundfile=$(${BIN_7ZZ} l -ba "${FILEPATH}" | grep "${filename}" | awk '{print $NF}')
			${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundfile}" */"${foundfile}" 2>/dev/null >> "${TMPDIR}"/zip.log
			output=$(ls -- "${filename}"* 2>/dev/null)
			[[ ! -e "${TMPDIR}"/"${outname}".img ]] && mv "${output}" "${TMPDIR}"/"${outname}".img
			"${SIMG2IMG}" "${TMPDIR}"/"${outname}".img "${OUTDIR}"/"${outname}".img 2>/dev/null
			[[ ! -s "${OUTDIR}"/"${outname}".img && -f "${TMPDIR}"/"${outname}".img ]] && mv "${outname}".img "${OUTDIR}"/"${outname}".img
		fi
	done
fi

# Extract/Put Image/Extra Files In TMPDIR
if ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system.new.dat" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system.new.dat*" -print | wc -l) -ge 1 ]]; then
	printf "A-only DAT-Formatted OTA detected.\n"
	for partition in $PARTITIONS; do
		${BIN_7ZZ} e -y "${FILEPATH}" ${partition}.new.dat* ${partition}.transfer.list ${partition}.img 2>/dev/null >> ${TMPDIR}/zip.log
		${BIN_7ZZ} e -y "${FILEPATH}" ${partition}.*.new.dat* ${partition}.*.transfer.list ${partition}.*.img 2>/dev/null >> ${TMPDIR}/zip.log
		rename 's/(\w+)\.(\d+)\.(\w+)/$1.$3/' *
		# For Oplus A-only OTAs, eg OnePlus Nord 2. Regex matches the 8 digits of Oplus NV ID (prop ro.build.oplus_nv_id) to remove them.
		# hello@world:~/test_regex# rename -n 's/(\w+)\.(\d+)\.(\w+)/$1.$3/' *
		# rename(my_bigball.00011011.new.dat.br, my_bigball.new.dat.br)
		# rename(my_bigball.00011011.patch.dat, my_bigball.patch.dat)
		# rename(my_bigball.00011011.transfer.list, my_bigball.transfer.list)
		if [[ -f ${partition}.new.dat.1 ]]; then
			cat ${partition}.new.dat.{0..999} 2>/dev/null >> ${partition}.new.dat
			rm -rf ${partition}.new.dat.{0..999}
		fi
		ls | grep "\.new\.dat" | while read i; do
			line=$(echo "$i" | cut -d"." -f1)
			if [[ $(echo "$i" | grep "\.dat\.xz") ]]; then
				${BIN_7ZZ} e -y "$i" 2>/dev/null >> ${TMPDIR}/zip.log
				rm -rf "$i"
			fi
			if [[ $(echo "$i" | grep "\.dat\.br") ]]; then
				echo "Converting brotli ${partition} dat to normal"
				brotli -d "$i"
				rm -f "$i"
			fi
			echo "Extracting ${partition}"
			uv run -q ${SDAT2IMG} ${line}.transfer.list ${line}.new.dat "${OUTDIR}"/${line}.img > ${TMPDIR}/extract.log
			rm -rf ${line}.transfer.list ${line}.new.dat
		done
	done
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep rawprogram || [[ $(find "${TMPDIR}" -type f -name "*rawprogram*" | wc -l) -ge 1 ]]; then
	echo "QFIL Detected"
	rawprograms=$(${BIN_7ZZ} l -ba ${FILEPATH} | gawk '{ print $NF }' | grep rawprogram)
	${BIN_7ZZ} e -y ${FILEPATH} $rawprograms 2>/dev/null >> ${TMPDIR}/zip.log
	for partition in $PARTITIONS; do
		partitionsonzip=$(${BIN_7ZZ} l -ba ${FILEPATH} | gawk '{ print $NF }' | grep $partition)
		if [[ ! $partitionsonzip == "" ]]; then
			${BIN_7ZZ} e -y ${FILEPATH} $partitionsonzip 2>/dev/null >> ${TMPDIR}/zip.log
			if [[ ! -f "$partition.img" ]]; then
				if [[ -f "$partition.raw.img" ]]; then
					mv "$partition.raw.img" "$partition.img"
				else
					rawprogramsfile=$(grep -rlw $partition rawprogram*.xml)
					"${PACKSPARSEIMG}" -t $partition -x $rawprogramsfile > ${TMPDIR}/extract.log
					mv "$partition.raw" "$partition.img"
				fi
			fi
		fi
	done
	if [[ -f super.img ]]; then
		superimage_extract || exit 1
	fi
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q ".*.nb0" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "*.nb0*" | wc -l) -ge 1 ]]; then
	printf "nb0-Formatted Firmware Detected.\n"
	if [[ -f "${FILEPATH}" ]]; then
		to_extract=$(${BIN_7ZZ} l -ba "${FILEPATH}" | grep ".*.nb0" | gawk '{print $NF}')
		${BIN_7ZZ} e -y -- "${FILEPATH}" "${to_extract}" 2>/dev/null >> "${TMPDIR}"/zip.log
	else
		find "${TMPDIR}" -type f -name "*.nb0*" -exec mv {} . \; 2>/dev/null
	fi
	"${NB0_EXTRACT}" "${to_extract}" "${TMPDIR}"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep system | grep chunk | grep -q -v ".*\.so$" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "*system*chunk*" | wc -l) -ge 1 ]]; then
	printf "Chunk Detected.\n"
	for partition in ${PARTITIONS}; do
		if [[ -f "${FILEPATH}" ]]; then
			foundpartitions=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "${partition}".img)
			${BIN_7ZZ} e -y -- "${FILEPATH}" *"${partition}"*chunk* */*"${partition}"*chunk* "${foundpartitions}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
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
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep -q "system_new.img\|^system.img\|\/system.img\|\/system_image.emmc.img\|^system_image.emmc.img" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system*.img" | wc -l) -ge 1 ]]; then
	printf "Image File detected.\n"
	if [[ -f "${FILEPATH}" ]]; then
		${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
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
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system.sin\|.*system_.*\.sin" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system*.sin" | wc -l) -ge 1 ]]; then
	printf "sin Image Detected.\n"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	# Remove Unnecessary Filename Part
	to_remove=$(find . -type f | grep ".*boot_.*\.sin" | gawk '{print $NF}' | sed -e 's/boot_\(.*\).sin/\1/')
	[[ -z "$to_remove" ]] && to_remove=$(find . -type f | grep ".*cache_.*\.sin" | gawk '{print $NF}' | sed -e 's/cache_\(.*\).sin/\1/')
	[[ -z "$to_remove" ]] && to_remove=$(find . -type f | grep ".*vendor_.*\.sin" | gawk '{print $NF}' | sed -e 's/vendor_\(.*\).sin/\1/')
	find "${TMPDIR}" -mindepth 2 -type f -name "*.sin" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	find "${TMPDIR}" -maxdepth 1 -type f -name "*_${to_remove}.sin" | while read -r i; do mv "${i}" "${i/_${to_remove}.sin/.sin}" 2>/dev/null; done	# proper names
	"${UNSIN}" -d "${TMPDIR}"
	find "${TMPDIR}" -maxdepth 1 -type f -name "*.ext4" | while read -r i; do mv "${i}" "${i/.ext4/.img}" 2>/dev/null; done	# proper names
	foundsuperinsin=$(find "${TMPDIR}" -maxdepth 1 -type f -name "super_*.img")
	if [ ! -z $foundsuperinsin ]; then
		mv $(ls ${TMPDIR}/super_*.img) "${TMPDIR}/super.img"
		echo "super image inside a sin detected"
		superimage_extract || exit 1
	fi
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep ".pac$" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "*.pac" | wc -l) -ge 1 ]]; then
	printf "pac Detected.\n"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	for f in "${TMPDIR}"/*; do detox -r "${f}"; done
	pac_list=$(find . -type f -name "*.pac" | cut -d'/' -f'2-' | sort)
	for file in ${pac_list}; do
		uv run -q --with crcmod "${PACEXTRACTOR}" "${file}" $(pwd)
	done
	if [[ -f super.img ]]; then
		superimage_extract || exit 1
	fi
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system.bin" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system.bin" | wc -l) -ge 1 ]]; then
	printf "bin Images Detected\n"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	find "${TMPDIR}" -mindepth 2 -type f -name "*.bin" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	find "${TMPDIR}" -maxdepth 1 -type f -name "*.bin" | while read -r i; do mv "${i}" "${i/\.bin/.img}" 2>/dev/null; done	# proper names
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system-p" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system-p*" | wc -l) -ge 1 ]]; then
	printf "P-Suffix Images Detected\n"
	for partition in ${PARTITIONS}; do
		if [[ -f "${FILEPATH}" ]]; then
			foundpartitions=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "${partition}-p")
			${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundpartitions}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
		else
			foundpartitions=$(find . -type f -name "*${partition}-p*" | cut -d'/' -f'2-')
		fi
	[[ -n "${foundpartitions}" ]] && mv "$(ls "${partition}"-p*)" "${partition}".img
	done
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system-sign.img" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system-sign.img" | wc -l) -ge 1 ]]; then
	printf "Signed Images Detected\n"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
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
elif [[ $(${BIN_7ZZ} l -ba "$FILEPATH" | grep "super.img") ]]; then
	echo "Super Image detected"
	foundsupers=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{ print $NF }' | grep "super.img")
	${BIN_7ZZ} e -y "${FILEPATH}" $foundsupers dummypartition 2>/dev/null >> ${TMPDIR}/zip.log
	superchunk=$(ls | grep chunk | grep super | sort)
	if [[ $(echo "$superchunk" | grep "sparsechunk") ]]; then
		"${SIMG2IMG}" $(echo "$superchunk" | tr '\n' ' ') super.img.raw 2>/dev/null
		rm -rf *super*chunk*
	fi
	superimage_extract || exit 1
elif [[ $(find "${TMPDIR}" -type f -name "super*.*img" | wc -l) -ge 1 ]]; then
	echo "Super Image Detected"
	if [[ -f "${FILEPATH}" ]]; then
		foundsupers=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "super.*img")
		${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundsupers}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
	fi
	splitsupers=$(ls | grep -oP "super.[0-9].+.img")
	if [[ ! -z "${splitsupers}" ]]; then
		printf "Creating super.img.raw ...\n"
		"${SIMG2IMG}" ${splitsupers} super.img.raw 2>/dev/null
		rm -rf -- ${splitsupers}
	fi
	superchunk=$(find . -maxdepth 1 -type f -name "*super*chunk*" | cut -d'/' -f'2-' | sort)
	if echo "${superchunk}" | grep -q "sparsechunk"; then
		printf "Creating super.img.raw ...\n"
		"${SIMG2IMG}" ${superchunk} super.img.raw 2>/dev/null
		rm -rf -- *super*chunk*
	fi
	superimage_extract || exit 1
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep tar.md5 | gawk '{print $NF}' | grep -q AP_ 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "*AP_*tar.md5" | wc -l) -ge 1 ]]; then
	printf "AP tarmd5 Detected\n"
	#mv -f "${FILEPATH}" "${TMPDIR}"/
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} e -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	printf "Extracting Images...\n"
	for i in $(ls *.tar.md5); do
		tar -xf "${i}" || exit 1
		rm -fv "${i}" || exit 1
		printf "Extracted %s\n" "${i}"
	done
	[[ $(ls *.lz4 2>/dev/null) ]] && {
		printf "Extracting lz4 Archives...\n"
		for f in $(ls *.lz4); do
			lz4 -dc ${f} > "${f/.lz4/}" || exit 1
			rm -fv ${f} || exit 1
			printf "Extracted %s\n" "${f}"
		done
	}
	for samsung_ext4_img_files in $(find -maxdepth 1 -type f -name \*.ext4 -printf '%P\n'); do
		mv -v $samsung_ext4_img_files "${samsung_ext4_img_files%%.ext4}"
	done
	if [[ -f super.img ]]; then
		superimage_extract || exit 1	
	fi
	if [[ ! -f system.img ]]; then
		printf "Extract failed\n"
		rm -rf "${TMPDIR}" && exit 1
	fi
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q payload.bin 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "payload.bin" | wc -l) -ge 1 ]]; then
	printf "AB OTA Payload Detected\n"
	${PAYLOAD_EXTRACTOR} -c "$(nproc --all)" -o "${TMPDIR}" "${FILEPATH}" >/dev/null
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep ".*.rar\|.*.zip\|.*.7z\|.*.tar$" 2>/dev/null || [[ $(find "${TMPDIR}" -type f \( -name "*.rar" -o -name "*.zip" -o -name "*.7z" -o -name "*.tar" \) | wc -l) -ge 1 ]]; then
	printf "Rar/Zip/7Zip/Tar Archived Firmware Detected\n"
	if [[ -f "${FILEPATH}" ]]; then
		mkdir -p "${TMPDIR}"/"${UNZIP_DIR}" 2>/dev/null
		${BIN_7ZZ} e -y "${FILEPATH}" -o"${TMPDIR}"/"${UNZIP_DIR}"  >> "${TMPDIR}"/zip.log
		for f in "${TMPDIR}"/"${UNZIP_DIR}"/*; do detox -r "${f}" 2>/dev/null; done
	fi
	zip_list=$(find ./"${UNZIP_DIR}" -type f -size +300M \( -name "*.rar" -o -name "*.zip" -o -name "*.7z" -o -name "*.tar" \) | cut -d'/' -f'2-' | sort)
	mkdir -p "${INPUTDIR}" 2>/dev/null
	rm -rf "${INPUTDIR:?}"/* 2>/dev/null
	for file in ${zip_list}; do
		mv "${TMPDIR}"/"${file}" "${INPUTDIR}"/
		rm -rf "${TMPDIR:?}"/*
		cd "${PROJECT_DIR}"/ || exit
		( bash "${0}" "${INPUTDIR}"/"${file}" ) || exit 1
		exit
	done
	rm -rf "${TMPDIR:?}"/"${UNZIP_DIR}"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "UPDATE.APP" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "UPDATE.APP") ]]; then
	printf "Huawei UPDATE.APP Detected\n"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x "${FILEPATH}" UPDATE.APP 2>/dev/null >> "${TMPDIR}"/zip.log
	find "${TMPDIR}" -type f -name "UPDATE.APP" -exec mv {} . \;
	uv run -q "${SPLITUAPP}" -f "UPDATE.APP" -l super preas preavs || (
	for partition in ${PARTITIONS}; do
		uv run -q "${SPLITUAPP}" -f "UPDATE.APP" -l "${partition/.img/}" || printf "%s not found in UPDATE.APP\n" "${partition}"
	done )
	find output/ -type f -name "*.img" -exec mv {} . \;	# Partitions Are Extracted In "output" Folder
	if [[ -f super.img ]]; then
		printf "Creating super.img.raw ...\n"
		"${SIMG2IMG}" super.img super_* super.img.raw 2>/dev/null
		[[ ! -s super.img.raw && -f super.img ]] && mv super.img super.img.raw
	fi
	superimage_extract || exit 1
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "rockchip" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "rockchip") ]]; then
	printf "Rockchip Detected\n"
	${RK_EXTRACT} -unpack "${FILEPATH}" ${TMPDIR}
	${AFPTOOL_EXTRACT} -unpack ${TMPDIR}/firmware.img ${TMPDIR}
	[ -f ${TMPDIR}/Image/super.img ] && {
		mv ${TMPDIR}/Image/super.img ${TMPDIR}/super.img
		cd ${TMPDIR}
		superimage_extract || exit 1
		cd -
	}
	for partition in $PARTITIONS; do
		[[ -e "${TMPDIR}/Image/${partition}.img" ]] && mv "${TMPDIR}/Image/${partition}.img" "${OUTDIR}/${partition}.img"
		[[ -e "${TMPDIR}/${partition}.img" ]] && mv "${TMPDIR}/${partition}.img" "${OUTDIR}/${partition}.img"
	done
fi

# PAC Archive Check
if [[ "${EXTENSION}" == "pac" ]]; then
	printf "PAC Archive Detected.\n"
	uv run -q --with crcmod ${PACEXTRACTOR} ${FILEPATH} $(pwd)
	superimage_extract || exit 1
	exit
fi

# $(pwd) == "${TMPDIR}"

# Process All otherpartitions From TMPDIR Now
for otherpartition in ${OTHERPARTITIONS}; do
	filename=${otherpartition%:*} && outname=${otherpartition#*:}
	output=$(ls -- "${filename}"* 2>/dev/null)
	if [[ -f "${output}" ]]; then
		printf "%s Detected For %s\n" "${output}" "${outname}"
		[[ ! -e "${TMPDIR}"/"${outname}".img ]] && mv "${output}" "${TMPDIR}"/"${outname}".img
		"${SIMG2IMG}" "${TMPDIR}"/"${outname}".img "${OUTDIR}"/"${outname}".img 2>/dev/null
		[[ ! -s "${OUTDIR}"/"${outname}".img && -f "${TMPDIR}"/"${outname}".img ]] && mv "${outname}".img "${OUTDIR}"/"${outname}".img
	fi
done

# Process All partitions From TMPDIR Now
for partition in ${PARTITIONS}; do
	if [[ ! -f "${partition}".img ]]; then
		foundpart=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "${partition}.img" 2>/dev/null)
		${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundpart}" */"${foundpart}" 2>/dev/null >> "${TMPDIR}"/zip.log
	fi
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

get_bootimg_info() {
    local bootimg="$1"
    local tempdir="$2"

    # Detect and skip MTK/vendor header
    local offset
    offset=$(grep -abo "ANDROID!\|VNDRBOOT" "$bootimg" | cut -f1 -d:)
    [[ -z "$offset" ]] && { echo "ERROR: No Android/VndrBoot magic found"; return 1; }

    local VNDRBOOT=false
    grep -qabo "VNDRBOOT" "$bootimg" && VNDRBOOT=true

    local header_addr=40
    $VNDRBOOT && header_addr=8

    # Read header version
    local version
    version=$(od -A n -D -j "$header_addr" -N 1 "$bootimg" | sed 's/ //g')

    # Read sizes
    local kernel_size ramdisk_size second_size dtb_size dtbo_size page_size
    kernel_size=$(od -A n -D -j 8  -N 4 "$bootimg" | sed 's/ //g')
    ramdisk_size=$(od -A n -D -j 16 -N 4 "$bootimg" | sed 's/ //g')
    second_size=$(od -A n -D -j 24 -N 4 "$bootimg" | sed 's/ //g')
    page_size=$(od -A n -D -j 36 -N 4 "$bootimg" | sed 's/ //g')
    dtb_size=$(od -A n -D -j 40 -N 4 "$bootimg" | sed 's/ //g')
    dtbo_size=$(od -A n -D -j 1632 -N 4 "$bootimg" | sed 's/ //g')

    # Read addresses
    local kernel_addr ramdisk_addr second_addr tags_addr dtb_addr dtbo_addr
    kernel_addr=0x$(od -A n -X -j 12 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')
    ramdisk_addr=0x$(od -A n -X -j 20 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')
    second_addr=0x$(od -A n -X -j 28 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')
    tags_addr=0x$(od -A n -X -j 32 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')
    [[ $dtbo_size -gt 0 ]] && \
        dtbo_addr=0x$(od -A n -X -j 1636 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')

    # Read board and cmdline
    local board cmd_line os_version patch_level
    board=$(od -A n -S1 -j 48 -N 16 "$bootimg")
    cmd_line=$(od -A n -S1 -j 64 -N 512 "$bootimg")

    # Version-specific overrides
    if [[ $version -eq 2 ]]; then
        dtb_size=$(od -A n -D -j 1648 -N 4 "$bootimg" | sed 's/ //g')
        dtb_addr=0x$(od -A n -X -j 1652 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')

    elif [[ $version -eq 3 ]]; then
        page_size=4096
        board=; second_size=0; second_addr=; dtb_size=0; dtb_addr=

        if $VNDRBOOT; then
            kernel_addr=0x$(od -A n -X -j 16 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')
            ramdisk_addr=0x$(od -A n -X -j 20 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')
            ramdisk_size=$(od -A n -D -j 24 -N 4 "$bootimg" | sed 's/ //g')
            cmd_line=$(od -A n -S1 -j 28 -N 2048 "$bootimg")
            tags_addr=0x$(od -A n -X -j 2076 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')
            dtb_size=$(od -A n -D -j 2100 -N 4 "$bootimg" | sed 's/ //g')
            dtb_addr=0x$(od -A n -X -j 2104 -N 4 "$bootimg" | sed 's/ //g;s/^0*//')
        else
            kernel_addr=0x00008000
            kernel_size=$(od -A n -D -j 8  -N 4 "$bootimg" | sed 's/ //g')
            ramdisk_size=$(od -A n -D -j 12 -N 4 "$bootimg" | sed 's/ //g')
            cmd_line=$(od -A n -S1 -j 44 -N 1536 "$bootimg")
            local raw_os
            raw_os=$(od -A n -D -j 16 -N 4 "$bootimg" | sed 's/ //g')
            patch_level=$(( raw_os & ((1<<11)-1) ))
            raw_os=$(( raw_os >> 11 ))
            os_version=$(( raw_os>>14 )).$(( (raw_os>>7) & ((1<<7)-1) )).$(( raw_os & ((1<<7)-1) ))
            patch_level=$(( (patch_level>>4) + 2000 )):$(( patch_level & ((1<<4)-1) ))
            kernel_addr=; ramdisk_addr=; tags_addr=
        fi
    fi

    # Compute offsets from base
    local base_addr
    base_addr=$(( kernel_addr - 0x00008000 ))

    _fmt_offset() { printf "0x%08x" "$(( $1 - base_addr ))"; }

    local kernel_offset ramdisk_offset second_offset tags_offset dtb_offset dtbo_offset
    [[ -n "$kernel_addr"  ]] && kernel_offset=$(_fmt_offset  "$kernel_addr")
    [[ -n "$ramdisk_addr" ]] && ramdisk_offset=$(_fmt_offset "$ramdisk_addr")
    [[ -n "$second_addr"  ]] && second_offset=$(_fmt_offset  "$second_addr")
    [[ -n "$tags_addr"    ]] && tags_offset=$(_fmt_offset    "$tags_addr")
    [[ -n "$dtb_addr"     ]] && dtb_offset=$(_fmt_offset     "$dtb_addr")
    [[ -n "$dtbo_addr"    ]] && dtbo_offset=$(_fmt_offset    "$dtbo_addr")
    base_addr=$(printf "0x%08x" "$base_addr")

    # Suppress offsets based on version/type
    if [[ $version -gt 2 ]] && ! $VNDRBOOT; then
        tags_offset=; ramdisk_offset=
    fi
    $VNDRBOOT && kernel_addr= && dtbo_offset=

    # Write img_info
    {
        echo "kernel=kernel"
        echo "ramdisk=ramdisk"
        echo "page_size=$page_size"
        echo "kernel_size=$kernel_size"
        echo "ramdisk_size=$ramdisk_size"
        echo "base_addr=$base_addr"
        [[ -n "$kernel_offset"  ]] && echo "kernel_offset=$kernel_offset"
        [[ -n "$ramdisk_offset" ]] && echo "ramdisk_offset=$ramdisk_offset"
        [[ -n "$tags_offset"    ]] && echo "tags_offset=$tags_offset"
        [[ -n "$second_size"    ]] && [[ $second_size -gt 0 ]] && echo "second=second.img" && echo "second_size=$second_size" && echo "second_offset=$second_offset"
        [[ -n "$dtbo_size"      ]] && [[ $dtbo_size  -gt 0 ]] && echo "dtbo=dtbo.img"     && echo "dtbo_size=$dtbo_size"     && echo "dtbo_offset=$dtbo_offset"
        [[ -n "$dtb_size"       ]] && [[ $dtb_size   -gt 0 ]] && echo "dt=dtb.img"        && echo "dtb_size=$dtb_size"       && [[ $version -gt 1 ]] && echo "dtb_offset=$dtb_offset"
        [[ -n "$os_version"     ]] && echo "os_version=$os_version"
        [[ -n "$patch_level"    ]] && echo "os_patch_level=$patch_level"
        [[ -n "$board"          ]] && echo "board=\"$board\""
        echo "cmd_line='$(echo "$cmd_line" | sed "s/'/'\"'\"'/g")'"
    } > "$tempdir/img_info"
}

# Extract and decompile device-tree blobs
for image in boot vendor_boot vendor_kernel_boot init_boot recovery; do
    if [[ -f "${image}".img ]]; then
        # Create working directories
        mkdir -p "${image}/dtb" "${image}/dts"

        # Unpack image's content
        echo "Extracting '${image}' content..."
		cd "${image}"
        ${MAGISKBOOT} unpack ../"${image}.img" > /dev/null
		cd -
		get_bootimg_info "${image}.img" "${image}"

        ## Retrive image's ramdisk, and extract it
		ramdiskfile=$(find "${image}" -type f -name "ramdisk.cpio" | head -1)
		${BIN_7ZZ} -snld x "${ramdiskfile}" -o"${image}/ramdisk" >> /dev/null 2>&1 || \
			echo "Failed to extract ramdisk."

        ## Clean-up
		rm -rf "${ramdiskfile}" "${image}/vendor_ramdisk"

        # Extract 'dtb' via 'extract-dtb'
        echo "Trying to extract device-tree(s) from '${image}'..." 
        uvx extract-dtb "${image}.img" -o "${image}/dtb" >> /dev/null 2>&1 || \
            echo "Failed to extract device-tree blobs."

        # Remove '00_kernel'
        rm -rf "${image}/dtb/00_kernel"

        # Decompile blobs to 'dts' via 'dtc'
        for dtb in $(find "${image}/dtb" -type f); do
            dtc -q -I dtb -O dts "${dtb}" >> "${image}/dts/$(basename "${dtb}" | sed 's/\.dtb/.dts/')" || \
                echo "Failed to decompile device-tree blobs."
        done
    fi

    # If no device-tree were extracted or decompiled, delete the directories
    if ! ls -A ${image}/dtb >> /dev/null 2>&1; then
        rm -rf "${image}/dtb" "${image}/dts"
    fi
done

# Extract 'boot.img'-related content
if [[ -f boot.img ]]; then
    # Extract 'ikconfig'
    echo "Extracting 'ikconfig'..."
    ${EXTRACT_IKCONFIG} boot.img > ikconfig || {
        echo "[ERROR] Failed to generate 'ikconfig'"
    }

    # Generate non-stack symbols
    echo "[INFO] Generating 'kallsyms.txt'..."
    uvx -q --from git+https://github.com/marin-m/vmlinux-to-elf@master kallsyms-finder boot.img >> /dev/null 2>&1 > kallsyms.txt || \
        echo "[ERROR] Failed to generate 'kallsyms.txt'"

    # Generate analyzable '.elf'
    echo "[INFO] Extracting 'boot.elf'..."
    uvx -q --from git+https://github.com/marin-m/vmlinux-to-elf@master vmlinux-to-elf boot.img boot.elf >> /dev/null 2>&1 > /dev/null ||
        echo "[ERROR] Failed to generate 'boot.elf'"

fi

# Extract 'dtbo.img' separately
if [[ -f dtbo.img ]]; then
    # Create working directories
    mkdir -p "dtbo/dts"

    # Extract 'dtb' via 'extract-dtb'
    echo "Trying to extract device-tree(s) from 'dtbo'..." 
    uvx extract-dtb "dtbo.img" -o "dtbo/"  >> /dev/null 2>&1 || \
        echo "Failed to extract device-tree blobs."

    # Remove '00_kernel'
    rm -rf "dtbo/00_kernel"

    # Decompile blobs to 'dts' via 'dtc'
    for dtb in $(find "dtbo" -type f -name "*.dtb"); do
        dtc -q -I dtb -O dts "${dtb}" >> "dtbo/dts/$(basename "${dtb}" | sed 's/\.dtb/.dts/')" || \
            echo "Failed to decompile device-tree blobs."
    done
fi

# Extract Partitions
for p in $PARTITIONS; do
	[[ "$p" =~ ^(boot|recovery|dtbo|vendor_boot|init_boot|tz)$ ]] && continue
	[[ ! -e "$p.img" ]] && continue

	echo "Extracting $p partition..."
	mkdir -p "$p" && rm -rf "${p:?}"/*

	# Try 7z first
	if "${BIN_7ZZ}" x -snld "$p.img" -y -o"$p/" > /dev/null 2>&1; then
		rm -f "$p.img"
		continue
	fi

	# Try fsck.erofs (for EROFS images)
	echo "7z failed, trying fsck.erofs..."
	if [[ "$p" != "modem" ]] && "${FSCK_EROFS}" --extract="$p" "$p.img" > /dev/null 2>&1; then
		rm -f "$p.img"
		continue
	fi

	# Fall back to mount loop
	echo "fsck.erofs failed, trying mount loop..."
	if sudo mount -o loop -t auto "$p.img" "$p"; then
		mkdir -p "${p}_"
		sudo cp -rf "${p}/." "${p}_/"
		sudo umount "$p"
		sudo cp -rf "${p}_/." "$p/"
		sudo rm -rf "${p}_"
		sudo chown -R "$(whoami)" "$p"
		chmod -R u+rwX "$p"
		rm -f "$p.img"
		continue
	fi

	echo "ERROR: Could not extract '$p' partition. Unsupported filesystem."
	echo "For EROFS: Linux 5.4+ kernel required"
	echo "For F2FS: Linux 5.15+ kernel required"
done

# Remove Unnecessary Image Leftover From OUTDIR
for q in *.img; do
	if ! echo "${q}" | grep -q "boot\|recovery\|dtbo\|tz"; then
		rm -f "${q}" 2>/dev/null
	fi
done

# Oppo/Realme Devices Have Some Images In A Euclid Folder In Their Vendor and/or System, Extract Those For Props
for dir in "vendor/euclid" "system/system/euclid"; do
	if [[ -d "${dir}" ]]; then
		pushd "${dir}" || exit 1
		for f in *.img; do
			[[ -f "${f}" ]] || continue
			${BIN_7ZZ} x "${f}" -o"${f/.img/}"
			rm -f "${f}"
		done
		popd || exit 1
	fi
done

# board-info.txt
find "${OUTDIR}"/modem -type f -exec strings {} \; 2>/dev/null | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> "${TMPDIR}"/board-info.txt
find "${OUTDIR}"/tz* -type f -exec strings {} \; 2>/dev/null | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> "${TMPDIR}"/board-info.txt
if [ -e "${OUTDIR}"/vendor/build.prop ]; then
	strings "${OUTDIR}"/vendor/build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> "${TMPDIR}"/board-info.txt
fi
sort -u < "${TMPDIR}"/board-info.txt > "${OUTDIR}"/board-info.txt

# set variables
[[ $(find "$(pwd)"/system "$(pwd)"/system/system "$(pwd)"/vendor "$(pwd)"/*product -maxdepth 1 -type f -name "build*.prop" 2>/dev/null | sort -u | gawk '{print $NF}') ]] || { printf "No system/vendor/product build*.prop found, pushing cancelled.\n" && exit 1; }

# Helper: grep last match from files
get_prop() {
    local prop="$1"
    shift
    local file val
    for file in "$@"; do
        val=$(grep -h -oP "(?<=^${prop}=).*" "$file" 2>/dev/null | tail -1)
        if [[ -n "$val" ]]; then
            echo "$val"
            return 0
        fi
    done
    return 1
}

# 'flavor' property (e.g. caiman-user)
flavor=$(
    get_prop "ro.build.flavor"        {vendor,system,system/system}/build.prop        ||
    get_prop "ro.vendor.build.flavor" vendor/build*.prop                              ||
    get_prop "ro.build.flavor"        {vendor,system,system/system}/build*.prop       ||
    get_prop "ro.system.build.flavor" {system,system/system}/build*.prop              ||
    get_prop "ro.build.type"          {system,system/system}/build*.prop
)

# 'release' property (e.g. 15)
release=$(
    get_prop "ro.build.version.release"        {my_manifest,vendor,system,system/system}/build*.prop ||
    get_prop "ro.vendor.build.version.release" vendor/build*.prop                                    ||
    get_prop "ro.system.build.version.release" {system,system/system}/build*.prop
)

# 'id' property (e.g. AP4A.241205.013)
id=$(
    get_prop "ro.build.id"        my_manifest/build*.prop                   ||
    get_prop "ro.build.id"        system/system/build_default.prop          ||
    get_prop "ro.build.id"        vendor/euclid/my_manifest/build.prop      ||
    get_prop "ro.build.id"        {vendor,system,system/system}/build*.prop ||
    get_prop "ro.vendor.build.id" vendor/build*.prop                        ||
    get_prop "ro.system.build.id" {system,system/system}/build*.prop
)

# 'incremental' property (e.g. 12621605)
incremental=$(
    get_prop "ro.build.version.incremental"        my_manifest/build*.prop                   ||
    get_prop "ro.build.version.incremental"        system/system/build_default.prop          ||
    get_prop "ro.build.version.incremental"        vendor/euclid/my_manifest/build.prop      ||
    get_prop "ro.build.version.incremental"        {vendor,system,system/system}/build*.prop ||
    get_prop "ro.vendor.build.version.incremental" my_manifest/build*.prop                   ||
    get_prop "ro.vendor.build.version.incremental" vendor/euclid/my_manifest/build.prop      ||
    get_prop "ro.vendor.build.version.incremental" vendor/build*.prop                        ||
    get_prop "ro.system.build.version.incremental" {system,system/system}/build*.prop        ||
    get_prop "ro.build.version.incremental"        my_product/build*.prop                    ||
    get_prop "ro.system.build.version.incremental" my_product/build*.prop                    ||
    get_prop "ro.vendor.build.version.incremental" my_product/build*.prop
)

# 'tags' property (e.g. release-keys)
tags=$(
    get_prop "ro.build.tags"        {vendor,system,system/system}/build*.prop ||
    get_prop "ro.vendor.build.tags" vendor/build*.prop                        ||
    get_prop "ro.system.build.tags" {system,system/system}/build*.prop
)

# 'platform' property (e.g. zumapro)
platform=$(
    grep -h -oP '(?<=^ro.board.platform=)(?!common$).*' {vendor,system,system/system}/build*.prop 2>/dev/null | tail -1 ||
    get_prop "ro.vendor.board.platform" vendor/build*.prop                                                              ||
    get_prop "ro.system.board.platform" {system,system/system}/build*.prop
)

# 'manufacturer' property (e.g. google)
manufacturer=$(
    get_prop "ro.product.odm.manufacturer"     odm/etc/build*.prop                          ||
    get_prop "ro.product.manufacturer"         odm/etc/fingerprint/build.default.prop       ||
    get_prop "ro.product.manufacturer"         my_product/build*.prop                       ||
    get_prop "ro.product.manufacturer"         my_manifest/build*.prop                      ||
    get_prop "ro.product.manufacturer"         system/system/build_default.prop             ||
    get_prop "ro.product.manufacturer"         vendor/euclid/my_manifest/build.prop         ||
    get_prop "ro.product.manufacturer"         {vendor,system,system/system}/build*.prop    ||
    get_prop "ro.product.brand.sub"            my_product/build*.prop                       ||
    get_prop "ro.product.brand.sub"            system/system/euclid/my_product/build*.prop  ||
    get_prop "ro.vendor.product.manufacturer"  vendor/build*.prop                           ||
    get_prop "ro.product.vendor.manufacturer"  my_manifest/build*.prop                      ||
    get_prop "ro.product.vendor.manufacturer"  system/system/build_default.prop             ||
    get_prop "ro.product.vendor.manufacturer"  vendor/euclid/my_manifest/build.prop         ||
    get_prop "ro.product.vendor.manufacturer"  vendor/build*.prop                           ||
    get_prop "ro.system.product.manufacturer"  {system,system/system}/build*.prop           ||
    get_prop "ro.product.system.manufacturer"  {system,system/system}/build*.prop           ||
    get_prop "ro.product.odm.manufacturer"     my_manifest/build*.prop                      ||
    get_prop "ro.product.odm.manufacturer"     system/system/build_default.prop             ||
    get_prop "ro.product.odm.manufacturer"     vendor/euclid/my_manifest/build.prop         ||
    get_prop "ro.product.odm.manufacturer"     vendor/odm/etc/build*.prop                   ||
    get_prop "ro.product.manufacturer"         {oppo_product,my_product}/build*.prop        ||
    get_prop "ro.product.manufacturer"         vendor/euclid/*/build.prop                   ||
    get_prop "ro.system.product.manufacturer"  vendor/euclid/*/build.prop                   ||
    get_prop "ro.product.product.manufacturer" vendor/euclid/product/build*.prop
)

# 'fingerprint' property (e.g. google/caiman/caiman:15/AP4A.241205.013/12621605:user/release-keys)
fingerprint=$(
    get_prop "ro.odm.build.fingerprint"     odm/etc/*build*.prop                   ||
    get_prop "ro.vendor.build.fingerprint"  my_manifest/build*.prop                ||
    get_prop "ro.vendor.build.fingerprint"  system/system/build_default.prop       ||
    get_prop "ro.vendor.build.fingerprint"  vendor/euclid/my_manifest/build.prop   ||
    get_prop "ro.vendor.build.fingerprint"  odm/etc/fingerprint/build.default.prop ||
    get_prop "ro.vendor.build.fingerprint"  vendor/build*.prop                     ||
    get_prop "ro.build.fingerprint"         my_manifest/build*.prop                ||
    get_prop "ro.build.fingerprint"         system/system/build_default.prop       ||
    get_prop "ro.build.fingerprint"         vendor/euclid/my_manifest/build.prop   ||
    get_prop "ro.build.fingerprint"         {system,system/system}/build*.prop     ||
    get_prop "ro.product.build.fingerprint" product/build*.prop                    ||
    get_prop "ro.system.build.fingerprint"  {system,system/system}/build*.prop     ||
    get_prop "ro.build.fingerprint"         my_product/build.prop                  ||
    get_prop "ro.system.build.fingerprint"  my_product/build.prop                  ||
    get_prop "ro.vendor.build.fingerprint"  my_product/build.prop
)

# 'codename' property (e.g. caiman)
codename=$(
    get_prop "ro.product.odm.device"        odm/etc/build*.prop                                 ||
    get_prop "ro.product.odm.device"        system/system/build_default.prop                    ||
    get_prop "ro.product.device"            odm/etc/fingerprint/build.default.prop              ||
    get_prop "ro.product.device"            my_manifest/build*.prop                             ||
    get_prop "ro.product.device"            system/system/build_default.prop                    ||
    get_prop "ro.product.device"            vendor/euclid/my_manifest/build.prop                ||
    get_prop "ro.product.vendor.device"     system/system/build_default.prop                    ||
    get_prop "ro.product.vendor.device"     vendor/euclid/my_manifest/build.prop                ||
    get_prop "ro.vendor.product.device"     system/system/build_default.prop                    ||
    get_prop "ro.vendor.product.device"     vendor/build*.prop                                  ||
    get_prop "ro.product.vendor.device"     vendor/build*.prop                                  ||
    get_prop "ro.product.device"            {vendor,system,system/system}/build*.prop           ||
    get_prop "ro.vendor.product.device.oem" odm/build.prop                                      ||
    get_prop "ro.vendor.product.device.oem" vendor/euclid/odm/build.prop                        ||
    get_prop "ro.product.vendor.device"     my_manifest/build*.prop                             ||
    get_prop "ro.product.system.device"     {system,system/system}/build*.prop                  ||
    get_prop "ro.product.system.device"     vendor/euclid/*/build.prop                          ||
    get_prop "ro.product.product.device"    vendor/euclid/*/build.prop                          ||
    get_prop "ro.product.product.device"    system/system/build_default.prop                    ||
    get_prop "ro.product.product.model"     vendor/euclid/*/build.prop                          ||
    get_prop "ro.product.device"            {oppo_product,my_product}/build*.prop               ||
    get_prop "ro.product.product.device"    oppo_product/build*.prop                            ||
    get_prop "ro.product.system.device"     my_product/build*.prop                              ||
    get_prop "ro.product.vendor.device"     my_product/build*.prop                              ||
    { get_prop "ro.build.fota.version"      {system,system/system}/build*.prop | cut -d- -f1; } ||
    get_prop "ro.build.product"             {vendor,system,system/system}/build*.prop           ||
    echo "$fingerprint" | cut -d/ -f3 | cut -d: -f1
)

# 'brand' property (e.g. google)
brand=$(
    get_prop "ro.product.odm.brand"     odm/etc/"${codename}"_build.prop             ||
    get_prop "ro.product.odm.brand"     odm/etc/build*.prop                          ||
    get_prop "ro.product.odm.brand"     system/system/build_default.prop             ||
    get_prop "ro.product.brand"         odm/etc/fingerprint/build.default.prop       ||
    get_prop "ro.product.brand"         my_product/build*.prop                       ||
    get_prop "ro.product.brand"         system/system/build_default.prop             ||
    get_prop "ro.product.brand"         vendor/euclid/my_manifest/build.prop         ||
    get_prop "ro.product.brand"         {vendor,system,system/system}/build*.prop    ||
    get_prop "ro.product.brand.sub"     my_product/build*.prop                       ||
    get_prop "ro.product.brand.sub"     system/system/euclid/my_product/build*.prop  ||
    get_prop "ro.product.vendor.brand"  my_manifest/build*.prop                      ||
    get_prop "ro.product.vendor.brand"  system/system/build_default.prop             ||
    get_prop "ro.product.vendor.brand"  vendor/euclid/my_manifest/build.prop         ||
    get_prop "ro.product.vendor.brand"  vendor/build*.prop                           ||
    get_prop "ro.vendor.product.brand"  vendor/build*.prop                           ||
    get_prop "ro.product.system.brand"  {system,system/system}/build*.prop           ||
    get_prop "ro.product.system.brand"  vendor/euclid/*/build.prop                   ||
    get_prop "ro.product.product.brand" vendor/euclid/product/build*.prop            ||
    get_prop "ro.product.odm.brand"     my_manifest/build*.prop                      ||
    get_prop "ro.product.odm.brand"     vendor/euclid/my_manifest/build.prop         ||
    get_prop "ro.product.odm.brand"     vendor/odm/etc/build*.prop                   ||
    get_prop "ro.product.brand"         {oppo_product,my_product}/build*.prop        ||
    echo "$fingerprint" | cut -d/ -f1                                                ||
    echo "$manufacturer"
)
# Special case: override if brand is OPPO
[[ "$brand" == "OPPO" ]] && brand=$(get_prop "ro.product.system.brand" vendor/euclid/*/build.prop || echo "$brand")

# 'description' property (e.g. caiman-user 15 AP4A.241205.013 12621605 release-keys)
description=$(
    get_prop "ro.build.description"         {system,system/system}/build.prop      ||
    get_prop "ro.build.description"         {system,system/system}/build*.prop     ||
    get_prop "ro.vendor.build.description"  vendor/build.prop                      ||
    get_prop "ro.vendor.build.description"  vendor/build*.prop                     ||
    get_prop "ro.product.build.description" product/build.prop                     ||
    get_prop "ro.product.build.description" product/build*.prop                    ||
    get_prop "ro.system.build.description"  {system,system/system}/build*.prop     ||
    echo "$flavor $release $id $incremental $tags"
)

# Remaining properties
abilist=$(
    get_prop "ro.product.cpu.abilist"        {system,system/system}/build*.prop ||
    get_prop "ro.vendor.product.cpu.abilist" vendor/build*.prop
)

locale=$(get_prop "ro.product.locale" {system,system/system}/build*.prop || echo "undefined")
density=$(get_prop "ro.sf.lcd_density" {vendor,system,system/system}/build*.prop || echo "undefined")
is_ab=$(get_prop "ro.build.ab_update" {system,system/system,vendor}/build*.prop || echo "false")
treble_support=$(get_prop "ro.treble.enabled" {system,system/system}/build*.prop || echo "false")

otaver=$(
    get_prop "ro.build.version.ota" {vendor/euclid/product,oppo_product,system,system/system}/build*.prop ||
    get_prop "ro.build.fota.version" {system,system/system}/build*.prop
)
[[ -n "$otaver" && -z "$fingerprint" ]] && branch=$(echo "$otaver" | tr ' ' '-')
branch=${branch:-$(echo "$description" | tr ' ' '-')}

if [[ "$PUSH_TO_GITLAB" = true ]]; then
	rm -rf .github_token
	repo=$(printf "${brand}" | tr '[:upper:]' '[:lower:]' && echo -e "/${codename}")
else
	rm -rf .gitlab_token
	repo=$(echo "${brand}"_"${codename}"_dump | tr '[:upper:]' '[:lower:]')
fi

platform=$(echo "${platform}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
top_codename=$(echo "${codename}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
manufacturer=$(echo "${manufacturer}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
[ -f "ikconfig" ] && kernel_version=$(cat ikconfig | grep "Kernel Configuration" | head -1 | awk '{print $3}')
# Repo README File
printf "## %s\n- Manufacturer: %s\n- Platform: %s\n- Codename: %s\n- Brand: %s\n- Flavor: %s\n- Release Version: %s\n- Kernel Version: %s\n- Id: %s\n- Incremental: %s\n- Tags: %s\n- CPU Abilist: %s\n- A/B Device: %s\n- Treble Device: %s\n- Locale: %s\n- Screen Density: %s\n- Fingerprint: %s\n- OTA version: %s\n- Branch: %s\n- Repo: %s\n" "${description}" "${manufacturer}" "${platform}" "${codename}" "${brand}" "${flavor}" "${release}" "${kernel_version}" "${id}" "${incremental}" "${tags}" "${abilist}" "${is_ab}" "${treble_support}" "${locale}" "${density}" "${fingerprint}" "${otaver}" "${branch}" "${repo}" > "${OUTDIR}"/README.md
cat "${OUTDIR}"/README.md

# Generate TWRP Trees
twrpdtout="twrp-device-tree"
if [[ "$is_ab" = true ]]; then
	if [ -f recovery.img ]; then
		printf "Legacy A/B with recovery partition detected...\n"
		twrpimg="recovery.img"
	else
	twrpimg="boot.img"
	fi
else
	twrpimg="recovery.img"
fi
if [[ -f ${twrpimg} ]]; then
	mkdir -p $twrpdtout
	uvx --from git+https://github.com/twrpdtgen/twrpdtgen@master twrpdtgen $twrpimg -o $twrpdtout
	if [[ "$?" = 0 ]]; then
		[[ ! -e "${OUTDIR}"/twrp-device-tree/README.md ]] && curl https://raw.githubusercontent.com/wiki/SebaUbuntu/TWRP-device-tree-generator/4.-Build-TWRP-from-source.md > ${twrpdtout}/README.md
	fi
fi

# Remove all .git directories from twrpdtout
rm -rf $(find $twrpdtout -type d -name ".git")

# copy file names
chown "$(whoami)" ./* -R
chmod -R u+rwX ./*		#ensure final permissions
find "$OUTDIR" -type f -printf '%P\n' | sort | grep -v ".git/" > "$OUTDIR"/all_files.txt

# Generate LineageOS Trees
if [[ "$treble_support" = true ]]; then
        aospdtout="aosp-device-tree"
        mkdir -p $aospdtout
        uvx aospdtgen $OUTDIR -o $aospdtout

        # Remove all .git directories from aospdtout
        rm -rf $(find $aospdtout -type d -name ".git")

        # Regenerate all_files.txt
        find "$OUTDIR" -type f -printf '%P\n' | sort | grep -v ".git/" > "$OUTDIR"/all_files.txt
fi

# Generate Files having the sha1sum values of the Blobs
function write_sha1sum(){
	# Usage: write_sha1sum <file> <destination_file>

	local SRC_FILE=$1
	local DST_FILE=$2

	# Temporary files
	local TMP_PAIRS="${SRC_FILE}.pairs.tmp"
	local TMP_SUMS="${SRC_FILE}.sums.tmp"

	# Resolve each blob to its actual path
	grep -v '^[[:space:]]*$' "${SRC_FILE}" | grep -v '^#' | while IFS= read -r blob; do
		local topdir="${blob%%/*}"
		local resolved="$blob"
		[[ "${topdir:0:1}" == "-" ]] && resolved="${topdir#-}/${blob#${topdir}/}"
		local path="$resolved"
		[[ ! -e "$path" && -e "system/$path" ]] && path="system/$path"
		[[ ! -e "$path" && -e "system/system/$path" ]] && path="system/system/$path"
		printf '%s\t%s\n' "$blob" "$path"
	done > "${TMP_PAIRS}"

	# sha1sum on all files at once
	cut -f2 "${TMP_PAIRS}" | xargs sha1sum 2>/dev/null > "${TMP_SUMS}"

	# Load pairs + sums and write to DST_FILE
	awk '
		FILENAME == ARGV[1] {
			split($0, a, "\t")
			path2blob[a[2]] = a[1]
			next
		}
		FILENAME == ARGV[2] {
			blob = path2blob[$2]
			if (blob != "") blob2sha[blob] = $1
			next
		}
		/^[[:space:]]*$/ || /^#/ { print; next }
		{ print ($0 in blob2sha) ? $0 "|" blob2sha[$0] : $0 }
	' "${TMP_PAIRS}" "${TMP_SUMS}" "${SRC_FILE}" > "${DST_FILE}"

	# Delete the Temporary files
	rm -f "${TMP_PAIRS}" "${TMP_SUMS}"
}

# Generate proprietary-files.txt
printf "Generating proprietary-files.txt...\n"
bash "${UTILSDIR}"/android_tools/tools/proprietary-files.sh "${OUTDIR}"/all_files.txt >/dev/null
printf "# All blobs from %s, unless pinned\n" "${description}" > "${OUTDIR}"/proprietary-files.txt
cat "${UTILSDIR}"/android_tools/working/proprietary-files.txt >> "${OUTDIR}"/proprietary-files.txt

# Generate proprietary-files.sha1
printf "Generating proprietary-files.sha1...\n"
printf "# All blobs are from \"%s\" and are pinned with sha1sum values\n" "${description}" > "${OUTDIR}"/proprietary-files.sha1
write_sha1sum ${UTILSDIR}/android_tools/working/proprietary-files.{txt,sha1}
cat "${UTILSDIR}"/android_tools/working/proprietary-files.sha1 >> "${OUTDIR}"/proprietary-files.sha1

# Stash the changes done at ${UTILSDIR}/android_tools
git -C "${UTILSDIR}"/android_tools/ add --all
git -C "${UTILSDIR}"/android_tools/ stash

# Generate all_files.sha1
printf "Generating all_files.sha1...\n"
write_sha1sum "$OUTDIR"/all_files.{txt,sha1.tmp}
( cat "$OUTDIR"/all_files.sha1.tmp | grep -v all_files.txt ) > "$OUTDIR"/all_files.sha1		# all_files.txt will be regenerated
rm -rf "$OUTDIR"/all_files.sha1.tmp

# Regenerate all_files.txt
printf "Generating all_files.txt...\n"
find "$OUTDIR" -type f -printf '%P\n' | sort | grep -v ".git/" > "$OUTDIR"/all_files.txt

rm -rf "${TMPDIR}" 2>/dev/null

commit_and_push(){
	local DIRS=(
		"system_ext"
		"product"
		"system_dlkm"
		"odm"
		"odm_dlkm"
		"vendor_dlkm"
		"vendor"
		"system"
	)

	git lfs install
	[ -e ".gitattributes" ] || find . -type f -not -path ".git/*" -size +100M -exec git lfs track {} \;
	[ -e ".gitattributes" ] && {
		git add ".gitattributes"
		git commit -sm "Setup Git LFS"
		git push -u origin "${branch}"
	}

	git add $(find -type f -name '*.apk')
	git commit -sm "Add apps for ${description}"
	git push -u origin "${branch}"

	for i in "${DIRS[@]}"; do
		[ -d "${i}" ] && git add "${i}"
		[ -d system/"${i}" ] && git add system/"${i}"
		[ -d system/system/"${i}" ] && git add system/system/"${i}"
		[ -d vendor/"${i}" ] && git add vendor/"${i}"

		git commit -sm "Add ${i} for ${description}"
		git push -u origin "${branch}"
	done

	git add .
	git commit -sm "Add extras for ${description}"
	git push -u origin "${branch}"
}

split_files(){
	# usage: split_files <min_file_size> <part_size>
	# Files larger than ${1} will be split into ${2} parts as *.aa, *.ab, etc.
	mkdir -p "${TMPDIR}" 2>/dev/null
	find . -size +${1} | cut -d'/' -f'2-' >| "${TMPDIR}"/.largefiles
	if [[ -s "${TMPDIR}"/.largefiles ]]; then
		printf '#!/bin/bash\n\n' > join_split_files.sh
		while read -r l; do
			split -b ${2} "${l}" "${l}".
			rm -f "${l}" 2>/dev/null
			printf "cat %s.* 2>/dev/null >> %s\n" "${l}" "${l}" >> join_split_files.sh
			printf "rm -f %s.* 2>/dev/null\n" "${l}" >> join_split_files.sh
		done < "${TMPDIR}"/.largefiles
		chmod a+x join_split_files.sh 2>/dev/null
	fi
	rm -rf "${TMPDIR}" 2>/dev/null
}

if [[ -s "${PROJECT_DIR}"/.github_token ]]; then
	GITHUB_TOKEN=$(< "${PROJECT_DIR}"/.github_token)	# Write Your Github Token In a Text File
	[[ -z "$(git config --get user.email)" ]] && git config user.email "guptasushrut@gmail.com"
	[[ -z "$(git config --get user.name)" ]] && git config user.name "Sushrut1101"
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
	split_files 62M 47M
	printf "\nFinal Repository Should Look Like...\n" && ls -lAog
	printf "\n\nStarting Git Init...\n"
	git init		# Insure Your Github Authorization Before Running This Script
	git config --global http.postBuffer 524288000		# A Simple Tuning to Get Rid of curl (18) error while `git push`
	git checkout -b "${branch}" || { git checkout -b "${incremental}" && export branch="${incremental}"; }
	find . \( -name "*sensetime*" -o -name "*.lic" \) | cut -d'/' -f'2-' >| .gitignore
	[[ ! -s .gitignore ]] && rm .gitignore
	if [[ "${GIT_ORG}" == "${GIT_USER}" ]]; then
		curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{"name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/user/repos" >/dev/null 2>&1
	else
		curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{ "name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/orgs/${GIT_ORG}/repos" >/dev/null 2>&1
	fi
	curl -s -X PUT -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.mercy-preview+json" -d '{ "names": ["'"${platform}"'","'"${manufacturer}"'","'"${top_codename}"'","firmware","dump"]}' "https://api.github.com/repos/${GIT_ORG}/${repo}/topics" 	# Update Repository Topics
	
	# Commit and Push
	printf "\nPushing to %s via HTTPS...\nBranch:%s\n" "https://github.com/${GIT_ORG}/${repo}.git" "${branch}"
	sleep 1
	git remote add origin https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git
	commit_and_push
	sleep 1
	
	# Telegram channel post
	if [[ -s "${PROJECT_DIR}"/.tg_token ]]; then
		TG_TOKEN=$(< "${PROJECT_DIR}"/.tg_token)
		if [[ -s "${PROJECT_DIR}"/.tg_chat ]]; then		# TG Channel ID
			CHAT_ID=$(< "${PROJECT_DIR}"/.tg_chat)
		else
			CHAT_ID="@DumprXDumps"
		fi
		printf "Sending telegram notification...\n"
		printf "<b>Brand: %s</b>" "${brand}" >| "${OUTDIR}"/tg.html
		{
			printf "\n<b>Device: %s</b>" "${codename}"
			printf "\n<b>Platform: %s</b>" "${platform}"
			printf "\n<b>Android Version:</b> %s" "${release}"
			[ ! -z "${kernel_version}" ] && printf "\n<b>Kernel Version:</b> %s" "${kernel_version}"
			printf "\n<b>Fingerprint:</b> %s" "${fingerprint}"
			printf "\n<a href=\"https://github.com/%s/%s/tree/%s/\">Github Tree</a>" "${GIT_ORG}" "${repo}" "${branch}"
		} >> "${OUTDIR}"/tg.html
		TEXT=$(< "${OUTDIR}"/tg.html)
		rm -rf "${OUTDIR}"/tg.html
		curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" || printf "Telegram Notification Sending Error.\n"
	fi

elif [[ -s "${PROJECT_DIR}"/.gitlab_token ]]; then
	if [[ -s "${PROJECT_DIR}"/.gitlab_group ]]; then
		GIT_ORG=$(< "${PROJECT_DIR}"/.gitlab_group)	# Set Your Gitlab Group Name
	else
		GIT_USER="$(git config --get user.name)"
		GIT_ORG="${GIT_USER}"				# Otherwise, Your Username will be used
	fi

	# Gitlab Vars
	GITLAB_TOKEN=$(< "${PROJECT_DIR}"/.gitlab_token)	# Write Your Gitlab Token In a Text File
	if [ -f "${PROJECT_DIR}"/.gitlab_instance ]; then
		GITLAB_INSTANCE=$(< "${PROJECT_DIR}"/.gitlab_instance)
	else
		GITLAB_INSTANCE="gitlab.com"
	fi
	GITLAB_HOST="https://${GITLAB_INSTANCE}"

	# Check if already dumped or not
	[[ $(curl -sL "${GITLAB_HOST}/${GIT_ORG}/${repo}/-/raw/${branch}/all_files.txt" | grep "all_files.txt") ]] && { printf "Firmware already dumped!\nGo to https://"$GITLAB_INSTANCE"/${GIT_ORG}/${repo}/-/tree/${branch}\n" && exit 1; }

	# Remove The Journal File Inside System/Vendor
	find . -mindepth 2 -type d -name "\[SYS\]" -exec rm -rf {} \; 2>/dev/null
	printf "\nFinal Repository Should Look Like...\n" && ls -lAog
	printf "\n\nStarting Git Init...\n"

	git init		# Insure Your GitLab Authorization Before Running This Script
	git config --global http.postBuffer 524288000		# A Simple Tuning to Get Rid of curl (18) error while `git push`
	git checkout -b "${branch}" || { git checkout -b "${incremental}" && export branch="${incremental}"; }
	find . \( -name "*sensetime*" -o -name "*.lic" \) | cut -d'/' -f'2-' >| .gitignore
	[[ ! -s .gitignore ]] && rm .gitignore
	[[ -z "$(git config --get user.email)" ]] && git config user.email "guptasushrut@gmail.com"
	[[ -z "$(git config --get user.name)" ]] && git config user.name "Sushrut1101"

	# Create Subgroup
	GRP_ID=$(curl -s \
        --request GET \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_HOST}/api/v4/groups/${GIT_ORG}" | jq -r '.id')
	curl -s \
        --request POST \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"name\": \"${brand}\",
            \"path\": \"$(echo "${brand}" | tr '[:upper:]' '[:lower:]')\",
            \"visibility\": \"public\",
            \"parent_id\": \"${GRP_ID}\"
        }" \
        "${GITLAB_HOST}/api/v4/groups/"
	echo ""

	# Subgroup ID
	get_gitlab_subgrp_id() {
    	local subgrp="${1,,}"

    	curl -s \
	        --request GET \
    	    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
			"${GITLAB_HOST}/api/v4/groups/${GIT_ORG}/subgroups?per_page=100" \
    		| jq -r --arg name "$subgrp" '.[] | select(.path == $name) | .id'
	}

	SUBGRP_ID=$(get_gitlab_subgrp_id "${brand}")

	# Create Repository
    curl -s \
        --request POST \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"name\": \"${codename}\",
            \"namespace_id\": \"${SUBGRP_ID}\",
            \"visibility\": \"public\"
        }" \
        "${GITLAB_HOST}/api/v4/projects"

	# Get Project/Repo ID
	get_gitlab_project_id() {
	    local proj="$1"
	    local group_id="$2"

    	curl -s \
	        --request GET \
    	    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
			"${GITLAB_HOST}/api/v4/groups/${group_id}/projects?per_page=100" \
    		| jq -r --arg name "$proj" '.[] | select(.path == $name) | .id'
	}

	PROJECT_ID=$(get_gitlab_project_id "${codename}" "${SUBGRP_ID}")

	# Commit and Push
	# Pushing via HTTPS doesn't work on GitLab for Large Repos (it's an issue with gitlab for large repos)
	# NOTE: Your SSH Keys Needs to be Added to your Gitlab Instance
	git remote add origin git@${GITLAB_INSTANCE}:${GIT_ORG}/${repo}.git

	# Ensure that the target repo is public
    curl -s \
        --request PUT \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data '{"visibility": "public"}' \
        "${GITLAB_HOST}/api/v4/projects/${PROJECT_ID}"
	printf "\n"

	# Push to GitLab
	while [[ ! $(curl -sL "${GITLAB_HOST}/${GIT_ORG}/${repo}/-/raw/${branch}/all_files.txt" | grep "all_files.txt") ]]
	do
		printf "\nPushing to %s via SSH...\nBranch:%s\n" "${GITLAB_HOST}/${GIT_ORG}/${repo}.git" "${branch}"
		sleep 1
		commit_and_push
		sleep 1
	done

	# Update the Default Branch
	curl -s \
	    --request PUT \
	    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
	    --header "Content-Type: application/json" \
	    --data "{\"default_branch\": \"${branch}\"}" \
	    "${GITLAB_HOST}/api/v4/projects/${PROJECT_ID}"

	printf "\nDone! Repo available at %s/%s/%s\n" "${GITLAB_HOST}" "${GIT_ORG}" "${repo}"

	# Telegram channel post
	if [[ -s "${PROJECT_DIR}"/.tg_token ]]; then
		TG_TOKEN=$(< "${PROJECT_DIR}"/.tg_token)
		if [[ -s "${PROJECT_DIR}"/.tg_chat ]]; then		# TG Channel ID
			CHAT_ID=$(< "${PROJECT_DIR}"/.tg_chat)
		else
			CHAT_ID="@DumprXDumps"
		fi
		printf "Sending telegram notification...\n"
		printf "<b>Brand: %s</b>" "${brand}" >| "${OUTDIR}"/tg.html
		{
			printf "\n<b>Device: %s</b>" "${codename}"
			printf "\n<b>Platform: %s</b>" "${platform}"
			printf "\n<b>Android Version:</b> %s" "${release}"
			[ ! -z "${kernel_version}" ] && printf "\n<b>Kernel Version:</b> %s" "${kernel_version}"
			printf "\n<b>Fingerprint:</b> %s" "${fingerprint}"
			printf "\n<a href=\"${GITLAB_HOST}/%s/%s/-/tree/%s/\">Gitlab Tree</a>" "${GIT_ORG}" "${repo}" "${branch}"
		} >> "${OUTDIR}"/tg.html
		TEXT=$(< "${OUTDIR}"/tg.html)
		rm -rf "${OUTDIR}"/tg.html
		curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" || printf "Telegram Notification Sending Error.\n"
	fi

else
	printf "Dumping done locally.\n"
	exit
fi
