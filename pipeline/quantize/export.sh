#!/bin/bash
##
# Export the quantized model to bergamot translator format.
#
# Usage:
#   bash export.sh model_dir shortlist output_dir
#

set -x
set -euo pipefail

echo "###### Exporting a quantized model"

test -v SRC
test -v TRG
test -v MARIAN

model_dir=$1
shortlist=$2
vocab=$3
output_dir=$4

mkdir -p "${output_dir}"

model="${output_dir}/model.${SRC}${TRG}.intgemm.alphas.bin"
cp "${model_dir}/model.intgemm.alphas.bin" "${model}"
pigz "${model}"

shortlist_bin="${output_dir}/lex.50.50.${SRC}${TRG}.s2t.bin"
"${MARIAN}"/marian-conv \
  --shortlist "${shortlist}" 50 50 0 \
  --dump "${shortlist_bin}" \
  --vocabs "${vocab}" "${vocab}"
pigz "${shortlist_bin}"

vocab_out="${output_dir}/vocab.${SRC}${TRG}.spm"
cp "${vocab}" "${vocab_out}"
pigz "${vocab_out}"


echo "### Export is completed. Results: ${output_dir}"

echo "###### Done: Exporting a quantized model"
