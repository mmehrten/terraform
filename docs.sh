#!/bin/bash
set -e

for f in terraform-main/aws/modules/*/ terraform-main/aws/projects/*/ * */*; do 
	if [ ! -d "${f}" ]; then continue; fi 	
	echo $f
	terraform-docs markdown $f > $f/README.md; 
	cd $f 
	terraform fmt
	cd - >/dev/null;
done
