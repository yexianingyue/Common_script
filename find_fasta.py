#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2019-12-10, 19:03:49
# Modiffed date :  2019-12-10, 19:03:49
##########################################################

'''
<seq_name> is the seq header  before the first spaces
'''
from Bio import SeqIO
import re
import argparse

def cut_seq(fasta_file, name, count_limit, start, stop, count):
    for seq in SeqIO.parse(fasta_file, 'fasta'):
        if seq.id == name:
            if count_limit == 0:
                print(">{}_cut_{}:{}\tpoint={}:{}\tcut_length= {}\tseq_full_lenth= {}".format(seq.id, start, stop, start, stop, stop-start+1, len(seq.seq)))
                print(seq.seq[start-1: stop])
                count += 1
                if count_limit == 1:
                    exit(0)
                continue
            elif count > count_limit and count_limit > 0:
                exit(0)
            print(">{}_cut_{}:{}\tpoint={}:{}\tcut_length= {}\tseq_full_lenth= {}".format(seq.id, start, stop, start, stop, stop-start+1, len(seq.seq)))
            print(seq.seq[start-1: stop])
            count += 1

def full_seq(fasta_file, name, count_limit, start, count):
    for seq in SeqIO.parse(fasta_file, 'fasta'):
       if seq.id == name:
           if count_limit == 0:
               print(">{}\tseq_full_lenth= {}".format(seq.id, len(seq.seq)))
               print(seq.seq)
               count += 1
               if count_limit == 1:
                   print("123")
                   exit(0)
               continue
           elif count > count_limit and count_limit > 0:
               exit(0)
           print(">{}\tseq_full_lenth= {}".format(seq.id, len(seq.seq)))
           print(seq.seq)
           count += 1

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='./find_fasta.py <fasta_file>  <seq_name> [optional]',description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("f", metavar='file', type=str, help='the fasta format file')
    parser.add_argument("n", metavar='name', type=str, help='seq name')
    parser.add_argument("-l", metavar='limit', default=1, type=int, help='to find the num seqs ,0:all , [1:defaule]')
    parser.add_argument("--start", metavar='start', default=1, type=int, help='start:int [1: default]')
    parser.add_argument("--stop", metavar='stop', default=None, type=int, help='stop: int [all: default]')
    args = parser.parse_args()
    fasta_file = args.f
    name = args.n
    count_limit = args.l
    start = args.start
    stop = args.stop
    count = 0
    if stop:
        cut_seq(fasta_file, name, count_limit, start, stop, count)
    else:
        full_seq(fasta_file, name, count_limit, start, count)

