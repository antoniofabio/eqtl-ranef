#!/bin/bash -l

set -e
set -u
set -o pipefail

../eqtl-ranef \
    --regressors=data/genotype.bySample.thin \
    --outcomes=data/expression.thin \
    --cis-pvalue=1 \
    --trans-pvalue=1
