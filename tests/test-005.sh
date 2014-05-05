#!/bin/bash -l

set -e
set -u
set -o pipefail

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../generate-eqtl-ranef-data --output=${TMPD} \
  --regressors=2 --outcomes=2 --samples=30 --fixef=1

cp ${TMPD}/fixef ${TMPD}/intef
cut -f 1 ${TMPD}/fixef > ${TMPD}/temp
mv ${TMPD}/temp ${TMPD}/fixef

../eqtl-ranef \
  --regressors=${TMPD}/regressors \
  --outcomes=${TMPD}/outcomes \
  --fixef=${TMPD}/fixef \
  --intef=${TMPD}/intef \
  --ranef=${TMPD}/ranef \
  --genespos=${TMPD}/genespos.sqlite \
  --snpspos=${TMPD}/snpspos.sqlite \
  --cis-pvalue=1.0 --trans-pvalue=1.0 \
    | sort
