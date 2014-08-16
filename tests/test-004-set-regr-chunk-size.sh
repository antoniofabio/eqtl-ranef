#!/bin/bash -l

set -e
set -u
set -o pipefail

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../generate-eqtl-ranef-data --output=${TMPD} \
  --regressors=100 --outcomes=1 --samples=30 --fixef=1

../eqtl-ranef \
  --regressors=${TMPD}/regressors \
  --outcomes=${TMPD}/outcomes \
  --fixef=${TMPD}/fixef \
  --ranef=${TMPD}/ranef \
  --genespos=${TMPD}/genespos.sqlite \
  --snpspos=${TMPD}/snpspos.sqlite \
  --cis-pvalue=0.1 --trans-pvalue=1e-3 \
  --regressors-chunk-size=301 \
    | sort
