#!/bin/bash -e
# Set up an existing test case with a sub-directory for a specific time-step
# to give a specific Courant number, c

if [ "$#" -ne 3 ]
then
   echo usage: initDT.sh case c newName
   exit
fi

# arguments
case=$1
c=$2
newName=$3
cName=`echo $c | sed 's/\.//g'`

# derived from arguments (nx and time-step)
nx=`echo $case | awk -F'/' '{print $2}' | awk -Fx '{print $1}'`
dt=`echo $c $nx | awk '{print $1/$2*60/100.}'`

# Create sub-case
newCase=$case/c${cName}_${newName}
mkdir $newCase
ln -s ../constant $newCase/constant
ln -s ../0 $newCase/0
cp -r $case/system $newCase
sed -e 's/DELTAT/'$dt'/g' dummy/system/controlDict > $newCase/system/controlDict
