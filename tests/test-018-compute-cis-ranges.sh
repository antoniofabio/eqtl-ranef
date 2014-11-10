#!/bin/bash -l

set -e
set -u

CIS_WINDOW=0

sort -k2,2 -k3,3g data/genespos.ex1.tab \
    | ../data-cis-ranges \
    <(sort -k2,2 -k3,3g data/snpspos.ex1.tab) \
    ${CIS_WINDOW}
