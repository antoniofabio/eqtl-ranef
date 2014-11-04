#!/bin/bash -l

set -e
set -u

CIS_WINDOW=0

TMPD=`mktemp -d`
trap "rm -rf ${TMPD}" EXIT

function melt {
  ../table-melt < $1 > $2
}

function cast {
  ../table-cast < $1 > $2
}

melt data/expression.fat ${TMPD}/expression.thin
cast ${TMPD}/expression.thin ${TMPD}/expression.fat.1
melt ${TMPD}/expression.fat.1 ${TMPD}/expression.thin.1
cast ${TMPD}/expression.thin.1 ${TMPD}/expression.fat.2
melt ${TMPD}/expression.fat.2 ${TMPD}/expression.thin.2

if diff ${TMPD}/expression.thin.{1,2} ; then
  echo "cast/melt behave consistently"
else
  diff ${TMPD}/expression.thin.{1,2}
fi
