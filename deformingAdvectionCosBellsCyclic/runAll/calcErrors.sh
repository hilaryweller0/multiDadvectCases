#!/bin/bash -e

if [ "$#" -ne 1 ]
then
   echo usage: calcErrors.sh case
   exit
fi

case=$1

# Difference between initial and final conditions
endTime=5
sumFields -case $case $endTime TDiff $endTime T 0 T -scale0 1 -scale1 -1


# Calculate error metrics
globalSum -case $case T -time 0
mv $case/globalSumT.dat $case/globalSumT0.dat
globalSum -case $case T -time $endTime
mv $case/globalSumT.dat $case/globalSumT$endTime.dat
globalSum -case $case TDiff -time $endTime

# Find dx and dt
nx=`echo $case | awk -F "/" '{print $2}' | awk -F "x" '{print $1}'`
dx=`echo $nx | awk '{print 360/$1}'`
dt=`grep deltaT $case/system/controlDict | awk '{print $2'} \
    | awk -F';' '{print $1'}`

echo '#dx dt l1 l2 linf mean var min max' > $case/errorNorms.dat
paste $case/globalSumTDiff.dat $case/globalSumT0.dat \
      $case/globalSumT$endTime.dat | tail -1 |\
    awk '{print '$dx', '$dt', $2/$10, $3/$11, $4/$12, $5/$13, $6/$14, $23, $24}' \
    >> $case/errorNorms.dat

cat $case/errorNorms.dat
