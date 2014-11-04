#!/bin/bash -l

set -e
set -u
set -o pipefail

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../generate-eqtl-ranef-data --output=${TMPD} \
  --regressors=1 --outcomes=1 --samples=4 --fixef=1

../eqtl-ranef \
  --regressors=${TMPD}/regressors \
  --outcomes=${TMPD}/outcomes \
  --fixef=${TMPD}/fixef \
  --ranef=${TMPD}/ranef \
  --cis-pvalue=1.0 --trans-pvalue=1.0 \
  | wc -l
