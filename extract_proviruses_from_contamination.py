#!/share/data1/software/miniconda3/bin/python
from Bio import SeqIO
import sys
import re
import argparse

import gzip
import bz2
import zipfile
import tarfile
import logging

RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
RESET = "\033[0m"


# ANSI 转义序列定义颜色
class ColoredFormatter(logging.Formatter):
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


def get_args():
    parser = argparse.ArgumentParser(description = __doc__, formatter_class = argparse.RawTextHelpFormatter)
    parser.add_argument("i", metavar="", help="contamination.tsv")
    parser.add_argument("fasta", metavar="", help="virus.fa")
    parser.add_argument("o", metavar="", help="output")
    parser.add_argument("-l", metavar="minLen", default=0, type=int, help="嵌合病毒的最小长度.(default: 0)")
    parser.add_argument("-L", metavar="minLen", default=0, type=int, help="嵌合病毒的最大长度.(default: 0, means not limit.)")
    args = parser.parse_args()
    return(args)

def read_file(filename):
    logger.info(f"read file: {filename}")
    # Read the first few bytes to identify the file type
    with open(filename, 'rb') as f:
        file_start = f.read(4)

    # Gzip files start with the bytes 0x1F 0x8B
    if file_start[:2] == b'\x1f\x8b':
        return gzip.open(filename, 'rt')

    # Bzip2 files start with the bytes 0x42 0x5A
    elif file_start[:2] == b'BZ':
        return bz2.open(filename, 'rt')

    # Zip files start with the bytes 0x50 0x4B
    elif file_start[:2] == b'PK':
        # Note: Zip files may contain multiple files, you need to handle that
        zf = zipfile.ZipFile(filename)
        # Here, we just return the first file in the zip
        first_file = zf.namelist()[0]
        return zf.open(first_file, 'r')

    # Tar files start with specific headers that are more complex to detect
    # but often have extensions .tar, .tar.gz, .tar.bz2, etc.
    elif tarfile.is_tarfile(filename):
        return tarfile.open(filename, 'r')

    # If the file is not compressed, open it normally
    else:
        return open(filename, 'r')



def parse_tsv(filename, proviruses, ctg_length, minLen=0, maxLen=0):
    f = read_file(filename)
    logger.info(f"parse file: {filename}")
    for line in f:
        count = 1
        line_split = re.split("\t", line.strip())
        name = line_split[0]
        length = line_split[1]
        if line_split[5] == "Yes":
            types = re.split(",", line_split[8])
            regions = re.split(",", line_split[10])
            # 循环类型
            temp = []
            for i, v in enumerate(types):
                if v == "viral":
                    region = regions[i]
                    reg = [ int(x) for x in re.split("-", region)]
                    reg_len = reg[1] - reg[0]
                    if reg_len < minLen:
                        continue
                    if maxLen !=0 and reg_len > maxLen:
                        continue
                    try:
                        temp.append(reg)
                    except:
                        print(line)
                        print(reg)
                        print(temp)
                        exit(0)
            proviruses[name] = temp
            ctg_length[name] = length
    f.close()



def main(args):

    proviruses = dict()
    ctg_length = dict()

    minLen = args.l
    maxLen = args.L

    parse_tsv(args.i, proviruses, ctg_length, minLen, maxLen)


    if len(ctg_length) == 0:
        logger.warning(f"No targets match the conditions. [{minLen} < length < {maxLen}]")
        exit(0)

    outf = open(args.o, 'w')


    seq_file = read_file(args.fasta)
    logger.info(f"extract virus from file: {args.fasta}")
    for seq in SeqIO.parse(seq_file, 'fasta'):
        if ctg_length.get(seq.id):
            regions = proviruses[seq.id]
            for i,reg in enumerate(regions): 
                outf.write(f">{seq.id}_{i+1} {reg[0]}-{reg[1]}/{ctg_length[seq.id]}\n")
                outf.write(str(seq.seq[ reg[0] - 1 : reg[1] ]))
                outf.write("\n")
    outf.close()


if __name__ == "__main__":
    args = get_args()
    main(args)

