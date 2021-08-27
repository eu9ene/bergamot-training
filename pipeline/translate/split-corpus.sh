#!/bin/bash
##
# Splits a parallel dataset
#

set -x
set -euo pipefail

corpus_src=$1
corpus_trg=$2
output_dir=$3
chunks=$4

mkdir -p "${output_dir}"
pigz -dc "${corpus_src}" |  split -d -n ${chunks} - "${output_dir}/file."
pigz -dc "${corpus_trg}" |  split -d -n ${chunks} - "${output_dir}/file." --additional-suffix .ref