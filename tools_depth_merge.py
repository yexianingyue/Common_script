#!/share/data1/software/miniconda3/bin/python
# -*- encoding: utf-8 -*-
##########################################################
# Creater       :  夜下凝月
# Created  date :  2024-09-18, 15:24:14
# Modiffed date :  2024-09-18, 15:24:14
##########################################################

import logging
import argparse
import random
import re
import os
import tarfile


# ANSI 转义序列定义颜色
class ColoredFormatter(logging.Formatter):

    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    RESET = "\033[0m"

    # 定义颜色
    BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE = range(30, 38)

    RESET_SEQ = "\033[0m"
    COLOR_SEQ = "\033[1;%dm"

    # 定义日志级别与颜色的映射
    LEVEL_COLORS = {
        logging.DEBUG: CYAN,
        logging.INFO: GREEN,
        logging.WARNING: YELLOW,
        logging.ERROR: RED,
        logging.CRITICAL: MAGENTA,
    }


    def format(self, record):
        # 获取日志级别对应的颜色
        color = self.COLOR_SEQ % (self.LEVEL_COLORS.get(record.levelno, self.WHITE))
        # 格式化信息
        # message = super().format(record, datefmt='%m/%d/%Y %I:%M:%S %p')
        levelname = record.levelname

        colored_levelname = f"[{color}{levelname}{self.RESET_SEQ}]"
        record.levelname = colored_levelname
        message = super().format(record)
        record.levelname = levelname
        return message


def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class = argparse.RawTextHelpFormatter)
    parser.add_argument("-r", type=str, required=True, help="reference depths.")
    parser.add_argument("-d", nargs="+", type=str, required=True, help="other depths")
    parser.add_argument("-s", default=0, type=int, help="The number chosen at random.[default:0, means all.]")
    parser.add_argument("-o", default="/dev/stdout", type=str, help="output file. [STDOUT]")
    args = parser.parse_args()
    return args


def random_files(dfiles, ndepths):
    try:
        return random.sample(dfiles, ndepths)
    except Exception as e:
        logger.error(f"{e}")
        raise

def open_file(filename):
    logger.info(f"read file: {filename}")
    try:
        with open(filename, 'rb') as f:
            file_start = f.read(4)
    except Exception as e:
        logger.error(f"{e}")
        exit(127)

    ## gzip
    if file_start[:2] == b'\x1f\x8b':
        return gzip.open(filename, 'rt')

    # bzip
    elif file_start[:2] == b'BZ':
        return bz2.open(filename, 'rt')

    # zip
    elif file_start[:2] == b'PK':
        # Note: Zip files may contain multiple files, you need to handle that
        zf = zipfile.ZipFile(filename)
        # Here, we just return the first file in the zip
        first_file = zf.namelist()[0]
        return zf.open(first_file, 'r')
    # tar
    elif tarfile.is_tarfile(filename):
        return tarfile.open(filename, 'r')
    # 常规
    else:
        return open(filename, 'r')


def parse_file(inf, dep_avg, res_avg, ctg_order=[], ctg_len=[], name_order=False, file_name=""):
    try:
        inf.readline()
        for line in inf:
            name, ctg_l, tavg, _, var  = line.strip().split()
            try:
                dep_avg[name] += float(tavg)
                res_avg[name] += f"\t{tavg}\t{var}"
            except:
                dep_avg[name] = float(tavg)
                res_avg[name] = f"\t{tavg}\t{var}"
            if name_order:
                ctg_order.append(name)
                ctg_len.append(int(float(ctg_l))) # 因为JGI软件出来的数字，有可能是科学计数法
    except:
        logger.error(f"{file_name}: {name}\n{line.strip()}")
        raise
    finally:
        inf.close()


def main(dref, dfiles, outf):

    logger.info(f"<<<<< Read references file >>>>>")
    ref = open_file(dref)
    dep_avg = {} # {ctg: sum(dep1, dep2, dep3, dep4, ...) }
    res_avg = {} # {ctg: "dep1\tvar1\tdep2\tvar2\tdep3\tvar3..."}
    ctg_order = []
    ctg_len = []
    title = ['contigName','contigLen','totalAvgDepth']
    
    # 解析参考文件
    parse_file(ref, dep_avg, res_avg, ctg_order, ctg_len, True, file_name=dref)
    name = re.sub('.*/', '', dref)
    title.append(f"{name}\t{name}-var")

    logger.info(f"<<<<< Read other depths >>>>>")
    for dfile in dfiles:
        f = open_file(dfile)
        name = re.sub('.*/', '', dfile)
        title.append(f"{name}\t{name}-var")
        parse_file(f, dep_avg, res_avg, name_order=False, file_name=dfile)

    ndepths = len(dfiles) + 1 # 随机选择的加上参考的
    res = '\t'.join(title) + "\n"
    for index, ctg in enumerate(ctg_order):
        total_avg = dep_avg[ctg] / ndepths
        res += f"{ctg}\t{ctg_len[index]}\t{total_avg}{res_avg[ctg]}\n"

    logger.info(f"save results to {outf}.")
    with open(outf, 'w') as f:
        f.write(res)


if __name__ == "__main__":
    logger = logging.getLogger(__name__)

    # 创建日志记录器
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)

    # 创建控制台处理器
    ch = logging.StreamHandler()

    # 定义日志输出格式
    formatter = ColoredFormatter("%(asctime)s - %(levelname)s - %(message)s", datefmt= "%Y-%m-%d %H:%M:%S")
    ch.setFormatter(formatter)

    # 添加处理器到记录器
    logger.addHandler(ch)



    args = get_args()
    dfiles = args.d
    if args.s:
        dfiles = random_files(dfiles, args.s)
    main(args.r, dfiles, args.o)
    

