#!/share/data1/software/miniconda3/bin/python3
import sys
import json
import argparse

def put_leaf(target, obj):
    if not target.get(obj):
        target[obj] = {}
    return(target[obj])


def build_newick_v1(node):
    children = list(node.values())
    if len(children) == 0:
        return ''
    elif len(children) == 1:
        return '(' + build_newick(children[0]) + ')'
    else:
        subtrees = [build_newick(child) for child in children]
        return '(' + ','.join(filter(None, subtrees)) + ')'

def build_newick_v2(node):
    # 如果节点是空字典，返回空字符串
    if not isinstance(node, dict) or len(node) == 0:
        return ''

    # 处理每一个子节点
    subtrees = []
    for key, child in node.items():
        subtree = build_newick(child)
        if subtree:
            # 如果子树非空，将节点名称和子树拼接
            subtree = '({}){}'.format(subtree, key)
        else:
            # 如果子树为空，即是叶节点，直接返回节点名称
            subtree = key
        subtrees.append(subtree)

    # 以逗号为分隔，将所有子树拼接起来
    return ','.join(subtrees)

def build_newick(node, branch_length=1):
    # 如果节点是空字典，返回空字符串
    if not isinstance(node, dict) or len(node) == 0:
        return ''

    # 处理每一个子节点
    subtrees = []
    for key, child in node.items():
        subtree = build_newick(child, branch_length)
        if subtree:
            # 如果子树非空，将节点名称和子树拼接
            subtree = '({}){}:{}'.format(subtree, key, branch_length)
        else:
            # 如果子树为空，即是叶节点，直接返回节点名称
            subtree = '{}:{}'.format(key, branch_length)
        subtrees.append(subtree)

    # 以逗号为分隔，将所有子树拼接起来
    return ','.join(subtrees)



def main(inf, outf, sstr = "|"):
    res = {}
    k1,k2 = False, False
    f = open(inf, 'r')
    for line in f:
        line_split = line.strip().split(sstr)
        if "(" in line:
            k1 = True
            line_split = [x.replace("(", "{").replace(")", "}") for x in line_split]
        if "[" in line:
            k2 = True
            line_split = [x.replace("[", "{").replace("]", "}") for x in line_split]
        if not res.get(line_split[0]):
            res[line_split[0]] = {}
        tmp_dic = res
        for tax in line_split:
            tmp_dic = put_leaf(tmp_dic, tax)
    f.close()

    if len(res) != 1:
        resf = {'zy_root':{}}
        for k,v in res.items():
            resf['zy_root'][k] = v
        res = resf

    O = open(outf, 'w')

    # 构建Newick字符串并添加一个结束符号
    newick_str = build_newick(res, 1) + ';'
    if k1:
        print("\t\n\t里面有小括号，改成了花括号。后续注意名字!!!!!!!!!\n\n")

    if k2:
        print("\t\n\t里面有括中号，改成了花括号。后续注意名字!!!!!!!!!\n\n")

    # 打印Newick字符串
    O.write(newick_str)
    O.close()

__doc__ = '''
Description:\t使用具有分类的列表来构建nwk文件
\t\tA|B|C|D
\t\tA|B|C|E
\t\tA|B|F|G
\t\tA|H|I|J
'''
def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('i', metavar='input', type=str, help='Input file')
    parser.add_argument('o', metavar='output', type=str, help='output file')
    parser.add_argument('-s', metavar='split str', type=str, default='1', help='split str.\n0 -> \\t\n1 -> | (\033[32mdefalut\033[0m)\n2 -> ;\n')
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = get_args()
    inf = args.i
    outf = args.o
    sstr = {'0':'\t', '1':'|', '2':';'}.get(args.s)
    main(inf, outf, sstr)

