#!/bin/bash
##
# Runs quantization of the student model.
#

set -x
set -euo pipefail

echo "###### Quantizing a model"

test -v MARIAN
test -v BIN
test -v SRC
test -v TRG

model=$1
vocab=$2
shortlist=$3
devtest_src=$4
output_dir=$5

cd "$(dirname "${0}")"

res_model="${output_dir}/model.intgemm.alphas.bin"
mkdir -p "${output_dir}"
cp "${vocab}" "${output_dir}"

echo "### Decoding a sample test set in order to get typical quantization values"
test -s "${output_dir}/quantmults" ||
  "${MARIAN}"/marian-decoder \
    -m "${model}" \
    -v "${vocab}" "${vocab}" \
    -c "decoder.yml" \
    -i "${devtest_src}" \
    -o "${output_dir}/output.${TRG}" \
    --shortlist "${shortlist}" false \
    --quiet \
    --quiet-translation \
    --log "${output_dir}/cpu.output.log" \
    --dump-quantmult \
    2>"${output_dir}/quantmults"

echo "### Quantizing"
test -s "${output_dir}/model.alphas.npz" ||
  "${MARIAN}"/../scripts/alphas/extract_stats.py \
    "${output_dir}/quantmults" \
    "${model}" \
    "${output_dir}/model.alphas.npz"

echo "### Converting"
test -s "${res_model}" ||
  "${MARIAN}"/marian-conv \
    -f "${output_dir}/model.alphas.npz" \
    -t "${res_model}" \
    --gemm-type intgemm8

echo "### The result models is saved to ${res_model}"

echo "###### Done: Quantizing a model"
