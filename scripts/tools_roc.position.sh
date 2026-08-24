#!/usr/bin/bash

([ $# -ne 3 ]) && { echo -e "\n\n\tUsage:\t$0 \033[32mmin max No.points\033[0m\n\n"; exit 0; }

min=$1
max=$2
position=$3
awk -v start=$min -v end=$max -v over=${position} '
    BEGIN {
        r = (end / start) ^ (1 / (over - 1))
        val = start
        for (i=0; i<over; i++) {
            printf "%d\n", int(val + 0.5)
            val *= r
        }
    }' | sort -n | uniq | head -n ${position}
