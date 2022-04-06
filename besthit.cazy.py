#!/share/data1/software/miniconda3/bin/python
import sys
import re
from fractions import Fraction as frac

'''
cazy注释结果，容易个菌注释到多个酶，则平均分配，保持总基因数不变
'''


if '-h' in sys.argv or '--help' in sys.argv or '-help' in sys.argv or sys.argv.__len__() != 2 :
    print(f"{sys.argv[0]}  <diamond output of cazy>")
    exit(127)

al = {}
result = {}

f = open(sys.argv[1], 'r')
for line in f:
    line_split = re.split("\s+", line.strip())
    if al.get(line_split[0]):
        continue

    hit = re.split("\|", line_split[1])
    count = 0
    al[line_split[0]] = 1

    for h in hit[1:]:
        if re.search("^[A-Za-z]+", h):
            count += 1

    for h in hit[1:count+1]:
        m = f"1/{count}"
        if result.get(h):
            result[h] += frac(m)
        else:
            result[h] = frac(m)
f.close()

for k,v in result.items():
    print(f"{k}\t{v}")
