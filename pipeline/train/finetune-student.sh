#!/bin/bash
##
# Finetune a student model.
#

set -x
set -euo pipefail

echo "###### Finetuning the student model"

dir=$1
corpus=$2
devset=$3
vocab=$4
alignment=$5
student=$6

test -v SRC
test -v TRG


mkdir -p "${dir}"
cp "${student}" "${dir}/model.npz"

bash "pipeline/train/train.sh" \
  "pipeline/train/configs/model/student.tiny11.yml" \
  "pipeline/train/configs/training/student.finetune.yml" \
  "${SRC}" \
  "${TRG}" \
  "${corpus}" \
  "${devset}" \
  "${dir}" \
  "${vocab}" \
  --guided-alignment "${alignment}"


echo "###### Done: Finetuning the student model"


