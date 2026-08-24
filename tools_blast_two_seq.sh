#!/usr/bin/bash
set -e
shopt -e expand_aliases

if [ $# -lt 3 ];then
    echo "$0 blast/x/n/p <query_seq> <subject_seq> \"other blastn parameters\""
fi

alias blast
