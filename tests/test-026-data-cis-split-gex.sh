#!/bin/bash -l

set -e
set -u
set -o pipefail

CIS_WINDOW=0
CHUNKS=3

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../table-sort-genomic < data/genespos.ex1.tab \
    | ../data-cis-ranges \
    <(../table-sort-genomic < data/snpspos.ex1.tab) \
    ${CIS_WINDOW} \
    > ${TMPD}/cisRanges.tab \
    2> /dev/null

../cis-ranges-chunks --mode=gex --chunks=${CHUNKS} \
  < ${TMPD}/cisRanges.tab \
  > ${TMPD}/cisChunks.tab \
  2> /dev/null

../data-cis-split \
  --gex=data/expression.ex1.fat \
  --gt=data/genotype.ex1.fat \
  --cis-ranges=${TMPD}/cisRanges.tab \
  --chunks=${TMPD}/cisChunks.tab \
  --output-prefix="${TMPD}/chunks/" \
  --dump-cisranges \
  2> /dev/null \
  > /dev/null

for chunk in `ls ${TMPD}/chunks` ; do
  ../cis-ranges-to-pairs \
    <(cut -f 1 ${TMPD}/chunks/${chunk}/genotype.fat | sed 1d) \
    < ${TMPD}/chunks/${chunk}/cisRanges.tab \
    > ${TMPD}/chunks/${chunk}/cisPairs.tab \
    2> /dev/null
done

cat ${TMPD}/chunks/*/cisPairs.tab | sort > ${TMPD}/cisPairs.splitted.tab

../cis-ranges-to-pairs \
  <(cut -f 1 data/genotype.ex1.fat | sed 1d) \
  < ${TMPD}/cisRanges.tab \
  > ${TMPD}/cisPairs.full.tab \
  2> /dev/null

if diff ${TMPD}/cisPairs.{full,splitted}.tab > /dev/null ; then
  echo "splitting cis-ranges behaves consistently"
else
  diff ${TMPD}/cisPairs.{full,splitted}.tab
fi
