#!/usr/bin/env sh

if [ ! $(id -u) -eq 0 ]; then
	printf "Run This File As Root User\n"
	exit 1
fi

if grep -q ^ID=alpine$ /etc/os-release; then
	if ! grep -q ".*alpine\/edge" /etc/apk/repositories; then
		{
			printf "http://dl-cdn.alpinelinux.org/alpine/edge/main\n"
			printf "http://dl-cdn.alpinelinux.org/alpine/edge/community\n"
			printf "http://dl-cdn.alpinelinux.org/alpine/edge/testing\n"
		} >> /etc/apk/repositories
	fi
	apk update -q --progress
	apk add --progress --no-cache --purge --update-cache \
		bash bash-completion binutils coreutils scanelf ncurses ncurses-dev findutils grep dpkg musl-dev libffi gawk sed file sharutils xterm \
		wget curl aria2 ca-certificates gzip cpio bzip2 libbz2 lz4 xz-dev xz xz-libs zlib lzo lzop brotli tar zstd zstd-dev p7zip \
		gcc libgcc libstdc++ linux-headers libc-dev git libxml2 libfdt dtc-dev python3-dev openssh openssl libcrypto1.1 libssl1.1 gnupg detox xxd
elif grep -q ^ID_LIKE=debian$ /etc/os-release; then
	sed 's/main$/main universe/' /etc/apt/sources.list 1>/dev/null
	apt-get update -qy
	apt-get install -qy --show-progress coreutils build-essential gawk git-core sharutils uudeview mpack p7zip-full p7zip-rar \
		gzip cpio bzip2 liblz4-dev liblz4-tool liblzma-dev xz-utils lzma lzop \
		libxml2 libfdt-dev python3-dev aria2 detox brotli zstd libzstd-dev openssl xxd jq liblz4-devel
fi

if [ $? -eq 0 ]; then
	wget -q -O get-pip.py https://bootstrap.pypa.io/get-pip.py
	python3 get-pip.py --upgrade --disable-pip-version-check --no-cache-dir
	rm -f get-pip.py
	pip3 install future requests humanize clint backports.lzma lz4 zstandard protobuf pycryptodome docopt twrpdtgen
fi
