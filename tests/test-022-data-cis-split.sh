#!/bin/bash -l

##
## run a cis-only analysis first by doing full run,
## followed by subsetting; then by splitting into a number of cis-chunks,
## running them separately, and concatenating back the results.
## The two results must match exactly
##

set -e
set -u
set -o pipefail

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

GT=data/genotype.bySample.thin
GEX=data/expression.thin
FIXEF=data/fixef.tab
RANEF=data/ranef.tab
GEXPOS=data/genespos.sqlite
GTPOS=data/snpspos.sqlite
CIS_WINDOW=50000
CHUNKS=2

LOG() { echo "$@" 1>&2; }
# LOG() { echo "$@" ; }

##
## first run: full analysis, followed by subsetting cis results only
##
LOG "first run: full analysis, followed by subsetting cis results only"

../eqtl-ranef \
  --regressors=${GT} \
  --outcomes=${GEX} \
  --fixef=${FIXEF} \
  --ranef=${RANEF} \
  --genespos=${GEXPOS}\
  --snpspos=${GTPOS} \
  --cis-window=${CIS_WINDOW} \
  --cis-pvalue=1 --trans-pvalue=1 \
  2> /dev/null \
  | awk -v FS='	' '$7 == "cis"' \
  | cut -f 1-6 \
  | sort \
  > ${TMPD}/results.serial

LOG "second run"

LOG ""
LOG "I) compute cis ranges"
LOG ""

../data-cis-ranges \
  --genespos=${GEXPOS} \
  --snpspos=${GTPOS} \
  --sorted-snpspos=${TMPD}/gt.pos \
  --cis-window=${CIS_WINDOW} \
  2> /dev/null \
  > ${TMPD}/cisRanges.tab

LOG ""
LOG "II) subset genotype and expression data"
LOG ""

../table-cast < ${GT} \
 2> /dev/null \
 | ../table-subset-ordered -a ${TMPD}/gt.pos > ${TMPD}/gt.fat 2> /dev/null

../table-cast < ${GEX} \
 2> /dev/null \
 | ../table-subset-ordered -a ${TMPD}/cisRanges.tab > ${TMPD}/gex.fat 2> /dev/null

LOG ""
LOG "III) split data in chunks"
LOG ""

../data-cis-split \
  --gex=${TMPD}/gex.fat \
  --gt=${TMPD}/gt.fat \
  --cis-ranges=${TMPD}/cisRanges.tab \
  --chunks=${CHUNKS} \
  --output-prefix="${TMPD}/chunks/" \
  --dump-cispairs-db \
  2> /dev/null
  > /dev/null

LOG ""
LOG "IV) run one analysis per chunk"
LOG ""

for chunk in `ls ${TMPD}/chunks` ; do
  ../eqtl-ranef \
    --regressors=<(../table-melt < ${TMPD}/chunks/${chunk}/genotype.fat 2> /dev/null) \
    --outcomes=<(../table-melt < ${TMPD}/chunks/${chunk}/expression.fat 2> /dev/null) \
    --fixef=${FIXEF} \
    --ranef=${RANEF} \
    --prefilter=${TMPD}/chunks/${chunk}/prefilter.cispairs.sqlite \
    --cis-window=${CIS_WINDOW} \
    --cis-pvalue=1 --trans-pvalue=1 \
    2> /dev/null \
    > ${TMPD}/chunks/${chunk}/results
done

LOG ""
LOG "V) merge back results"
LOG ""

cat ${TMPD}/chunks/*/results | cut -f 1-6 | sort > ${TMPD}/results.chunked

LOG ""
LOG "compare results"
LOG ""

if diff ${TMPD}/results.{serial,chunked} > /dev/null ; then
  echo "the chunking pipeline behaves consistently"
else
  diff ${TMPD}/results.{serial,chunked}
fi
