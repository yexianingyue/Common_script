#!/share/data1/software/miniconda3/envs/bio38/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2020-01-20, 11:20:42
# Modiffed date :  2020-01-20, 11:20:42
##########################################################

import re
import sys


def match(i,model):
    if model == 1:
        temp = re.split("\s+",i.split("\t")[2],maxsplit=1)[0]
    else:
        temp = re.split("\s+",i.split("\t")[2])[2]
    return str(temp)

def parse_(file_, model):
    com = re.compile(f"{sys.argv[2]}")
    try:
        name = com.search(file_).group(1)
    except:
        name = file_
    f = open(file_, 'r')
    for i in f:
        if re.findall("Total number", i):
            tn = match(i, model)
        elif re.findall("Total length of", i):
            tl = match(i, model)
        elif re.findall("N50", i):
            n5 = match(i, model)
        elif re.findall("N90", i):
            n9 = match(i, model)
        elif re.findall("Maximum",i):
            maxl = match(i, model)
        elif re.findall("Minimum",i):
            minl = match(i, model)
        elif re.findall("GC",i):
            GC = match(i, model)
    f.close()

    result = "{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}".format(name,tn,tl,n5,n9,maxl,minl,GC)
    print(result)

if __name__ == "__main__":


    if sys.argv.__len__() == 1 or sys.argv[1] == "-h":
        print("example:")
        print(f"{sys.argv[0]} <filter/origin> \"(.*).haha.youzi.so\"  *.haha.youzi.so")
        print(f"result:")
        print("as\t1234567")
        print("bs\t2345678")
        print("...")
        exit(0)

    print("\t".join(("name", "totalNumber", "totalLength", "n50", "n90", "maxlen", "minlen", "GC%")))
    f_dict={"origin":1, "filter":0}
    for i in sys.argv[3:]:
        parse_(i.strip(),f_dict[sys.argv[1]])

