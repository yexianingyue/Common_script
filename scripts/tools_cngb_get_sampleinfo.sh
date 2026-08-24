#!/usr/bin/bash

if [ $# -ne 1 ];then
    echo "$0 sample_name"
    exit 127
fi

sample=$1
wget -q -O - "https://db.cngb.org/cnsa/ajax/sample/public_view/?q=%7B%22CNSA%22%3A%22${sample}%22%2C%22EBB%22%3A%22%22%7D&lang=en" |
 jq -r '(.data.summary_data | [.accession_id[0], .sample_title, .sample_name]) | @tsv'
