#!/bin/bash -l

set -e
set -u
set -o pipefail

../eqtl-ranef --regressors=data/genotype.bySample.thin --outcomes=data/expression.thin --fixef=data/fixef.tab --ranef=data/ranef.tab --genespos=data/genespos.sqlite --snpspos=data/snpspos.sqlite --cis-pvalue=1 --trans-pvalue=1 | sort
