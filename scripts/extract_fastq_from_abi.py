#!/share/data1/software/miniconda3/bin/python3
from Bio import SeqIO
import gzip
import argparse

def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-i", help='abi file or ab1 file')
    parser.add_argument("-o", help="output fastq")
    parser.add_argument("--fl", default=0, type=int, help="cut start len")
    parser.add_argument("--rl", default=0, type=int, help="cut end len")
    args = parser.parse_args()
    return args

def main(args):
    inf = args.i
    outf = args.o
    fl = args.fl # 删除前端多少个碱基
    rl = args.rl # 删除后端多少个碱基

    for record in SeqIO.parse(inf, 'abi'):
        qs = record.letter_annotations["phred_quality"]
        seq = record.seq
        seql = len(seq)
        cutl = seql - rl
        seq = seq[fl:cutl]
        qs = qs[fl:cutl]
        ascii_qs = ''.join(chr(q + 33) for q in qs)
        res = f"@{record.name}\n{seq}\n+\n{ascii_qs}\n"

    with gzip.open(f"{outf}.gz", 'wt', encoding='utf-8') as f:
        f.write(res)

if __name__ == "__main__":
    args = get_args()
    main(args)



