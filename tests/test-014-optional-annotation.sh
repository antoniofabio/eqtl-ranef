#!/bin/bash -l

## genes and snps annotation can be left out.
## Then, all gene-snp pairs are treated as 'trans'

set -e
set -u
set -o pipefail

../eqtl-ranef \
    --regressors=data/genotype.bySample.thin \
    --outcomes=data/expression.thin \
    --intef=data/intef.tab \
    --trans-pvalue=1 \
    | sort
