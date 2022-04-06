#!/share/data1/software/miniconda3/bin/python
#from itertools import product
import re
import sys
import os
from itertools import product
from copy import deepcopy as dp

TNF_DICT = {}
TEMP_DICT = {"A":"T",
             "C":"G",
             "T":"A",
             "G":"C"}

def reverse_seq(seq: set) -> str:
    global TEMP_DICT
    temp = ""
    for s in seq:
        temp += TEMP_DICT[s]
    return temp[::-1]

def create_reverse_complete_seq():
    for i in product("ATCG", repeat=4):
        i = "".join(i)
        rev = reverse_seq(i)
        if TNF_DICT.get(rev) == 0:
            #print(i)
            continue
        TNF_DICT[i] = 0
     
def get_TNF(name: str, seq: str):
    global TNF_DICT
    temp_result = dp(TNF_DICT)
    seq_len = len(seq)
    end = seq_len - 3
    for i in range(0, end):
        kerm = seq[i:i+4]
        try:
            temp_result[kerm] += 1
        except:
            rev_kerm = reverse_seq(kerm)
            temp_result[rev_kerm] += 1
    print(f"{name}", end="")
    for k,v in temp_result.items():
        print(f"\t{v}",end="")
    print("\n", end="")

def get_seq(fasta_file):

    global TNE_DICT
    print(f"name", end="")
    for k,v in TNF_DICT.items():
        print(f"\t{k}",end="")
    print("\n", end="")

    f = open(f"{fasta_file}", 'r')
    last_name = ""
    seq = ""
    for line in f:
        if line[0] == ">":
            if last_name != "":
                get_TNF(last_name, seq)
            seq = ""
            try:
                last_name = re.match(">(.*?)\s+", line.strip()).group(1)
            except:
                last_name = re.match(">(.*)", line.strip()).group(1)
        else:
            seq += "".join(re.findall("[ATCG]+", line.strip().upper()))
    get_TNF(last_name, seq) #处理最后一个序列
    f.close()

def check_dir(out_dir):
    if not os.path.exists(out_dir):
        print(f"mkdir -p {out_dir}")
        os.makedirs(out_dir)


def main():
    get_seq(sys.argv[1])

if __name__ == "__main__":
    if sys.argv.__len__() != 2:
        print(f"Version: V 0.1\n         by: yexianingyue@126.com")
        print(f"Use:\n    {sys.argv[0]} <fasta>")
        exit(0)

    #check_dir(sys.argv[2])
    create_reverse_complete_seq()
    main()

