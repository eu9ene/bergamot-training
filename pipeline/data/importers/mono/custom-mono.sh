#!/bin/bash
##
# Use custom monolingual dataset that is already downloaded to a local disk
# Local path prefix without `.<lang_code>.gz` should be specified as a "dataset" parameter
#
# Usage:
#   bash custom-mono.sh lang output_prefix dataset
#

set -x
set -euo pipefail

echo "###### Copying custom monolingual dataset"

lang=$1
output_prefix=$2
dataset=$3

cp "${dataset}.${lang}.gz" "${output_prefix}.${lang}.gz"


echo "###### Done: Copying custom monolingual dataset"