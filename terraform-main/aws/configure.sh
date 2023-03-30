#!/bin/bash
set -e

cd modules 
base=$(pwd)

for f in `find . -type d -d 1`; do 
    ln -sf ${base}/common-variables.tf ${base}/$f/common-variables.tf
done
