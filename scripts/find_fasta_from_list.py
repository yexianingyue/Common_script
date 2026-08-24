#!/share/data1/software/miniconda3/bin/python
'''
输出未找到的名称
'''
import sys
import re
import gzip,bz2
from Bio import SeqIO

if sys.argv.__len__() > 4 or len(sys.argv) < 3:
    print(f"{__file__} \033[31m <name list> <fasta|fasta.gz|fasta.bz2> [-e]\033[0m")
    print("-e: means print the list to stderr which can't find in the fasta file.")
    exit(0)

q_dict = {}
f = open(sys.argv[1],'r')
for i in f:
    q_dict[i.strip()] = 1
f.close()

if re.search(".gz$", sys.argv[2]):
    fasta = gzip.open(sys.argv[2], 'rt')
elif re.search(".bz2$", sys.argv[2]):
    fasta = bz2.open(sys.argv[2],'rt')
else:
    fasta = open(sys.argv[2], 'r')

for seq in SeqIO.parse(fasta, 'fasta'):
    # 如果没有值，则退出循环
    if not q_dict:
        break
    if q_dict.get(seq.id):
        print(">{}".format(seq.description))
        print(seq.seq)
        del q_dict[seq.id]
try:
    if sys.argv[3] == "-e":
        if q_dict:
            for k,v in q_dict.items():
                sys.stderr.write(f"{k}\n")
except:
    sys.stderr.write(f"end.\n")
