#!/usr/bin/bash
set -euo pipefail

green='\033[0;32m'
red='\033[0;31m'
gray='\033[1;30m'
yellow='\033[0;33m'
nc='\033[0m'



## run config
THREADS=8
MODE="all"
NREADS=10000
CUTOFF=5

usage() {
    cont=$(cat << EOF
    ${green}Usage:${nc}

    ${green}$0${nc} <output> <index> <input> [options]

    ${yellow}Description:${nc}
    Filter and process sequencing reads, with optional automatic length filtering.

    ${yellow}Required:${nc}
    <output>              Output path (file)
    <index>               bowtie2 index
    <input>               Input fastq file(s)

    ${yellow}Options:${nc}

    -u, --nreads          head N[${green}${NREADS}${nc}] reads to test. ∈ [1,+∞]
    -c, --cutoff          cutoff[${green}${CUTOFF}${nc}]%. ∈ [0, 100]

    -m, --mode            {all, test, auto}
                          auto: Smart sampling mode
                                    Subsample the first N[${green}${NREADS}${nc}] reads and align them to the host index.
                                        - If reads mapping rate > cutoff ${green}${CUTOFF}${nc}%, perform full host removal on the entire dataset.
                                        - if ≤ threshold, skip full alignment and output original reads unchanged.
                          test: only use head N[${green}${NREADS}${nc}] reads to run. 

                          all[${green}default${nc}]:  Alignment all reads to host index default

    -p, --threads <int>   Number of parallel threads (default: ${green}${THREADS}${nc})

EOF
)
    echo -e "\n$cont\n\n";
}


positional=()
while [[ $# -gt 0 ]];do
    case $1 in
        -u|--nreads)    NREADS=$2; shift 2 ;;
        -c|--cutoff)    CUTOFF=$2; shift 2 ;;
        -m|--mode)      MODE=$2; shift 2 ;;
        -p|--threads)   THREADS=$2; shift 2 ;;
        -h|--help)      usage; exit 0 ;;
        --)             shift; break ;;
        -*|--*)         echo "Unknown params $1"; exit 1 ;;
        *)              positional+=("$1"); shift ;;
    esac
done

# set -- "${positional[@]}" "$@"
set -- ${positional+"${positional[@]}"} "$@"

(( $# < 3 )) && { usage; exit 1; } 

out=$(realpath -sm "$1")
index=$(realpath -sm "$2")
fq1=$(realpath -sm "$3")
fq2=""
finished=0
paired=0 # 默认是单端



[ ! -f ${fq1} ] && { echo "No such file: $fq1"; exit 127; }

if [ $# -eq 4 ];then
    paired=1
    fq2=$(realpath -sm "$4")
    [ ! -f ${fq2} ] && { echo "No such file: $fq2"; exit 127; }
fi


[[ $NREADS =~ ^[1-9][0-9]*$ ]] || { echo "nreads must be positive integer"; exit 1; }
[[ $CUTOFF =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "cutoff must be number"; exit 1; }

# ─── statfile ───
tmplock_file="${out}.tmplock"
ok_file="${out}.ok"
error_file="${out}.error"
run_log="${out}.run.log"


run_check(){
    [[ -f "$tmplock_file" ]] && { echo "running."; exit 127; }

    rm -f "$error_file" "$ok_file" 2> /dev/null
    touch "$tmplock_file" 2>/dev/null || { echo -e "can't touch file $tmplock_file" >&2; exit 1; }
}

run_error() {
    local msg="$1"
    rm -f "$tmplock_file" 2>/dev/null
    echo "$msg" > "$error_file"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $msg" >> "$run_log"
    echo -e "${red}$msg${nc}" >&2
    exit 1
}

run_end(){
    rm -f "$tmplock_file" 2> /dev/null       # 删除中间文件
    touch "$ok_file"  2> /dev/null              # 创建 ok 文件
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Script finished successfully" >> "$run_log"
}


run_start(){
    run_check
    # 初始化 run.log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Script started" > "$run_log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Mode: $MODE" >> "$run_log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Index: $index" >> "$run_log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Input: $fq1 ${fq2:+and $fq2}" >> "$run_log"
    echo "" >> "$run_log"
}


run_start

run_trap(){
    rm -f "$tmplock_file" 2>/dev/null;
    if (( ! finished )); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Script interrupted by signal" >> "$run_log"
    fi
}

trap run_trap EXIT INT TERM


# ─── 运行函数 ───
run_bowtie() {
    local mode="$1"
    local log_file="${out}.nohost.log"
    local un_prefix="${out}.nohost"

    bt2=(bowtie2 --end-to-end --fast --mm -x "$index" -p "$THREADS" --no-head )

    [[ $mode != "all" ]] && { bt2+=( -u "$NREADS"); }


    if (( paired )); then
        "${bt2[@]}" \
            -1 "$fq1" -2 "$fq2" \
            --un-conc-gz "${un_prefix}.fq.gz"  -S /dev/null 2> "$log_file" || run_error "run bowtie2"

        mv "${un_prefix}.fq.1.gz" "${un_prefix}.1.fq.gz" 2>/dev/null || true
        mv "${un_prefix}.fq.2.gz" "${un_prefix}.2.fq.gz" 2>/dev/null || true

    else
        "${bt2[@]}" \
            -U "$fq1" \
            --un-gz "${un_prefix}.fq.gz" \
            -S /dev/null 2> "$log_file" || run_error "run bowtie2"
    fi

    ## 提取map rate
    local rate
    rate=$(tail -n 1 "$log_file" | sed -E -n 's/^([0-9.]+)% overall alignment rate$/\1/p')

    if ! [[ "$rate" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        run_error "Failed to parse mapping rate from bowtie2 log"
    fi

    echo "${rate:0}"
}

maprate=$(run_bowtie "$MODE")

if [[ $MODE = "all" ]];then
    echo "Full de-hosting completed."
    run_end
    exit 0
elif [[ $MODE = "test" ]];then
    echo "test de-hosting completed."
    run_end
    exit 0
fi



### MODE == "auto"
## map rate和cutoff的关系
if (( $(echo "${maprate} > ${CUTOFF}"|bc -l) ));then
    echo "High host contamination detected → running full de-hosting"
    echo -e "curreut rate: $maprate%"
    echo -e "cutoff rate:  $CUTOFF%"

    rm -f "${out}.nohost.fq.gz" "${out}.nohost.1.fq.gz" "${out}.nohost.2.fq.gz" 2>/dev/null # 清理采样产生的文件
    maprate=$(run_bowtie "all")   # 重新跑全量
else
    echo "Low host content → copying original files"
    if (( paired ));then
        cp "${fq1}" "${out}.nohost.1.fq.gz" || run_error "cp ${fq1} failed"
        cp "${fq2}" "${out}.nohost.2.fq.gz" || run_error "cp ${fq2} failed"
    else
        cp "${fq1}" "${out}.nohost.fq.gz" || run_error "cp ${fq1} failed"
    fi
fi

run_end
