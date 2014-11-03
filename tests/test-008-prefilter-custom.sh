#!/bin/bash -l

set -e
set -u

N=10

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
  | sort \
  > ${TMPD}/with-prefiltering

../eqtl-ranef \
  --regressors=${TMPD}/regressors \
  --outcomes=${TMPD}/outcomes \
  --fixef=${TMPD}/fixef \
  --ranef=${TMPD}/ranef \
  --genespos=${TMPD}/genespos.sqlite \
  --snpspos=${TMPD}/snpspos.sqlite \
  --cores=1 \
  --cis-pvalue=1 --trans-pvalue=1 \
  | sort \
  > ${TMPD}/full

awk -v FS='	' -v OFS='	' '{print $2":::"$1}' ${TMPD}/prefilter.tab \
 | sort > ${TMPD}/prefilter.sorted

awk -v FS='	' -v OFS='	' '{print $1":::"$2, $0}' ${TMPD}/full \
 | sort -k1,1 \
 > ${TMPD}/full.sorted

join -t '	' ${TMPD}/prefilter.sorted ${TMPD}/full.sorted \
  | cut -f 2- \
  | sort \
  > ${TMPD}/full.postfiltered

if diff ${TMPD}/{with-prefiltering,full.postfiltered} ; then
  echo "outputs are identical"
else
  diff ${TMPD}/{with-prefiltering,full.postfiltered}
fi
