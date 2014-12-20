#!/bin/bash -l

set -e
set -u
set -o pipefail

CIS_WINDOW=0
CHUNKS=3

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

../pipeline-prepare-cis-data \
  --gex_data data/expression.ex1.fat \
  --gex_pos data/genespos.ex1.tab \
  --gt_data data/genotype.ex1.fat \
  --gt_pos data/snpspos.ex1.tab \
  --cis_window ${CIS_WINDOW} \
  --chunks ${CHUNKS} \
  --out ${TMPD} \
  > /dev/null 2>&1

rm -f ${TMPD}/cisPairs.chunked.tab
for chunk in ${TMPD}/chunks/* ; do
    sqlite3 --csv --separator '	' --newline $'\n' ${chunk}/cispairs.sqlite 'select * from pairs;' >> ${TMPD}/cisPairs.chunked.tab
done
sort ${TMPD}/cisPairs.chunked.tab > ${TMPD}/tmp && mv ${TMPD}/tmp ${TMPD}/cisPairs.chunked.tab

../cis-ranges-to-pairs <(cut -f 1 ${TMPD}/gt.pos) < ${TMPD}/cisRanges.tab 2> /dev/null | sort > ${TMPD}/cisPairs.full.tab

if diff ${TMPD}/cisPairs.{full,chunked}.tab > /dev/null ; then
  echo "the chunking pipeline behaves consistently"
else
  diff ${TMPD}/cisPairs.{full,chunked}.tab
fi
