#!/bin/bash -i

shopt -s expand_aliases

project_name=$1
sim_type=$2

if [ ! -d 'coverage' ] ; then
	echo "no coverage directory found"
	echo $'creating coverage directory\n'
	mkdir coverage
fi 

cd coverage

xcrg -report_format html -dir ../vivado/$project_name/$project_name.sim/sim_1/behav/xsim/xsim.covdb/
