#!/bin/bash
##
# Installs and compiles alignment tools
#
# Usage:
#   bash compile-fast-align.sh
#

set -x
set -euo pipefail

echo "###### Compiling fast align"

test -v BIN
test -v BUILD_DIR
test -v THREADS

mkdir -p "${BIN}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"
cmake ..
make -j "${THREADS}"
cp fast_align atools "${BIN}"

echo "###### Done: Compiling fast align"