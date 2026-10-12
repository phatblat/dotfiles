#!/usr/bin/env python3
#
# v2 pbzx stream handler
#
# pudquick/parse_pbzx2.py
# From: https://gist.github.com/pudquick/ff412bcb29c9c1fa4b8d
# -------
# My personal writeup on the differences here: https://gist.github.com/pudquick/29fcfe09c326a9b96cf5
#
# Pure python reimplementation of .cpio.xz content extraction from pbzx file payload originally here:
# http://www.tonymacx86.com/general-help/135458-pbzx-stream-parser.html
#
# Cleaned up C version (as the basis for my code) here, thanks to Pepijn Bruienne / @bruienne
# https://gist.github.com/bruienne/029494bbcfb358098b41

import struct
import sys
from pathlib import Path

XZ_MAGIC = b"\xfd7zXZ\x00"


def seekread(f, offset=None, length=0, relative=True):
    if offset is not None:
        # offset provided, let's seek
        f.seek(offset, [0, 1, 2][relative])
    if length != 0:
        return f.read(length)
    return None


def append_bytes(path, *chunks):
    with open(path, "ab") as out:
        out.writelines(chunks)


def parse_pbzx(pbzx_path):
    section = 0
    xar_out_path = f"{pbzx_path}.part{section:02d}.cpio.xz"
    Path(xar_out_path).write_bytes(b"")
    with open(pbzx_path, "rb") as f:
        magic = seekread(f, length=4)
        if magic != b"pbzx":
            raise ValueError("Error: Not a pbzx file")
        # Read 8 bytes for initial flags
        flags = seekread(f, length=8)
        # Interpret the flags as a 64-bit big-endian unsigned int
        flags = struct.unpack(">Q", flags)[0]
        while flags & (1 << 24):
            # Read in more flags
            flags = seekread(f, length=8)
            flags = struct.unpack(">Q", flags)[0]
            # Read in length
            f_length = seekread(f, length=8)
            f_length = struct.unpack(">Q", f_length)[0]
            xzmagic = seekread(f, length=6)
            if xzmagic != XZ_MAGIC:
                # This isn't xz content, this is actually _raw decompressed cpio_ chunk of 16MB in size...
                # Let's back up ...
                seekread(f, offset=-6, length=0)
                # ... and split it out ...
                f_content = seekread(f, length=f_length)
                section += 1
                decomp_out = f"{pbzx_path}.part{section:02d}.cpio"
                Path(decomp_out).write_bytes(f_content)
                # Now to start the next section, which should hopefully be .xz (we'll just assume it is ...)
                section += 1
                xar_out_path = f"{pbzx_path}.part{section:02d}.cpio.xz"
                Path(xar_out_path).write_bytes(b"")
            else:
                f_length -= 6
                # This part needs buffering
                f_content = seekread(f, length=f_length)
                tail = seekread(f, offset=-2, length=2)
                append_bytes(xar_out_path, xzmagic, f_content)
                if tail != b"YZ":
                    raise ValueError("Error: Footer is not xar file footer")


def main():
    parse_pbzx(sys.argv[1])
    print(
        "Now xz decompress the .xz chunks, then 'cat' them all together in order into a single new.cpio file"
    )


if __name__ == "__main__":
    main()
