#!/usr/bin/env python3

import sys
import argparse

def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("i", help="input matrix")
    parser.add_argument("o", help="output prefix")
    parser.add_argument("-t", action='store_true', help="have title")
    parser.add_argument("-l", type=int, default=100, help="lines perl file.")
    args = parser.parse_args()
    return args


def read_file(filepath):
    with open(filepath, 'rb') as f:
        header = f.read(4)
    if header[:2] == b'\x1f\x8b':  # Gzip
        return gzip.open(filepath, 'rt')
    elif header[:2] == b'BZ':  # Bzip2
        return bz2.open(filepath, 'rt')
    else:
        return open(filepath, 'r')

def main(args):
    inf = args.i
    outp = args.o
    title = args.t
    lines = args.l

    f = read_file(inf)

    title_content = ""
    if title:
        title_content = f.readline()

    countf = 0
    res = title_content

    for index, line in enumerate(f):

        x = index // lines

        if x == countf:
            res += line
        elif x != countf:
            with open(f"{outp}.{countf}", 'w') as out:
                out.write(res)
            countf = x
            res = title_content + line

    if res != title:
        with open(f"{outp}.{countf}", 'w') as out:
            out.write(res)

    f.close()


if __name__ == "__main__":
    args = get_args()
    main(args)

