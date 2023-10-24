#!/bin/bash
set -e

for f in terraform-main/aws/projects/*/ *; do 
	echo $f
	cd $f 
	terraform init -reconfigure 
	terraform validate 
	cd -
done
