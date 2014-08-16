#!/bin/bash -l

## genes and snps annotation can be left out.
## Then, all gene-snp pairs are treated as 'trans'

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
    --genespos=data/genespos.sqlite \
    --snpspos=data/snpspos.sqlite \
    --cis-pvalue=1 \
    --trans-pvalue=1 \
    2> /dev/null | sort \
    > ${TMPD}/withAnnotation.out

../eqtl-ranef \
    --regressors=data/genotype.bySample.thin \
    --outcomes=data/expression.thin \
    --fixef=data/fixef.tab \
    --ranef=data/ranef.tab \
    --trans-pvalue=1 \
    2> /dev/null | sort \
    > ${TMPD}/withoutAnnotation.out 2> /dev/null

echo "difference in output data with and without positions annotation:"

diff <(cut -f 1-6 ${TMPD}/withAnnotation.out) <(cut -f 1-6 ${TMPD}/withoutAnnotation.out)

echo "=end of diff="

echo "gene-SNP pairs are annotated as:"
cut -f 7 ${TMPD}/withoutAnnotation.out | sort | uniq
