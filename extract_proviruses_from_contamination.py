#!/share/data1/software/miniconda3/bin/python
from Bio import SeqIO
import sys
import re

tsv = sys.argv[1]
f = open(tsv, 'r')
proviruses = dict()
ctg_length = dict()
for line in f:
    count = 1
    line_split = re.split("\t", line.strip())
    name = line_split[0]
    length = line_split[1]
    if line_split[5] == "Yes":
        types = re.split(",", line_split[8])
        regions = re.split(",", line_split[10])
        # 循环类型
        temp = []
        for i, v in enumerate(types):
            if v == "viral":
                region = regions[i]
                reg = re.split("-", region)
                try:
                    temp.append(reg)
                except:
                    print(line)
                    print(reg)
                    print(temp)
                    exit(0)
        proviruses[name] = temp
        ctg_length[name] = length
f.close()

for seq in SeqIO.parse(sys.argv[2],'fasta'):
    if ctg_length.get(seq.id):
        regions = proviruses[seq.id]
        for i,reg in enumerate(regions): 
            print(f">{seq.id}_{i+1} {reg[0]}-{reg[1]}/{ctg_length[seq.id]}")
            print(seq.seq[int(reg[0])-1:int(reg[1])])


