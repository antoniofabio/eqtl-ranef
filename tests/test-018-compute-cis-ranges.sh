#!/bin/bash -l

set -e
set -u

CIS_WINDOW=0

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../import-genespos --output=${TMPD}/genespos.sqlite < data/genespos.ex1.tab
../import-snpspos --output=${TMPD}/snpspos.sqlite < data/snpspos.ex1.tab

../compute-cis-ranges \
  --genespos=${TMPD}/genespos.sqlite \
  --snpspos=${TMPD}/snpspos.sqlite \
  --sorted-snpspos=${TMPD}/snpspos.sorted.tab \
  --cis-window=${CIS_WINDOW}
