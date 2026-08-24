#!/usr/bin/bash
##########################################################
# Creater       :  夜下凝月
# Created  date :  2023-08-10, 09:20:43
# Modiffed date :  2023-08-10, 09:20:43
##########################################################

echo -e "\n\n\t\033[5;33m使用example代替example.sh\033[0m\n\n"
       
declare -A eg_dict=(

["test"]=$(cat <<'EOF'
    version:\t\tv.0
    avaliable database:\ttest
    conda env:\t\ttest
    \033[31mcommon command:\033[0m\ttest

    ----------------------------
         << 其他相关命令 >>
    ----------------------------

EOF
)

#=======================================================
#               功能注释
#=======================================================

["arg"]=$(cat <<'EOF'
    version:\t\tv.0
    avaliable database:\t/share/data2/guorc/Database/DrugResistanceGene/v20240927
    conda env:\t\ttest
    \033[31mcommon command:\033[0m\ttest

    ----------------------------
         << 其他相关命令 >>
    ----------------------------

EOF
)


["pfam"]=$(cat <<'EOF'
    avaliable database:\t/share/data1/Database/Pfam/releases35/
    ----------------------------
         << 相关命令 >>
    ----------------------------
    ## 1.添加perl环境
    export PERL5LIB=/share/data1/software/PfamScan:/root/perl5/lib/perl5:$PERL5LIB

    ## 2.测试
    /usr/bin/perl /share/data1/software/PfamScan/pfam_scan.pl -cpu 14 -fasta <faa> -dir /share/data1/Database/Pfam/releases35/ -as  -outfile <out.pfam>

    ## 3.flow
    /share/data1/zhangy2/scripts/flow_pfam.sh <fasta> <out_dir> <out_prefix>

EOF
)

["cazy"]=$(cat <<'EOF'
    version:\t\tv.0
    avaliable database:\t/share/data1/Database/cazy/CAZyDB.07142024.dmnd
    conda env:\t\ttest
    \033[31mcommon command:\033[0m\tdiamond blastp --outfmt 6 --db /share/data1/Database/cazy/CAZyDB.07142024.dmnd -o <output_file> --quiet --query <input.faa> --query-cover 50 --min-score 60 -p 80

    ----------------------------
         << 其他相关命令 >>
    ----------------------------

EOF
)

["kegg"]=$(cat <<'EOF'
    version:\t\t20230401
    avaliable database:\t/share/data1/Database/KEGG/20230401/KEGG20230401.dmnd
    conda env:\t\tNone
    \033[31mcommon command:\033[0m\tdiamond blastp --outfmt 6 --db /share/data1/Database/KEGG/20230401/KEGG20230401.dmnd -o <output_file> --quiet --query <input.faa> --query-cover 50 --min-score 60 -p 80

    ----------------------------
         << 其他相关命令 >>
    ----------------------------

EOF
)


["eggnog"]=$(cat <<'EOF'
    version:\t\tv2.1.12
    avaliable database:\t/share/data1/Database/eggnog/
    conda env:\t\tsource activate /home/zhangy2/.conda/envs/eggnog.2.1.12
    \033[31mcommon command:\033[0m\temapper.py -i  <input.faa> --output <output_file> --data_dir /share/data1/Database/eggnog/

    ----------------------------
         << 其他相关命令 >>
    ----------------------------
    1、一般的默认注释参数：
    emapper.py --cpu 80 --data_dir /share/data1/Database/eggnog/  --output <output_file> -i  <input.faa> --temp_dir . --query_cover 50 --score 60

EOF
)



["gunc"]=$(cat <<'EOF'
    version:\t\t1.0.5
    avaliable database:\t/share/data1/Database/GUNC/gunc_db_progenomes2.1.dmnd
    conda env:\t\tsource activate /share/data1/software/miniconda3/envs/gunc
    \033[31mcommon command:\033[0m\tgunc run -r <database> -g -f <input.fa> -t <threads> -o <out_dir> -e <suffix>

    ----------------------------
         << 示例 >>
    ----------------------------
    source activate /share/data1/software/miniconda3/envs/gunc
    gunc run -r /share/data1/Database/GUNC/gunc_db_progenomes2.1.dmnd -g -f input.faa -t 10 -o myout.gunc -e .fa

EOF
)



["mafft"]=$(cat <<'EOF'
    version:\t\tv7.475

    ----------------------------
         << 其他相关命令 >>
    ----------------------------
    ## 1. mafft --clustalout --parttree --retree 2 --thread 10 input.fasta > out

EOF
)

["dvf"]=$(cat <<'EOF'
    version:\t\tv1.0
    avaliable database:\ttest
    conda env:\t\tsource activate /share/data1/software/miniconda3/envs/dvf
    \033[31mcommon command:\033[0m\tpython /share/data1/lvqb/software/DeepVirFinder/dvf.py -i <in.fa> -o <out.dir> -l <minLen> -c <Threads>

    ----------------------------
         << 其他相关命令 >>
    ----------------------------

EOF
)

["melonnpan"]=$(cat <<'EOF'
    version:\t\tv.0
    avaliable database:\ttest
    conda env:\t\t/share/data1/zhangy2/conda/envs/melonnpan
    \033[31mcommon command:\033[0m\ttest

    source activate /share/data1/zhangy2/conda/envs/melonnpan

    ----------------------------
         << 其他相关命令 >>
    ----------------------------

EOF
)

["color"]=$(cat <<'EOF'

    # 语法
    \e[31mThis text will be red.\e[0m\t\\e[31mThis text will be red.\\e[0m
    \e[32mThis text will be green.\e[0m\t\\e[32mThis text will be green.\\e[0m
    \e[33mThis text will be yellow.\e[0m\t\\e[33mThis text will be yellow.\\e[0m
    \e[34mThis text will be blue.\e[0m\t\\e[34mThis text will be blue.\\e[0m
    \e[35mThis text will be magenta.\e[0m\t\\e[35mThis text will be magenta.\\e[0m
    \e[36mThis text will be cyan.\e[0m\t\\e[36mThis text will be cyan.\\e[0m
    \e[37mThis text will be light gray.\e[0m\t\\e[37mThis text will be light gray.\\e[0m

    \e[1;31mThis text will be bold and red.\e[0m\t\\e[1;31mThis text will be bold and red.\\e[0m
    \e[5;31mThis text will be bold and red.\e[0m\t\\e[5;31mThis text will be bold and red.\\e[0m
    \e[1;5;31mThis text will be bold and red.\e[0m\t\\e[1;5;31mThis text will be bold and red.\\e[0m

    颜色编码表如下：

    30: Black (黑色)
    31: Red (红色)
    32: Green (绿色)
    33: Yellow (黄色)
    34: Blue (蓝色)
    35: Magenta (洋红/品红色)
    36: Cyan (青色)
    37: Light gray (浅灰色)
    90: Dark gray (深灰色)
    91: Light red (亮红色)
    92: Light green (亮绿色)
    93: Light yellow (亮黄色)
    94: Light blue (亮蓝色)
    95: Light magenta (亮洋红色)
    96: Light cyan (亮青色)
    97: White (白色)

EOF
)

["rRNA"]=$(cat <<'EOF'
    version:\t\tv2.0.11
    database:\t/share/data2/guorc/Software/infernal-1.1.4/Rfam.v14/Rfam.rRNA.cm
    Description:\ttRNA预测工具

    ----------------------------
         << 常用命令 >>
    ----------------------------
    ## 1、常用命令
    export PATH=/share/data2/guorc/Software/infernal-1.1.4/infernal-1.1.4/bin/bin:$PATH
    cmsearch -Z 1000 --hmmonly --cut_ga --noali --tblout <out file> <database> <in fasta:nucl>
    sed '1,3d' <out file> | awk '{print $1"\t"$3"\t"$4"\ttRNA("$5")"}' | less

    ## 2、建库命令[待更新]

EOF
)

["tRNA"]=$(cat <<'EOF'
    version:\t\tv2.0.11
    PATH:\t\t/usr/local/bin/tRNAscan-SE
    \033[31mcommon command:\033[0m\ttRNAscan-SE -q -L -B -o <outf> <in fasta:nucl>
    Description:\ttRNA预测工具
EOF
)

["bacphlip"]=$(cat <<'EOF'
    version:\t\t0.9.6
    avaliable database:\tNone
    conda env:\t\tsource activate /share/data2/guorc/Software/conda/py3
    \033[31mcommon command:\033[0m\tbacphlip --multi_fasta -i input.fasta

    ----------------------------
         << 其他相关命令 >>
    ----------------------------
    ## 1、因为原始脚本作者没有考虑压缩文件等问题，运行时如果中断或者出现别的问题很麻烦,
          而且原始的脚本运行时需要手动拆分序列才能多个一起运行，所以这边重新封装了一下,支持多线程

    bacphlip.my -i input.fa/input.fa.gz -o output.txt -t 20

EOF
)


["phylophlan-3"]=$(cat <<'EOF'
    version:\t\tv.3.0.3
    conda env:\t\t/home/zhangy2/.conda/envs/phylophlan-3
    database:\t\t/share/data1/Database/phylophlan-3
    configure:\t\t/share/data1/software/phylophlan-3.0.3/phyphl.cfg

    ----------------------------
         << 常用命令 >>
    ----------------------------
    source activate /home/zhangy2/.conda/envs/phylophlan-3

    phylophlan --diversity low --nproc 40 -d <db> -f <cfg>

EOF
)


["bowtie2"]=$(cat <<'EOF'
    version:\t\t2.4.4
    PATH:\t\t/usr/local/bin/bowtie2

    ----------------------------
         << 常用命令 >>
    ----------------------------
    ## 1. build DB
    bowtie2-build --large-index --threads <threads> <fasta> <out_prefix>


    ## 2. paired bowtie2
    bowtie2 --end-to-end --mm --fast -1 <fq1> -2 <fq2>  -x <index>  --no-head -S <out.sam> -p <threads> 2> out.log

    ## 3. single bowtie2
    bowtie2 --end-to-end --mm --fast -U <fq>  -x <index>  --no-head -S <out.sam> --un-gz <out.fq.gz> -p <threads> 2> out.log

    ## 2. 保留没有比对到数据库的reads （常用于单端测序数据去宿主）
    bowtie2 --end-to-end --mm --fast -U <fq>  -x <index>  --no-head -S /dev/null --un-gz <out.fq.gz> -p <threads> 2> out.log

EOF
)

["bbduk"]=$(cat <<'EOF'
    version:\t\t/share/data1/software/bbmap/bbversion.sh
    PATH:\t\t/share/data1/software/bbmap/bbduk.sh
    \033[31mcommon command:\033[0m\tbbduk.sh in1=<fq> out1=$out.bbduk.fq.gz entropy=0.6 entropywindow=50 entropyk=5 2> $out.bbduk.log

    ----------------------------
         << 其他相关命令 >>
    ----------------------------

    bbduk.sh in1=$in.1.fq.gz out1=$out.1.bbduk.fq.gz in2==$in.2.fq.gz out2=$out.2.bbduk.fq.gz entropy=0.6 entropywindow=50 entropyk=5

EOF
)

["spades"]=$(cat <<'EOF'

    version:\t\tv3.15.5
    PATH:\t\t/share/data1/software/SPAdes-3.15.5-Linux/bin/spades.py

    ----------------------------
         << 常用命令 >>
    ----------------------------

    ## 1.对于混合菌株或者宏基因组样本，使用此参数
    spades.py --meta -1 <reads_1>  -2 <reads_2>  -k 21,41,61,81,101,121 -o <out_dir> 

    ## 2.分离的单个菌株测序用这个。如果组装结果有太多污染，可以考虑使用--meta
    spades.py --isolate -1 <reads_1>  -2 <reads_2>  -k 21,41,61,81,101,121 -o <out_dir> 

    ## 3.默认的参数会对reads做一次矫正，这一步也花费时间，如果本来测序错误就很低，那就省略矫正这一步
    spades.py --isolate -1 <reads_1>  -2 <reads_2> --only-assembler  -k 21,41,61,81,101,121 -o <out_dir> 

EOF
)

["checkm2"]=$(cat <<'EOF'
    version:\t\tv.2
    avaliable database:\t/share/data1/Database/checkm2/uniref100.KO.1.dmnd
    conda env:\t\t/share/data1/software/miniconda3/envs/checkm2

    ----------------------------
         << 基本命令 >>
    ----------------------------

    source activate /share/data1/software/miniconda3/envs/checkm2

    # 你可以给定参数-x 来指定后缀
    checkm2 predict --quiet --threads 20 -o <output_dir> --database_path <db_file> --allmodels --input <input_dir> -x fa

    ## 你也可以直接给定输入的所有文件，这样可以输入多个不同后缀的文件
    checkm2 predict --quiet --threads 20 -o <output_dir> --database_path <db_file> --allmodels --input <input_dir/*.fa> [<input_dir2/*.fasta>] 

EOF
)


["time"]=$(cat <<'EOF'

    /usr/bin/time --format='Real time: %e seconds\\nUser time: %U seconds\\nSystem time: %S seconds\\nCPU usage: %P\\nMax memory: %M KB\\nExit status: %x' -o time_output.txt ls

    %e 显示了程序从开始到结束的流逝时间（Real time），单位为秒。
    %U 显示了程序在用户模式下消耗的CPU时间（User time），单位为秒。
    %S 显示了程序在内核（系统）模式下消耗的CPU时间（System time），单位为秒。
    %P 显示了CPU的使用百分比（CPU usage）。
    %M 显示了程序使用的最大内存量（Max memory），单位为KB。
    %x 显示了命令的退出状态（Exit status）。
EOF
)

["geNomad"]=$(cat <<'EOF'
    version:\t\t1.7.4
    avaliable database:\t/share/data1/Database/geNomad/genomad_db
    conda env:\t\tsource activate /share/data2/guorc/Software/conda/genomad.v1.11.1
    cite:\t\t10.1038/s41587-023-01953-y
    \033[31mcommon command:\033[0m\tgenomad end-to-end --threads 80 --cleanup <input_fasta> <output_dir> <database>
EOF
)

["fastp"]=$(cat <<'EOF'
    version:\t\t0.23.3
    software path:\t/usr/local/bin/fastp

    ----------------------------
         << 双端过滤 >>
    fastp  -w 4 -q 20 -u 30 -n 5 -y -Y 30  --trim_poly_g --trim_poly_x -j /dev/null -h /dev/null -l \033[31m<min_len>\033[0m -o $out.1.fq.gz -i $fq1 -I $fq2 -O $out.2.fq.gz  2> $out.log 
    
    ----------------------------
    NOTE:
        <min_len> 可以设置为测序长度的80%，如果序列太短/长，可以适当调整


EOF
)

["metabat2"]=$(cat <<'EOF'
    version:\t\t2022-10-13T11:28:11
    software path:\t/share/data1/software/metabat/bin/metabat2
    \033[31mcommon command:\033[0m\tmetabat2 -i <in_fasta> -a <in_depth_by_jgi> -o <out_prefix> -m 2000 -s 200000 --saveCls --seed 2020
    ----------------------------
         << 相关命令 >>
    ----------------------------
    ## 1、输出没有被分箱的序列
    metabat2 -i <in_fasta> -a <in_depth_by_jgi> -o <out_prefix> -m 2000 -s 200000 --saveCls --unbinned --seed 2020
EOF
)

["diamond"]=$(cat <<'EOF'
    version:\t\tv2.0.13
    ----------------------------
         << 相关命令 >>
    ----------------------------
    ## 1.帮助文档
    diamond help

    ## 2.建库(建立索引)
    diamond makedb --in <fasta> --db <prefix>

    ## 3.蛋白序列比对
    diamond blastp --outfmt 6 --db <db.dmnd> -o <out.btp> --quiet  --query <in.fasta> --query-cover 50 --subject-cover 50 --id 30 -p 8

    ## 4.核酸比对蛋白
    NOTE: 对于每一条序列，blaxtx会翻译出6条蛋白序列(正反序列各三条)
    diamond blastx --outfmt 6 --db <db.dmnd> -o <out.btp> --quiet  --query <in.fasta> --query-cover 50 --subject-cover 50 --id 30 -p 8

    ## 5.将数据库转为faa序列
    diamond getseq -d <db.dmnd> | head
EOF
)



["blast"]=$(cat <<'EOF'
    version:\t\tv.2.12+

    ## 1.建立索引(数据库)
    makeblastdb -dbtype nucl -in <input.fna> -out <db>

    ## 2.比对参数
    blastn -query <query.fna> -out <out> -outfmt 6 -db <db.prefix> 

    ## 3.拼接
    /usr/local/bin/connect_blast  <input:blastn_out>  <out> 1
    必须是默认输出结果(qid, sid, qstart, sstart)排过序的

    ## 4.过滤
    ### 如果有别的需求可查看帮助文档,【\033[0m如果输入的长度文件不存在，程序不会报错，不会报错!!!\033[0m】
    /usr/local/bin/filter_blast -i <input:blast_out> -o <out> --identity 95 --qfile <query.fna.len> --qper 90

EOF
)

["gtdbtk"]=$(cat <<'EOF'
    version:\t\tv2.3.2
    avaliable database:\t/share/data1/Database/gtdbtk-214/release214/
    conda env:\t\tsource activate /share/data1/software/miniconda3/envs/gtdbtk
    \033[31mcommon command:\033[0m\tgtdbtk classify_wf --cpus 80 --skip_ani_screen --genome_dir <input_dir> --out_dir <output_dir> -x <suffix_of_input_genome[fa,fna,...]>

    ----------------------------
         << 其他相关命令 >>
    ----------------------------
    ## 1.列表

    gtdbtk classify_wf --cpus 80 --skip_ani_screen --batchfile <input_table> --out_dir <output_dir>

    用户可以输入基因组列表以运行gtdbtk，列表格式如下,使用tab分割：
    /path/to/genome1.fna.gz\tgenome1
    /path/to/genome2.fna\tgenome2
    /path/to/genome3.fa.gz\tgenome3
    /path/to/genome4.fa\tgenome4

EOF
)

["fastANI"]=$(cat <<'EOF'
    software path:/share/data1/software/miniconda3/envs/drep3/bin/fastANI

    ## 1.genome
    fastANI -q genome1.fa -r genome2.fa -o output.txt

    ## 2.genome list
    fastANI -q genome1.fa --refList genome_list.txt -o output.txt -t <threads>

    fastANI --queryList genome1.fa --refList genome_list.txt -o output.txt <threads>

    ---
    if genome length < --fragLen, get blank result
    ---

EOF
)

["samtools"]=$(cat <<'EOF'
    version:\t\t1.14
    software path:\t/usr/local/bin/samtools

    ## 1.calc genome coverage
    samtools coverage -ibam x.sorted.bam -o x.genome.tsv

EOF
)




["checkv"]=$(cat <<'EOF'
    version:\t\tv0.7.0
    avaliable database:\t/share/data2/guorc/Software/conda/checkv/checkv-db-v0.6/
    \033[31mcommon command:\033[0m\t/share/data2/guorc/Software/conda/checkv/bin/checkv end_to_end -d /share/data2/guorc/Software/conda/checkv/checkv-db-v0.6/ -t 80 GVD_sequences.fa  gvd_ckv >xx.log 2>&1

    ----------------------------
         << 其他相关命令 >>
    ----------------------------
    ## 1. 过滤条件

EOF
)


["prefetch"]=$(cat <<'EOF'
    version:\t\tv3.0.2
    \033[31mcommon command:\033[0m\t/share/data1/software/sratoolkit.3.0.2/bin/prefetch <SRA|URL> --max-size 100G --output-file <out>.sra

    ----------------------------
         << 其他相关命令 >>
    ----------------------------
    ## 1. extract fastq from SRA file
    /share/data1/software/sratoolkit.3.0.2/bin/fasterq-dump --split-3 --threads 80 --outdir <outdir> <input.sra>

EOF
)

["drep3"]=$(cat <<'EOF'
    URL:\t\thttps://github.com/MrOlm/drep/releases
    version:\t\tdrep3
    conda env:\t\tsource activate /share/data1/software/miniconda3/envs/drep3
    \033[31mcommom command:\033[0m\tdRep  dereplicate <out_dir> -g <input_dir/*.fna> -p 28 -pa 0.9 -sa 0.95 -nc 0.3 --ignoreGenomeQuality  --S_algorithm fastANI --skip_plots
    description:\tClustering genomes.

    ----------------------------
         << 其他相关命令 >>
    ----------------------------
    
    \e[1m\u25CF\e[0m\t00.因为fastANI计算很慢，如果想要跳过fastANI,加入参数--SkipSeconda,但是，相应的，你应该将第一次聚类的阈值改为-pa修改为自己想要设定的阈值
    dRep  dereplicate <out_dir> -g <input_dir/*.fna> -p 28 -pa 0.9 -sa 0.95 -nc 0.3 --ignoreGenomeQuality  --S_algorithm fastANI --skip_plots --SkipSeconda

    \e[1m\u25CF\e[0m\t1.解析聚类结果
    less <out_dir>/data_tables/Cdb.csv | perl -e '<>;while(<>){chomp;@s=split /,/;$s[1]=~s/.fa$//;push @{$h{$s[0]}},$s[1];} for(keys %h){@a=@{$h{$_}};print "$_\\t".($#a+1)."\\t".(join ";",@a)."\\n";}' | msort -k rn2 > drep.clu.info

    \e[1m\u25CF\e[0m\t2.转换成长列表
    less drep.clu.info | perl -e 'while(<>){chomp;@l=split/\s+/;@c=split(";",$l[-1]);$n++;print join("\\tclu_$n\\n",@c)."\\tclu_$n\\n"}' > drep.clu.long
    
    \e[1m\u25CF\e[0m\t3.如果有ckm的结果，那么在簇中选一个Quality Score（Completeness - 5 * Contamination）最高的。
    perl /share/data1/mengjx/bin/parse_dRep_cls.pl [Cdb.csv] [ckM_res] [out_f]
    result: cls, N cls, representive bin, all bins.


EOF
)

["mmseqs2"]=$(cat <<'EOF'
    URL:\t\thttps://github.com/soedinglab/MMseqs2
    version:\t\t12.113e3
    conda env:\t\tsource activate /share/data1/software/miniconda3/envs/mmseqs2
    \033[31mcommom command:\033[0m\tmmseqs easy-cluster <input> <out_prefix> <temp_dir> --min-seq-id 0.5 --cov-mode 1 -c 0.9 --cluster-mode 2 --cluster-reassign 1 --kmer-per-seq 200 --kmer-per-seq-scale 0.8 --threads 32 --compressed 1

    ----------------------------
         << 其他相关命令 >>
    ----------------------------
    ## 长列表转宽列表
    less all.clu_cluster.tsv | perl -e 'while(<>){chomp;@s=split/\s+/;push @{$h{$s[0]}},$s[1];} for(keys %h){@a=@{$h{$_}}; print "$_\\t".($#a+1)."\\t".(join",", @a)."\\n";}' > all.clu_cluster.tsv.f

    description:\tClustering gene[nucl,prot]

    ## 使用mmseqs进行序列比对
    ### 1、建库
    mmseqs createdb input.fa [input.fa2 input.fa3 ... ] votu.db
EOF
)

["busco"]=$(cat <<'EOF'
    version:\t\tv5.5.0
    avaliable database:\teukaryota_odb10, prokaryota_db, apicomplexa_odb10, fungi_odb10
    conda env:\t\tsource activate /home/zhangy2/.conda/envs/busco
    doi:\t\t10.1093/molbev/msab199
    \033[31mcommon command:\033[0m\tbusco -i <genome.fna> -l /share/data1/Database/busco/fungi_odb10/lineages/fungi_odb10/ -o <out> -m genome --offline

    ----------------------------
         << 其他相关命令 >>
    ----------------------------
    ## 1. 输入蛋白序列
    busco -i <input.faa> -l /share/data1/Database/busco/fungi_odb10/lineages/fungi_odb10/ -o <output> -m protein --offline

    ## 2. 输入基因组序列
    busco -i <input.fna> -l /share/data1/Database/busco/fungi_odb10/lineages/fungi_odb10/ -o <output> -m genome --offline

    ## 3. 查询网络有哪些数据库
    busco --list-datasets

EOF
)

)


eg_dict["lifestyle"]="${eg_dict["bacphlip"]}"
eg_dict["phage_lifestyle"]="${eg_dict["bacphlip"]}"  # 可以添加多个别名

eg_keys=${!eg_dict[*]} # 获取所有的键

function levenshtein {
    # levenshtein string1 string2
    local s1="$1"
    local s2="$2"
    # echo -n $(( $(echo -n "$s1" | wc -m) + $(echo -n "$s2" | wc -m) ))
    d=$(diff <(echo "$s1" |sed 's/./&\n/g') <(echo "$s2" |sed 's/./&\n/g') | grep -c '^[<>]')
    echo $((100-100*d/(${#s1}+${#s2})))
}

function get_simlar(){
    # 获取给定值和数组中最相似的某个值
    local input=$1
    local targets=($2) # 数组
    local most_similar=0
    declare -A dist_dict=()

    # 计算相似度，以及最大相似度
    for key in ${targets[*]}; do
        distance=$(levenshtein "$input" "$key")
        dist_dict["$key"]=$distance
        ( [ $distance -gt $most_similar ] ) && most_similar=$distance;
    done

    ( [ $most_similar -eq 0 ] ) && echo "Not found: $input" && exit 127;
    
    for key in ${!dist_dict[*]};do
        v=${dist_dict["$key"]}
        if [ $v -eq $most_similar ];then
            ref+="$key, "
        fi
    done
    printf "Did you mean: %s ?\n" "${ref%, }"
    exit 127
}



function print_usage(){
    local n=$1
    # if [ -n ${eg_dict["$n"]+_} ]; then
    if test ${eg_dict[$n]+_}; then
        echo -e "\n<<\e[32m$n\e[0m>>"
        x=${eg_dict["$n"]}
        echo -e "\n$x\n\n"
        exit 0
    else
        get_simlar $n "${eg_keys[*]}"
    fi
}

if [ $# -ne 1 ] || [[ $1 =~ "-h" ]] || [[ $1 =~ "-help" ]];then
    echo "$0 list    list all args"
    echo "$0 <arg>   show usage"
    exit 0
elif [ $1 == "list" ];then
    echo -e "\nall args:"
    echo "--------------"
    IFS=" " read -ra xx <<< "$eg_keys"
    xx=($(printf "%s\n" "${xx[@]}" | sort))
    for i in ${xx[@]}; do
        echo -e "    $i"
    done
    echo "--------------"
    exit 0
fi

print_usage "$1"

