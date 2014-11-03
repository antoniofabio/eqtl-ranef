#!/bin/bash -l

set -e
set -u

OUTCOMES=100
REGRESSORS=1000
CIS=2

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../generate-eqtl-ranef-data \
  --output=${TMPD} \
  --regressors=${REGRESSORS} \
  --outcomes=${OUTCOMES} \
  --samples=2 \
  --fixef=1 \
  2> /dev/null

../compute-cis-ranges \
  --genespos=${TMPD}/genespos.sqlite \
  --snpspos=${TMPD}/snpspos.sqlite \
  --sorted-snpspos=${TMPD}/snpspos.sorted.tab \
  --cis-window=${CIS}
