#!/share/data1/software/miniconda3/bin/python
import pandas as pd
import numpy as np
import argparse
import sys
from multiprocessing  import Process, Manager
from concurrent.futures import ProcessPoolExecutor, as_completed
import logging

__doc__ = """
归一化profile， 抽平样本reads数目,抽平的reads数由脚本自己取最小值
表中数据将被转为整数

下个版本：
    如果采样数据超过了原始数据的一般，那么使用掩码的方式，采样较小的，然后从原始数据剔除就可以
"""

def get_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("i", help="profile")
    parser.add_argument("o", help="output")
    parser.add_argument("-t", default=10, type=int, help="threads. (default:10)")
    parser.add_argument("-seed", type=int, help="seed")
    parser.add_argument("-min", default=None, type=int, help="min reads")
    parser.add_argument("--delete", action='store_true', help="如果列和小于-min,是否删除")
    args = parser.parse_args()
    return args

def process(name, counts, label, Min_num, seed, results, delete=False):
    np.random.seed(seed)
    if np.sum(counts) >= Min_num:
        temp1 = np.random.choice(np.repeat(label, counts),Min_num, replace=False)
        temp1 = pd.DataFrame(temp1)[0].value_counts()
        temp1 = pd.DataFrame(temp1)
        temp1.columns = [name]
    elif delete:
        return None
    else:
        temp1 = pd.DataFrame({name: counts}, index=label)
    results.append(temp1)


def main(args):
    inf = args.i
    outf = args.o
    Min_num = args.min
    seed = args.seed
    delete = args.delete
    num_process = args.t

    logging.info(f"read file: {inf}")
    df = pd.read_csv(inf, sep="\t", index_col=0, header=0).astype(int)
    if not Min_num:
        Min_num = df.sum().min()

    col_names = df.columns
    INDEX = df.index

    manager = Manager()
    results = manager.list()

    with ProcessPoolExecutor(max_workers=num_process) as executor:
        futures = {executor.submit(process, sample, df[sample].values, INDEX, Min_num, seed, results, delete): sample for sample in col_names}

        completed_count = 0
        for completed_future in as_completed(futures):
            try:
                completed_future.result()  # 确保任务完成

                completed_count += 1
                sys.stdout.write(f"\rprocessed: {completed_count}")
                sys.stdout.flush()  # 刷新输出

            except Exception as e:
                logging.error(e)
    print("")
    result = pd.concat(results, join='outer', axis=1).fillna(0).astype(int)
    result.to_csv(outf, sep="\t")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
    args = get_args()
    main(args)


