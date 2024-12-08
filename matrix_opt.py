#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-10-18, 16:23:45
# Modiffed date :  2023-10-18, 16:23:45
##########################################################

'''
Version : V1

分组和名字相同时，只会在最后提醒，但不会报错

Tips:
    对于group文件，name - group必须是一一对应，如果一个name分给了多个分组，暂时只解析最后一个
    If names are not found in the group file, it will be classified as unknown.
    分组和名字相同时，只会在最后提醒，但不会报错

group:
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
import statistics as stat
from fractions import Fraction as frac
import re,gzip,bz2

def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-i", metavar="Matrix", required=True, help="Input matrix")
    parser.add_argument("-g", metavar="group file", required=True, help="Input group")
    parser.add_argument("-N", metavar="Name col", default = 1, type=int, help="The ID's columns in group [default: 1]")
    parser.add_argument("-G", metavar="Group col", default = 2, type=int, help="The group's columns in group file [default: 2]")
    parser.add_argument("-o", metavar="output", required=True, help="Output matrix")
    parser.add_argument("--skip", metavar="header/index", default=1, type=int,help="skip header/index. [default: 1]")
    parser.add_argument("--split", required=False, type=int,  default=1, choices=[0,1,2,3], help="Split Str fo matrix and group.[default: 1] \033[31mThey must have similary split str\033[0m\n0 -> \\t\n1 -> \\s+\n2 -> |\n3 -> ,")
    parser.add_argument("--axis", metavar="Axis", required=False, type=str, default="col", choices=['col', 'row'], help="针对哪个轴进行合并")
    parser.add_argument('--format', metavar='format',type=str, default='float', choices=['int', 'float', 'fraction', 'str'], help='\033[31mdata format. [int, fraction, float:default]\033[0m')
    parser.add_argument('--method', metavar='method',type=str, default='sum', choices=['sum', 'mean', 'max', 'min','median'], help='\033[31mdata format. [mean, max, min, median, sum:default]\033[0m')
    parser.add_argument('--rename', metavar='test',type=str, default='sum', choices=['sum', 'mean', 'max', 'min','median'], help='\033[31mdata format. [mean, max, min, median, sum:default]\033[0m')
    args = parser.parse_args()
    return args

def parse_group(file_, GRP_dict, GRP_order, sstr, N, G):
    '''
    '''
    f = open_file(file_)
    tmp = {}

    for line in f:
        line_split = re.split(sstr, line.strip("\n"))
        name = line_split[N]
        group = line_split[G]
        if not tmp.get(group):
            GRP_order.append(group)
            tmp[group] = 1
        try:
            GRP_dict[name] = group
        except:
            print(line_split)
            print(line)
            exit(0)
    f.close()


def judge(x):
    '''
    判断是否是可计算数值: fraction, float, int
    '''
    #if re.match("[-]inf", x, re.I) # python 中的无穷值是否要跳过
    #    return False
    try:
        float(x)
        return True
    except:
        return False

def open_file(file_):
    if re.search(".gz$", file_):
        f = gzip.open(file_, 'rt')
    elif re.search(".bz2$", file_):
        f = bz2.open(file_,'rt')
    else:
        f = open(file_, 'r')
    return(f)


def parse_title(title:list, GRP_dict, GRP_order):
    '''
    return:
        { group: [index1, index2,...], ...} # 每个人分包含的列
    '''
    group_index = {} # {group1: [index1, index2, ...]}
    x = 0
    for i,v in enumerate(title):
        try:
            group = GRP_dict[v]
        except:
            print(f"\033[31m{v}\033[0m can't find in group file, it will be changed to unknown.")
            group = 'unknown'
            if x == 0:
                GRP_order.append(group)
                x = 1
        if not group_index.get(group):
            group_index[group] = [i]
            continue
        else:
            group_index[group].append(i)
    return(group_index)



def opt_col(file_, sstr, osstr, output_file, skip_index, format_function, method):
    '''
    按列分组
    '''
    global GRP_dict # 分组信息
    global GRP_order # 分组顺序


    f = open_file(file_)
    of = open(output_file, 'w')

    # process title
    title = f.readline()
    title_split = re.split(sstr, title.strip("\n"))
    title_name = osstr.join(title_split[0: skip_index])
    title_value = title_split[skip_index: ]
    group_index = parse_title(title_value, GRP_dict, GRP_order)
    title = osstr.join(GRP_order)
    of.write(f"{title_name}\t{title}\n")

    for line in f:
        line_split = re.split(sstr, line.strip("\n"))
        name = osstr.join(line_split[0: skip_index])
        value = line_split[skip_index: ]

        tmp_result = [name,]
        for grp in GRP_order:
            tmp = []
            for i in group_index[grp]:
                tmp.append(value[i])
            j = method([ format_function(x) for x in tmp])
            tmp_result.append(str(j))

        tmp_line = osstr.join(tmp_result)
        of.write(f"{tmp_line}\n")
    of.close()



def opt_row(file_, sstr, osstr, output_file, title, format_function, method):
    '''
    按行分组
    '''
    global GRP_dict # 分组信息
    global GRP_order # 分组顺序

    result = {}
    ngs = {}

    f = open_file(file_)
    of = open(output_file, 'w')

    for _ in range(0,title):
        of.write(f.readline())

    for line in f:
        line_split = re.split(sstr, line.strip("\n"))
        name = line_split[0]
        try:
            group = GRP_dict[name]
        except: 
            print(f"\033[31m{name}\033[0m can't find in group file, it will be changed to unknown.")
            group = 'unknown'

        if not result.get(group):
            result[group] = [ [ format_function(x) ] for x in line_split[1:]]
            continue
        num = [ format_function(x) for x in line_split[1:]] # 数据类型转换
        for i,v in enumerate(num):
            result[group][i].append(v)

    f.close()

    for k, v in result.items():
        tmp_str = osstr.join([ str(method(x)) for x in v ])
        of.write(f"{k}{osstr}{tmp_str}\n")
    of.close()


if __name__ == "__main__":
    args = get_args()

    GRP_dict = {} # {name1:group1, name2:group2, name3:group3, ...}
    GRP_order = []

    sstr  = {0:"\t", 1:"\s+", 2:"\|", 3:","}[args.split]
    osstr = {0:"\t", 1:"\t", 2:"|", 3:","}[args.split]

    format_dict = {'int':int, 'float':float, 'fraction':frac, 'str':str}
    format_function = format_dict[args.format]

    methods = {'mean': stat.fmean, 'median': stat.median, 'max':max, 'min':min, 'sum':stat.fsum}
    method = methods[args.method]

    if args.N < 0 or args.G < 0:
        print("Plese check Your parameter -N -G, they must >= 1")
        exit(127)

    N = args.N - 1 
    G = args.G - 1 

    parse_group(args.g, GRP_dict, GRP_order, sstr, N, G)

    main = {'col':opt_col, 'row': opt_row}[args.axis]
    main(args.i, sstr, osstr, args.o, args.skip, format_function, method)

    if args.N == args.G < 0:
        print(f"\033[40;31mYour name and group is equal -> {args.G}\033[0m")
