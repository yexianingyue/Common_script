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
    if model == 0:
        temp = re.split("\s+",i.split("\t")[2])[0]
    elif model == 1:
        temp = re.split("\s+",i.split("\t")[2])[1]
    elif model == 2:
        temp = re.split("\s+",i.split("\t")[2])[2]
    elif model == 3:
        temp = re.split("\s+",i.split("\t")[2])[3]
    return str(temp)

def parse_(file_, model):
    com = re.compile(f"{sys.argv[2]}")
    try:
        name = com.search(file_).group(1)
    except:
        name = file_
    tn = None
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
        elif re.findall("Average",i):
            avg = match(i, model)
        elif re.findall("Minimum",i):
            minl = match(i, model)
        elif re.findall("GC",i):
            GC = match(i, model)
    f.close()

    if tn != None:
        result = "{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}".format(name,tn,tl,n5,n9,maxl,minl,avg,GC)
        print(result)

if __name__ == "__main__":

    if sys.argv.__len__() == 1 or sys.argv[1] == "-h":
        print("example:")
        print(f"{sys.argv[0]} \033[4m<flag>\033[0m \"(.*).haha.youzi.so\"  *.haha.youzi.so")
        print(f"flag:\n\torigin_ctg\n\torigin_scaffold\n\tfilter_ctg\n\tfilter_scaffold")
        print(f"result:")
        print("as\t1234567")
        print("bs\t2345678")
        print("...")
        exit(0)

    print("\t".join(("name", "totalNumber", "totalLength", "n50", "n90", "maxlen", "minlen", "Average", "GC%")))
    f_dict={"origin_ctg":0,"origin_scaffold":1,'filter_ctg':2,'filter_scaffold':3}
    for i in sys.argv[3:]:
        parse_(i.strip(),f_dict[sys.argv[1]])

