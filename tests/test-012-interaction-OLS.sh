#!/bin/bash -l

## interaction tests with simple linear regression

set -e
set -u
set -o pipefail

../eqtl-ranef \
    --regressors=data/genotype.bySample.thin \
    --outcomes=data/expression.thin \
    --intef=data/intef.tab \
    --genespos=data/genespos.sqlite \
    --snpspos=data/snpspos.sqlite \
    --cis-pvalue=1 \
    --trans-pvalue=1 \
    | sort
