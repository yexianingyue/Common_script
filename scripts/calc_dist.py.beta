#!/share/data1/software/miniconda3/envs/bio38/bin/python3
# -*- encoding:utf-8 -*-

from concurrent.futures import ProcessPoolExecutor, as_completed, ThreadPoolExecutor
from multiprocessing import Manager, shared_memory, Pool, cpu_count
import threading
import time
import logging
from scipy.spatial.distance import cdist
import numpy as np
import pandas as pd
import argparse
import os
import math

# 定义颜色
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
GRAY = "\033[2m"
RESET = "\033[0m"  # 重置为默认颜色

dist_meths = ['braycurtis', 'canberra', 'chebyshev', 'cityblock', 'correlation',
              'cosine', 'dice', 'euclidean', 'hamming', 'jaccard', 'jensenshannon',
              'kulczynski1', 'mahalanobis', 'matching', 'minkowski','rogerstanimoto',
              'russellrao', 'seuclidean', 'sokalmichener','sokalsneath', 'sqeuclidean', 'yule']

methods_text = "\n".join(f"- {method}" for method in dist_meths[1:])


meths_binary = ['dice', 'hamming','jaccard', 'kulczynski1', 'matching', 'rogerstanimoto','sokalmichener','sokalsneath','yule']
meths_non_negative = ['braycurtis','jensenshannon','canberra','cosine']
meths_continues = ['mahalanobis','minkowski','seuclidean']


__doc__ = f'''
{GREEN}提示：{RED}脚本会检查输入的数据是否是二进制数据,如果不是，则会将数字自动转为二进制
    对于需要非负数的距离，脚本只进行检查，不进行处理，但不会检查是否是连续变量，所以在输入时请自行检查.
    
{GREEN}输入数据格式要求:{RESET}

    {YELLOW}1. 二进制数据 (0/1): {RESET}
       - {meths_binary}

    {YELLOW}2. 非负数:{RESET}
       - {meths_non_negative}

    {YELLOW}3. 连续数值{RESET}:
        - {meths_continues}
'''


class CustomHelpFormatter(argparse.RawTextHelpFormatter):

    def _format_action(self, action):
        # 调整每个动作的格式，并添加额外的空行
        parts = super()._format_action(action)
        # 检查参数是否是可选的（required=False）
        # if not action.required:
             # 将可选参数的描述中的 "required=False" 部分设置为灰色
             # parts = f"{GRAY}{parts}{RESET}"
        return parts + '\n'  # 在每个动作后添加一个空行


def get_args():
    # parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    default = f"{GREEN}default{RESET}"
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=CustomHelpFormatter)
    parser.add_argument("-i", metavar="matrix_1", required=True, type=str, help="Input data1")
    parser.add_argument("-I", metavar="matrix_2", required=False, type=str, help=f"Input data2. ({GREEN}Option{RESET})")
    parser.add_argument("-o", metavar="out", required=True, type=str, help="Output")
    parser.add_argument("-t1", metavar="title", default='T', choices=['T','F'], type=str, help=f"data1是否有列名(F/T:{default})")
    parser.add_argument("-t2", metavar="title", default='T', choices=['T','F'], type=str, help=f"data2是否有列名(F/T:{default})")
    parser.add_argument("-M",metavar="Method",required=False, default="braycurtis", choices=dist_meths, type=str, help=f"- braycurtis ({default})\n{methods_text}")
    parser.add_argument("-s", required=False, type=int,  default=1, choices=[0,1,2,3], help=f"Split Str fo matrix.\n0 -> \\s+\n1 -> \\t ({default})\n2 -> |\n3 -> ,")
    parser.add_argument("--skip1", type=int, default=0, help=f"data1 忽略前多少行(0: {default}).")
    parser.add_argument("--skip2", type=int, default=0, help=f"data2 忽略前多少行(0: {default}).")
    parser.add_argument("--threads", metavar="threads", type=int, default=10, help=f"Number of threads.（0: {default}）")
    parser.add_argument("--axis", metavar="", default="row", type=str, help=f"by col/row: {default}.")
    args = parser.parse_args()
    return args


def calc_dist(args):
    start1, end1, shared_mem_name1, shared_mem_name2, shared_mem_name_result, shape1, shape2, method = args
    st = time.time()
    try:
        # 从共享内存中读取 df1、df2 和结果矩阵
        shm_df1 = shared_memory.SharedMemory(name=shared_mem_name1)
        shm_df2 = shared_memory.SharedMemory(name=shared_mem_name2)
        shm_result = shared_memory.SharedMemory(name=shared_mem_name_result)

        df1 = np.ndarray(shape1, dtype=np.float64, buffer=shm_df1.buf)
        df2 = np.ndarray(shape2, dtype=np.float64, buffer=shm_df2.buf)
        dists = np.ndarray((shape1[0], shape2[0]), dtype=np.float64, buffer=shm_result.buf)

        # 计算距离
        dists[start1:end1] = cdist(df1[start1:end1], df2, metric=method)


    except Exception as e:
        logging.error(f"Error {e}")
    
    logging.info(f"# {start1} - {end1}\t{time.time() - st} Sec.")


