#!/bin/bash -l

set -e
set -u
set -o pipefail

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

echo -n "ID	C1	C2
X1	1	2
X2	3	4
X3	5	6
X4	7	8
X5	9	10
" > ${TMPD}/input.tab

echo -n "X4
X2
" > ${TMPD}/IDs.txt

../table-subset-ordered ${TMPD}/IDs.txt < ${TMPD}/input.tab
echo ""
../table-subset-ordered -a ${TMPD}/IDs.txt < ${TMPD}/input.tab
