#!/bin/bash -l

set -e
set -u

N=10

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../generate-eqtl-ranef-data --output=${TMPD} \
  --regressors=${N} --outcomes=${N} --samples=20 --fixef=1 2> /dev/null

echo "SNPID	reporterID" > ${TMPD}/prefilter.tab
paste \
  <(cut -f 1 ${TMPD}/regressors | sort | uniq) \
  <(cut -f 1 ${TMPD}/outcomes | sort | uniq) \
  | sort \
  >> ${TMPD}/prefilter.tab
../import-table --table-name='pairs' --output=${TMPD}/prefilter.sqlite 2> /dev/null < ${TMPD}/prefilter.tab
sed -i 1d ${TMPD}/prefilter.tab ## drop header line

../eqtl-ranef \
  --regressors=${TMPD}/regressors \
  --outcomes=${TMPD}/outcomes \
  --fixef=${TMPD}/fixef \
  --ranef=${TMPD}/ranef \
  --prefilter=${TMPD}/prefilter.sqlite \
  --cores=1 \
  --cis-pvalue=1 --trans-pvalue=1 \
  | awk -v FS='	' -v OFS='	' '{print $2, $1}' \
  | sort \
  > ${TMPD}/tested-pairs

if diff ${TMPD}/{tested-pairs,prefilter.tab} ; then
  echo "output tests match input prefiltering"
else
  diff ${TMPD}/{tested-pairs,prefilter.tab}
fi
