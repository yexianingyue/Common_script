#!/share/data1/software/miniconda3/bin/python
'''
输出未找到的名称
'''
import sys
import re
import gzip
from Bio import SeqIO

if sys.argv.__len__() != 3:
    print(f"{__file__} \033[31m <name list> <fasta|fasta.gz> \033[0m")
    exit(0)
q_dict = {}
f = open(sys.argv[1],'r')
for i in f:
    q_dict[i.strip()] = 1
f.close()

if re.search(".gz$", sys.argv[2]):
    fasta = gzip.open(sys.argv[2], 'rt')
else:
    fasta = open(sys.argv[2], 'r')

for seq in SeqIO.parse(fasta, 'fasta'):
    if q_dict.get(seq.id):
        print(">{}".format(seq.description))
        print(seq.seq)
        del q_dict[seq.id]
if q_dict:
    for k,v in q_dict.items():
        sys.stderr.write(f"{k}\n")
