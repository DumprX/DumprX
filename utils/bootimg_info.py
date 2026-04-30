#!/usr/bin/env python3

"""
Prints boot, recovery or vendor_boot image info.
"""

from argparse import ArgumentParser
from struct import unpack

BOOT_IMAGE_HEADER_V3_PAGESIZE = 4096

def get_number_of_pages(image_size, page_size):
    """calculates the number of pages required for the image"""
    return (image_size + page_size - 1) // page_size

def cstr(s):
    """Remove first NULL character and any character beyond."""
    return s.split('\0', 1)[0]

def format_os_version(os_version):
    if os_version == 0:
        return None
    a = os_version >> 14
    b = os_version >> 7 & ((1<<7) - 1)
    c = os_version & ((1<<7) - 1)
    return f'{a}.{b}.{c}'

def format_os_patch_level(os_patch_level):
    if os_patch_level == 0:
        return None
    y = os_patch_level >> 4
    y += 2000
    m = os_patch_level & ((1<<4) - 1)
    return f'{y:04d}-{m:02d}'

def decode_os_version_patch_level(os_version_patch_level):
    """Returns a tuple of (os_version, os_patch_level)."""
    os_version = os_version_patch_level >> 11
    os_patch_level = os_version_patch_level & ((1<<11) - 1)
    return (format_os_version(os_version),
            format_os_patch_level(os_patch_level))

class BootImageInfoFormatter:
    """Formats the boot image info."""
    def print_info(self):
        print(f'header version: {self.header_version}')
        if self.os_version:
            print(f'os_version: {self.os_version}')
        if self.os_patch_level:
            print(f'os_patch_level: {self.os_patch_level}')
        
        if self.header_version <= 2:
            base = self.kernel_load_address - 0x00008000

            print(f'pagesize: {self.page_size}')
            print(f'base: {base:#010x}')
            print(f'kernel_offset: {self.kernel_load_address - base:#010x}')
            print(f'ramdisk_offset: {self.ramdisk_load_address - base:#010x}')
            if self.second_size > 0:
                print(f'second_offset: {self.second_load_address - base:#010x}')
            print(f'tags_offset: {self.tags_load_address - base:#010x}')
            if self.header_version == 2:
                print(f'dtb_offset: {self.dtb_load_address - base:#010x}')
            print(f"board: '{self.product_name}'")
            print(f"cmdline: '{self.cmdline + self.extra_cmdline}'")
        else:
            print(f'pagesize: {BOOT_IMAGE_HEADER_V3_PAGESIZE}')
            print(f"cmdline: '{self.cmdline}'")

def parse_boot_image(boot_img):
    info = BootImageInfoFormatter()
    info.boot_magic = unpack('8s', boot_img.read(8))[0].decode()
    kernel_ramdisk_second_info = unpack('9I', boot_img.read(9 * 4))
    
    # header_version is always at [8] regardless of the value of header_version.
    info.header_version = kernel_ramdisk_second_info[8]

    if info.header_version < 3:
        info.kernel_size = kernel_ramdisk_second_info[0]
        info.kernel_load_address = kernel_ramdisk_second_info[1]
        info.ramdisk_size = kernel_ramdisk_second_info[2]
        info.ramdisk_load_address = kernel_ramdisk_second_info[3]
        info.second_size = kernel_ramdisk_second_info[4]
        info.second_load_address = kernel_ramdisk_second_info[5]
        info.tags_load_address = kernel_ramdisk_second_info[6]
        info.page_size = kernel_ramdisk_second_info[7]
        os_version_patch_level = unpack('I', boot_img.read(1 * 4))[0]
    else:
        info.kernel_size = kernel_ramdisk_second_info[0]
        info.ramdisk_size = kernel_ramdisk_second_info[1]
        os_version_patch_level = kernel_ramdisk_second_info[2]
        info.second_size = 0
        info.page_size = BOOT_IMAGE_HEADER_V3_PAGESIZE

    info.os_version, info.os_patch_level = decode_os_version_patch_level(
        os_version_patch_level)

    if info.header_version < 3:
        info.product_name = cstr(unpack('16s', boot_img.read(16))[0].decode())
        info.cmdline = cstr(unpack('512s', boot_img.read(512))[0].decode())
        boot_img.read(32)  # ignore SHA
        info.extra_cmdline = cstr(unpack('1024s', boot_img.read(1024))[0].decode())
    else:
        info.cmdline = cstr(unpack('1536s', boot_img.read(1536))[0].decode())

    if info.header_version in {1, 2}:
        info.recovery_dtbo_size = unpack('I', boot_img.read(1 * 4))[0]
    else:
        info.recovery_dtbo_size = 0

    if info.header_version == 2:
        info.dtb_size = unpack('I', boot_img.read(4))[0]
        info.dtb_load_address = unpack('Q', boot_img.read(8))[0]
    else:
        info.dtb_size = 0
        info.dtb_load_address = 0

    return info

class VendorBootImageInfoFormatter:
    """Formats the vendor_boot image info."""
    def print_info(self):
        base = self.kernel_load_address - 0x00008000

        print(f'header version: {self.header_version}')
        print(f'pagesize: {self.page_size}')
        print(f'base: {base:#010x}')
        print(f'kernel_offset: {self.kernel_load_address - base:#010x}')
        print(f'ramdisk_offset: {self.ramdisk_load_address - base:#010x}')
        print(f'tags_offset: {self.tags_load_address - base:#010x}')
        print(f'dtb_offset: {self.dtb_load_address - base:#010x}')
        print(f"vendor_cmdline: '{self.cmdline}'")
        print(f"board: '{self.product_name}'")

def parse_vendor_boot_image(boot_img):
    info = VendorBootImageInfoFormatter()
    info.boot_magic = unpack('8s', boot_img.read(8))[0].decode()
    info.header_version = unpack('I', boot_img.read(4))[0]
    info.page_size = unpack('I', boot_img.read(4))[0]
    info.kernel_load_address = unpack('I', boot_img.read(4))[0]
    info.ramdisk_load_address = unpack('I', boot_img.read(4))[0]
    info.vendor_ramdisk_size = unpack('I', boot_img.read(4))[0]
    info.cmdline = cstr(unpack('2048s', boot_img.read(2048))[0].decode())
    info.tags_load_address = unpack('I', boot_img.read(4))[0]
    info.product_name = cstr(unpack('16s', boot_img.read(16))[0].decode())
    info.header_size = unpack('I', boot_img.read(4))[0]
    info.dtb_size = unpack('I', boot_img.read(4))[0]
    info.dtb_load_address = unpack('Q', boot_img.read(8))[0]

    return info

def parse_bootimg_info(boot_img):
    """Parses the |boot_img| and returns the 'info' object."""
    with open(boot_img, 'rb') as image_file:
        boot_magic = unpack('8s', image_file.read(8))[0].decode()
        image_file.seek(0)
        if boot_magic == 'ANDROID!':
            info = parse_boot_image(image_file)
        elif boot_magic == 'VNDRBOOT':
            info = parse_vendor_boot_image(image_file)
        else:
            raise ValueError(f'Not an Android boot image, magic: {boot_magic}')
    return info

def parse_cmdline():
    """parse command line arguments"""
    parser = ArgumentParser(description='Prints boot, recovery or vendor_boot image info.')
    parser.add_argument('boot_img', help='path to the boot, recovery or vendor_boot image')
    return parser.parse_args()

def main():
    """parse arguments and print boot image info"""
    args = parse_cmdline()
    info = parse_bootimg_info(args.boot_img)
    info.print_info()

if __name__ == '__main__':
    main()
