#!/bin/bash -l

set -e
set -u

N=100

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../generate-eqtl-ranef-data --output=${TMPD} \
  --regressors=${N} --outcomes=${N} --samples=200 --fixef=1 2> /dev/null

echo "SNPID	reporterID" > ${TMPD}/prefilter.tab
paste <(cut -f 1 ${TMPD}/regressors | sort | uniq) <(cut -f 1 ${TMPD}/outcomes | sort | uniq) >> ${TMPD}/prefilter.tab
../import-table --table-name='pairs' --output=${TMPD}/prefilter.sqlite < ${TMPD}/prefilter.tab

../eqtl-ranef \
  --regressors=${TMPD}/regressors \
  --outcomes=${TMPD}/outcomes \
  --fixef=${TMPD}/fixef \
  --ranef=${TMPD}/ranef \
  --prefilter=${TMPD}/prefilter.sqlite \
  --genespos=${TMPD}/genespos.sqlite \
  --snpspos=${TMPD}/snpspos.sqlite \
  --cores=1 \
  --cis-pvalue=1 --trans-pvalue=1 \
  | sort
