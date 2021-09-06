#!/bin/bash
##
# Filters student parallel data with a reversed NMT model.
#
# Usage:
#   bash ce-clean.sh model_dir corpus_prefix output_prefix
#

set -x
set -euo pipefail

echo "###### Cross entropy filtering"
test -v MARIAN
test -v GPUS
test -v SRC
test -v TRG
test -v WORKSPACE

model=$1
vocab=$2
corpus_prefix=$3
output_prefix=$4
threads=$5

# Part of the data to be removed (0.05 is 5%)
remove=0.05
output_dir=$(dirname "${output_prefix}")
dir="${output_dir}/scored"
mkdir -p "${output_dir}"
mkdir -p "${dir}"

echo "### Scoring"
test -s "${dir}/scores.txt" ||
  "${MARIAN}/marian-scorer" \
    -m "${model}" \
    -v "${vocab}" "${vocab}" \
    -t "${corpus_prefix}.${TRG}.gz" "${corpus_prefix}.${SRC}.gz" \
    --mini-batch 32 \
    --mini-batch-words 1500 \
    --maxi-batch 1000 \
    --max-length 250 \
    --max-length-crop \
    -d ${GPUS} \
    -w "${WORKSPACE}" \
    --log "${dir}/scores.txt.log" \
    >"${dir}/scores.txt"

echo "### Decompressing corpus"
test -s "${dir}/corpus.${TRG}" || pigz -dc "${corpus_prefix}.${TRG}.gz" >"${dir}/corpus.${TRG}"
test -s "${dir}/corpus.${SRC}" || pigz -dc "${corpus_prefix}.${SRC}.gz" >"${dir}/corpus.${SRC}"


echo "### Normalizing scores"
test -s "${dir}/scores.nrm.txt" ||
  paste "${dir}/scores.txt" "${dir}/corpus.${TRG}" |
  parallel --no-notice --pipe -k -j "${threads}" --block 50M "python pipeline/cefilter/normalize-scores.py" |
  cut -f1 >"${dir}/scores.nrm.txt"

echo "### Sorting scores"
if [ ! -s "${dir}/sorted.gz" ]; then
  buffer_size="$(echo "$(grep MemTotal /proc/meminfo | awk '{print $2}')"*0.9 | bc | cut -f1 -d.)"
  paste "${dir}/scores.nrm.txt" "${dir}/corpus.${SRC}" "${dir}/corpus.${TRG}" |
  LC_ALL=C sort -n -k1,1 -S "${buffer_size}K" -T "${dir}" |
  pigz >"${dir}/sorted.gz"
fi

echo "### Cutting the best scored corpus"
if [ ! -s "${dir}/best.gz" ]; then
  lines=$(pigz -dc "${dir}/sorted.gz" | wc -l)
  startline=$(echo ${lines}*${remove} | bc | cut -f1 -d.)
  pigz -dc "${dir}/sorted.gz" | tail -n +${startline} | cut -f2,3 | pigz >"${dir}/best.gz"
fi

echo "### Writing output corpus"
pigz -dc "${dir}/best.gz" | cut -f1 | pigz >"${output_prefix}.${SRC}.gz"
pigz -dc "${dir}/best.gz" | cut -f2 | pigz >"${output_prefix}.${TRG}.gz"

echo "### Deleting tmp dir"
rm -rf "${dir}"

echo "###### Done: Cross entropy filtering"