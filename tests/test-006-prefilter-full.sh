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
  --prefilter=data/prefilter.full.sqlite \
  --genespos=data/genespos.sqlite \
  --snpspos=data/snpspos.sqlite \
  --cis-pvalue=1.0 --trans-pvalue=1.0 \
  | sort \
  > ${TMPD}/prefiltered

../eqtl-ranef \
  --regressors=data/genotype.bySample.thin \
  --outcomes=data/expression.thin \
  --fixef=data/fixef.tab \
  --ranef=data/ranef.tab \
  --genespos=data/genespos.sqlite \
  --snpspos=data/snpspos.sqlite \
  --cis-pvalue=1.0 --trans-pvalue=1.0 \
  | sort \
  > ${TMPD}/naive

if diff ${TMPD}/{prefiltered,naive} ; then
    echo "outputs are identical"
else
    echo "outputs differ!"
fi

