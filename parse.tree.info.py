#!/usr/bin/python3
import re
import sys

f = open(sys.argv[1], 'r')

temp_stat = 0
stat = 0
temp_dict = {}

for line in f:
    temp_stat += 1
    line_split = re.split("\s+", line.strip())
    pn, cn = int(line_split[0]), int(line_split[1])

    if pn == cn:
        stat = temp_stat
        continue
    if stat == 0:
        print(f"{cn}\t{cn},")

    if temp_dict.get(pn):
        temp_dict[pn].append(cn)
        continue
    temp_dict[pn] = [cn]
f.close()

def query(ql:list):
    global temp_dict
    for q in ql:
        if q < stat:
            print(f"{q},", end="")
        else:
            query(temp_dict[q])



for k,v in temp_dict.items():
    print(f"{k}", end="\t")
    query(v)
    print("")




