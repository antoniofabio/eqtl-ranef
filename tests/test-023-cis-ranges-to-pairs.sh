#!/bin/bash -l

set -e
set -u
set -o pipefail

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

echo -n "rs1
rs2
rs3
rs4
rs5
" > ${TMPD}/gtIDs.txt

echo -n "geneA	1	1
geneB	1	3
geneC	2	5
geneD	3	3
" | ../cis-ranges-to-pairs ${TMPD}/gtIDs.txt
