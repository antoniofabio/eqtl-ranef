#!/bin/bash -l

## unannotated SNP-gene pairs should be considered as trans

set -e
set -u
set -o pipefail

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

sqlite3 ${TMPD}/genespos.depleted.sqlite '
attach "data/genespos.sqlite" as gxpos;
create table genespos as select * from gxpos.genespos;
delete from genespos where reporterID = "1007_s_at";
'

../eqtl-ranef \
    --regressors=data/genotype.bySample.thin \
    --outcomes=data/expression.thin \
    --intef=data/intef.tab \
    --genespos=${TMPD}/genespos.depleted.sqlite \
    --snpspos=data/snpspos.sqlite \
    --cis-pvalue=1 \
    --trans-pvalue=1 \
    | cut -f 1,2,8 \
    | sort | uniq
