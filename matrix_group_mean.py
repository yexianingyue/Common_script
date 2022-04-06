#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
###########################################################
# Author:				ZhangYue
# Description:				See below
# Time:				2020年07月06日	 Monday
# ModiffTime:       2021年11月19日 星期五 16:01:20 CST
###########################################################
'''
Version : V3.0
组内运算

sum(names)/sqrt(len(names))

group: Must non header
    name_1  group_1     Group_A
    name_1  group_4     Group_B
    name_2  group_2     Group_C
    name_3  group_3     Group_A
    ...     ...         ...

matrix: Must have header
    tittle sample_1 sample_2    ...
    name_1  1       1           0
    name_2  0       1           2
    name_3  3       4           9
    ...     ...     ...         ...
'''
import  argparse
import re
import numpy as np
from math import sqrt 
from fractions import Fraction as frac

def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-i", metavar="Matrix", required=True, help="Input matrix")
    parser.add_argument("-g", metavar="group file", required=True, help="Input group")
    parser.add_argument("-V", metavar="Var col", default = 1, type=int, help="The ID's columns in group [default: 1]")
    parser.add_argument("-G", metavar="Group col", default = 2, type=int, help="The group's columns in group file [default: 2]")
    parser.add_argument("-o", metavar="output", required=True, help="Output matrix")
    parser.add_argument("-s", required=False, type=int,  default=1, choices=[0,1,2,3], help="Split Str fo matrix and group.[default: 1] \033[31mThey must have similary split str\033[0m\n0 -> \\t\n1 -> \\s+\n2 -> |\n3 -> ,")
    args = parser.parse_args()
    return args

def parse_group(file_, GRP, sstr, V, G):
    '''
    只是解析分组文件，{key: {taxo_1, taxo_2,...}, ...}
    '''
    f = open(file_, 'r')
    for line in f:
        # 去除空行
        if re.match(r"^\s+$|^$", line.strip()):
            continue
        line_split = re.split(sstr, line.strip())
        if GRP.get(line_split[V]):
            GRP[line_split[V]].update({line_split[G]})
            continue
        GRP[line_split[V]] = {line_split[G]}
    f.close()

def judge(x):
    '''
    判断是否是数字
    '''
    #if re.match("[-]inf", x, re.I) # python 中的无穷值是否要跳过
    #    return False
    try:
        float(x)
        return True
    except:
        return False


def main(file_, sstr, output_file):
    result = {} 
    f = open(file_, 'r')
    tittle = f.readline()
    ngs = {}

    for line in f:
        line_split = re.split(sstr, line.strip())
        name = line_split[0]
        try:
            groups = GRP[name] # 将名字转为分组 这边得到一个set，后面需要循环才行_
        except:
            groups = {'unknown'}
            print(f"\033[31m{name}\033[0m can't find in group file.")
        ngroup = groups.__len__() # 有多少分组，就分为多少分组
        # 格式化每一行的数据
        # num = [float(x) for x in line_split[1:]] # 如果需要整数，此处改为int即可
        # ngs = [map(lambda x, y: x+1 if judge(y) else x, ngs, line_split[1:])]
        num = list(map(lambda x: float(x) if judge(x) else 0, line_split[1:])) # 如果需要整数，此处改为int即可
        ngs_value = list(map(lambda y: 1 if judge(y) else 0, line_split[1:]))
        for group in groups:
            if result.get(group):
                result[group] = list(map(lambda x, y: x + y if judge(y) else x, result[group], num)) # ！！！！！！！！！！！这边不需要赋值，因为赋值会得到空值原理不清楚
                ngs[group] = list(map(lambda x, y: x+y , ngs[group], ngs_value))
            else:
                ngs[group] = ngs_value
                result[group] =  num
    f.close()
    # ngs = [sqrt(x) for x in ngs]
    for k, v in ngs.items():
        ngs[k] = np.sqrt(v)

    with open(output_file, 'w', encoding="utf-8") as f:
        if sstr in ["|", "\s+"]:
            sstr = "\t"
        f.write(tittle)
        for k,v in result.items():
            # v = [map(lambda x, y: x/y, v, ngs)]
            v = np.array(v)/ngs[k]
            f.write(f"{k}")
            for n in v:
                #  n = float(n)
                f.write(f"{sstr}{n}")
            f.write("\n")


if __name__ == "__main__":
    args = get_args()
    GRP = {}
    sstr = {0:"\t", 1:"\s+", 2:"\|", 3:","}[args.s]
    if args.V < 0 or args.G < 0:
        print("Plese check Your parameter -V -G, they must >= 1")
        exit(127)
    V = args.V - 1 
    G = args.G - 1 
    parse_group(args.g, GRP, sstr, V, G)
    main(args.i, sstr, args.o)
    if args.V == args.G:
        print("Your parameter -V -G are equal!!!")
