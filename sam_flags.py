#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2021-02-18, 19:14:38
# Modiffed date :  2021-02-18, 19:14:38
##########################################################
import fileinput
import re
import sys
try:
    with fileinput.input() as f:
        for line in f:
            reads_name, reads_flags = re.split("\s+", line.strip())
            b = "reads1" if bin(int(reads_flags))[-7] == "1" else "reads2"
            print(f"{reads_name}\t{b}")
except:
    print(f"{sys.argv[0]} < file")
    print("file:")
    print("readsname    map_flags")
    exit(0)

'''
1    （1）            该read是成对的paired reads中的一个 
2    （10）           paired reads中每个都正确比对到参考序列上 
4    （100）          该read没比对到参考序列上 
8    （1000）         与该read成对的matepair read没有比对到参考序列上 
16   （10000）        该read其反向互补序列能够比对到参考序列 
32   （100000）       与该read成对的matepair read其反向互补序列能够比对到参考序列 
64   （1000000）      在paired reads中，该read是与参考序列比对的第一条 
128  （10000000）     在paired reads中，该read是与参考序列比对的第二条 
256  （100000000）    该read是次优的比对结果 
512  （1000000000）   该read没有通过质量控制 
1024 （10000000000）  由于PCR或测序错误产生的重复reads 
2048 （100000000000） 补充匹配的read 
'''
