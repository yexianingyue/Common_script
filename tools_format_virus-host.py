#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-03-03, 11:47:39
# Modiffed date :  2023-03-03, 14:22:44
##########################################################

import argparse
import re
import sys
'''
格式花病毒分类及其宿主的脚本。
NOTE:
    如果一个病毒被分类到多个宿主，且这几个宿主属于不同的分类
    它则会被分为mutiple_taxo,你可以手动指定，例如:mutiple_genus, 
    mutiple_family, mutiple_phylum...
'''
def get_parameter():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-i", metavar="", required=True, help="The table contain viral and bacterial taxonomy.")
    parser.add_argument("-n", metavar="", type=int, default=1, help="The column in which the viral name.(default:1)")
    parser.add_argument("-t", metavar="", type=int, default=2, help="The column in which the virus is classified.(default:2)")
    parser.add_argument("-T", metavar="", type=int, default=3, help="The column in which the host is classified.(default:3)")
    parser.add_argument("-m", metavar="", type=str, default="mutiple_tax", help="the name that viral have mutiple host at the level you care.")
    parser.add_argument("-g", metavar="", type=int, default=None, help="The group column.(default:None)")
    parser.add_argument("-s", metavar="", required=False, type=int,  default=1, choices=[0,1,2,3], help="Split Str of Table .[default: 1]\n0 -> \\t\n1 -> \\s+\n2 -> |\n3 -> ,")
    args = parser.parse_args()
    return(args)

def process_group(in_f, vn, vt, bt, mn, sstr, g):
    '''
    vt -> which viral taxo; bt -> which bacterial taxo; mn -> mutiple_name; vn -> which viral name; g -> group
    '''
    result = dict()
    vb = dict()
    f = open(in_f, 'r')
    for line in f:
        line_split = re.split(sstr, line.strip("\n"))
        try:
            vnn, vtn, btn, gn = line_split[vn-1], line_split[vt-1], line_split[bt-1], line_split[g-1]
            if not vb.get(gn):
                vb[gn] = {}
                result[gn] = {}
            if vb.get(gn).get(vnn):
                vb[gn][vnn]["host_taxo"].update([btn])
            else:
                vb[gn][vnn] = {"host_taxo": {btn}, "viral_taxo": vtn}
        except:
            sys.stderr.write(f"\n")
            sys.stderr.write(str(line_split))
            sys.stderr.write(f"\n\033[31mthe line only have {len(line_split)} columns\033[0m, \033[1;33mplease check your parameter -t and -T \033[1m\n")
            exit(127)
    f.close()
    for k,v in vb.items():
        for i, j in v.items():
            if len(j['host_taxo']) > 1:
                tj = f"{j['viral_taxo']}\t{mn}"
            else:
                tj =f"{j['viral_taxo']}\t{j['host_taxo'].pop()}"
            if result.get(k).get(tj):
                result[k][tj] += 1
            else:
                result[k][tj] = 1
    for k, v in result.items():
        for i, j in v.items():
            print(f"{k}\t{i}\t{j}")


def process(in_f, vn, vt, bt, mn, sstr):
    '''
    vt -> which viral taxo; bt -> which bacterial taxo; mn -> mutiple_name; vn -> which viral name; g -> group
    '''
    result = dict()
    vb = dict()
    f = open(in_f, 'r')
    for line in f:
        line_split = re.split(sstr, line.strip("\n"))
        try:
            vnn, vtn, btn = line_split[vn-1], line_split[vt-1], line_split[bt-1]
            if vb.get(vnn):
                vb[vnn]["host_taxo"].update([btn])
            else:
                vb[vnn] = {"host_taxo": {btn}, "viral_taxo": vtn}
        except:
            sys.stderr.write(f"\n")
            sys.stderr.write(str(line_split))
            sys.stderr.write(f"\n\033[31mthe line only have {len(line_split)} columns\033[0m, \033[1;33mplease check your parameter -t and -T \033[1m\n")
    f.close()
    for k,v in vb.items():
        if len(v['host_taxo']) > 1:
            tk = f"{v['viral_taxo']}\t{mn}"
        else:
            tk =f"{v['viral_taxo']}\t{v['host_taxo'].pop()}"
        if result.get(tk):
            result[tk] += 1
        else:
            result[tk] = 1
    for k, v in result.items():
        print(f"{k}\t{v}")

if __name__ == "__main__":
    args = get_parameter()
    sstr = {0:"\t", 1:"\s+", 2:"\|", 3:","}[args.s]
    if args.g:
        process_group(args.i, args.n, args.t, args.T, args.m, sstr, args.g)
    else:
        process(args.i, args.n, args.t, args.T, args.m, sstr)
