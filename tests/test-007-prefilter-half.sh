#!/bin/bash -l

set -e
set -u
set -o pipefail

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../eqtl-ranef \
  --regressors=data/genotype.bySample.thin \
  --outcomes=data/expression.thin \
  --fixef=data/fixef.tab \
  --ranef=data/ranef.tab \
  --prefilter=data/prefilter.half.sqlite \
  --genespos=data/genespos.sqlite \
  --snpspos=data/snpspos.sqlite \
  --cis-pvalue=1.0 --trans-pvalue=1.0 \
  | sort \
  > ${TMPD}/with-prefiltering

../eqtl-ranef \
  --regressors=data/genotype.bySample.thin \
  --outcomes=data/expression.thin \
  --fixef=data/fixef.tab \
  --ranef=data/ranef.tab \
  --genespos=data/genespos.sqlite \
  --snpspos=data/snpspos.sqlite \
  --cis-pvalue=1.0 --trans-pvalue=1.0 \
  | sort \
  > ${TMPD}/full

awk -v FS='	' -v OFS='	' '{print $2":::"$1}' data/prefilter.half.tab \
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
