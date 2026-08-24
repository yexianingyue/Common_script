#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-03-05, 11:08:11
# Modiffed date :  2023-03-05, 11:08:11
##########################################################

'''
根据某一个文件的某一列，提取另一个文件
'''

import argparse
import re


def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-i', metavar='', type=str, required=True, help='reference file')
    parser.add_argument('-n', metavar='',type=int, default=1, help='\033[31mWhich col. [1:default]\033[0m')
    
    parser.add_argument('-I', metavar='', type=str, required=True, help='target file')
    parser.add_argument('-N', metavar='',type=int, default=1, help='\033[31mWhich col. [1:default]\033[0m')
    
    parser.add_argument('-o', metavar='', type=str, default="combined.profile", help='Output Matrix')
    parser.add_argument('-w', metavar='', type=int, default=1, help='\033[31mwhether shared. [1:default]\033[0m')

    parser.add_argument("--skip", type=int, default=0, help="How many lines should be skipped in target file.\033[31m[0:default]\033[0m")
    parser.add_argument("-s", required=False, type=int,  default=1, choices=[0,1,2,3], help="Split Str of reference and target files.[default: 1] \033[31mThey must have similary split str\033[0m\n0 -> \\t\n1 -> \\s+\n2 -> |\n3 -> ,")
    args = parser.parse_args()
    return args



def main(ref_f, ref_n, target_f, target_n, out_f, shared, sstr, f_title):
    """"""
    ref_dict = dict()
    f = open(ref_f, "r")
    for line in f:
        line_split = re.split(sstr, line.strip("\n"))
        ref_dict[line_split[ref_n-1]] = 1
    f.close()
    
    fo = open(out_f, 'w') # 输出
    f = open(target_f, 'r') # 目标文件
    # 跳过行名
    while(f_title > 0):
        fo.write(f.readline()) # 将这些行写入到输出
        f_title -= 1
    if shared:
        for line in f:
            line_split = re.split(sstr, line.strip("\n"))
            if ref_dict.get(line_split[target_n - 1 ]):
                fo.write(line)
    else:
        for line in f:
            line_split = re.split(sstr, line.strip("\n"))
            if not ref_dict.get(line_split[target_n - 1 ]):
                fo.write(line)
    f.close()
    fo.close()
    

if __name__ == "__main__":
    args = get_args()
    sstr = {0:"\t", 1:"\s+", 2:"\|", 3:","}[args.s]
    main(args.i, args.n, args.I, args.N, args.o, args.w, sstr, args.skip)


