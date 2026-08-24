#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2019-12-30, 20:05:24
# Modiffed date :  2019-12-30, 20:05:24
##########################################################
'''
print_id_len.py <fasta_file>  > output
'''
import sys, gzip, bz2, re
from Bio import SeqIO
from Bio.SeqUtils import GC

def myopen(inf):
    if re.search(".gz$", inf):
        fasta = gzip.open(inf, 'rt')
    elif re.search(".bz2$", inf):
        fasta = bz2.open(inf,'rt')
    else:
        fasta = open(inf, 'r')
    return fasta

def all_info(file_):
    print(f"name\tlength\tgc%\tG\tC\tA\tT")

    fasta = myopen(file_)
    for i in SeqIO.parse(fasta, 'fasta'):
        print("{}\t{}\t{}\t{}\t{}\t{}\t{}".format(i.id, len(i.seq), GC(i.seq), i.seq.count("G"), i.seq.count("C") , i.seq.count("A") , i.seq.count("T")))

def get_len():
    fasta = myopen(sys.argv[1])

    for i in SeqIO.parse(fasta, 'fasta'):
        print("{}\t{}".format(i.id, len(i.seq)))


def main():
    if "-gc" in sys.argv:
        if sys.argv.index("-gc") == 1:
            all_info(sys.argv[2])
        else:
            all_info(sys.argv[1])
    else:
        get_len()


if __name__ == "__main__":
    if sys.argv.__len__() == 1 or sys.argv.__len__() > 3 :
        print(f"{sys.argv[0]} [-gc ] fasta_file")
        print("\033[31;1mif not -gc it only print len\033[0m")
        exit(0)
    main()


