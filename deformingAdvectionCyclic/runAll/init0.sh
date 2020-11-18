#!/bin/bash -e
# Set up a initial conditions of a test case

if [ "$#" -ne 1 ]
then
   echo usage: init0.sh case
   exit
fi

case=$1

# Create the initial conditions
cp -r dummy/0/* $case/0
setGaussians -case $case setGaussiansDict
#setInitialTracerField -case $case