def read_file(inf, skp, sstr, title, axis, method):
    inf = os.path.abspath(f"{inf}") 
    logging.info(f"read file: {inf}")
    if title == "F":
        title=None
    else:
        title=0
    preview_df = pd.read_csv(inf, skiprows=skp, header=title, sep=sstr, index_col=0, nrows=2)
    column_names = preview_df.columns.tolist()

    # 根据这些列名，假设所有列都是 float64
    dtypes = {col: 'float64' for col in column_names}

    # 然后读取整个文件
    df = pd.read_csv(inf, skiprows=skp, header=title, sep=sstr, index_col=0, low_memory=False, dtype=dtypes)
    
    ##  针对特殊的距离方法，需要对数据处理
    if method in meths_binary:
        df = (df > 0).astype(int)
        logging.info("Covert data to binary data.")
    elif method in meths_non_negative:
        if df.min().any() < 0:
            logging.err(f"file: {inf}. Negative data inclusion")
            exit(127)


    ## 判断是否按行
    if axis == "col":
        df = df.T
    return df


def get_input_matrix(args):
    sstr = {0:"\s+", 1:"\t", 2:"\|", 3:","}[args.s]
    logging.info("## Step1: read data")
    logging.info(f"axis: {args.axis}")
    ## 读取文件
    df1 = read_file(args.i, args.skip1, sstr, args.t1, axis=args.axis, method=args.M)
    nf,ns = df1.shape
    if not args.I:
        df2 = df1
        logging.info("-"*50)
        logging.info(f"\tN_items\t\tN_features")
        logging.info(f"data\t{nf}\t\t{ns}")
    else:
        df2 = read_file(args.I, args.skip2, sstr, args.t2, axis=args.axis, method=args.M)
        df2 = df2.reindex(columns=df1.columns)
        nf2,ns2 = df2.shape
        logging.info("-"*50)
        logging.info(f"\tN_items\tN_features")
        logging.info(f"data1\t{nf}\t\t{ns}")
        logging.info(f"data2\t{nf2}\t\t{ns2}" )
    logging.info("-"*50)
    return df1, df2

def merge_results(db_name):
    # 从SQLite数据库中读取所有结果
    conn = sqlite3.connect(db_name)
    final_df = pd.read_sql_query("SELECT * FROM results", conn)
    conn.close()
    return final_df


def print_progress(progress, total):
    while True:
        current_progress = sum(progress)
        print(f"Total Progress: {current_progress}/{total}", end="\r")
        if current_progress >= total:
            print("\nMerged Data...")
            break
        time.sleep(1)

def main(args):
    
    outf = args.o
    
    ## get data1 and data2
    df1, df2 = get_input_matrix(args)
    
    ## dist method
    method = args.M
    logging.info(f"method: {method}")

    ## 多线程计算
    num_threads = args.threads

    ## 将data1分割成多份
    nf1 = df1.shape[0]
    step_size = math.ceil(nf1 / num_threads)
    loop_size = nf1 // step_size + (nf1 % step_size > 0)

    names1 = df1.index
    logging.info(f"actual: {num_threads}")

    
    # 将 DataFrame 转换为 numpy 数组
    df1_array = df1.to_numpy()
    df2_array = df2.to_numpy()

    # 创建共享内存，存储 df1、df2 和结果矩阵
    shm_df1 = shared_memory.SharedMemory(create=True, size=df1_array.nbytes)
    shm_df2 = shared_memory.SharedMemory(create=True, size=df2_array.nbytes)
    shm_result = shared_memory.SharedMemory(create=True, size=df1_array.shape[0] * df2_array.shape[0] * 8)  # 8 是 float64 的字节数

    # 将数据写入共享内存
    np_array_df1 = np.ndarray(df1_array.shape, dtype=df1_array.dtype, buffer=shm_df1.buf)
    np_array_df2 = np.ndarray(df2_array.shape, dtype=df2_array.dtype, buffer=shm_df2.buf)
    np_array_result = np.ndarray((df1_array.shape[0], df2_array.shape[0]), dtype=np.float64, buffer=shm_result.buf)

    np_array_df1[:] = df1_array[:]
    np_array_df2[:] = df2_array[:]

    tasks =  [(i * step_size, min((i + 1) * step_size, nf1), shm_df1.name, shm_df2.name, shm_result.name, df1_array.shape, df2_array.shape, method) for i in range(loop_size)]

     # 使用进程池并行处理
    with Pool(processes=num_threads) as pool:
        pool.map(calc_dist, tasks)
        

    logging.info("Combine ...")
    final_result = pd.DataFrame(np_array_result, index=df1.index, columns=df2.index)
    logging.info(f"Write result to {outf}.")
    final_result.to_csv(f"{outf}", sep="\t")
    logging.info(f"Release memaory.")
    
    # 释放共享内存
    shm_df1.close()
    shm_df2.close()
    shm_result.close()
    shm_df1.unlink()
    shm_df2.unlink()
    shm_result.unlink()
    
    logging.info("Done.")
    
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
    args = get_args()
    main(args)
    
    
