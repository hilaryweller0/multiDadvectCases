#!/bin/bash -e

if [ "$#" -ne 4 ]
then
   echo usage: init.sh orthogonal'|'nonOrthog'|'nonOrthogW nx deltaT c
   exit
fi

type=$1
let nx=$2*2
nz=$2
dt=$3
c=$4
case=${type}_c$c/${nx}x${nz}

rm -rf $case
mkdir -p $case

# derived properties
# number of grid points in half of the domain
let NX=$nx/2
let NZ=$nz/2
SQUEEZE=1
EXPAND=1
AM=0
AP=0
if [ "$type" == "orthogonal" ]; then
    echo orthogonal case
elif [ "$type" == "nonOrthog" ]; then
    echo non-orthogonal case
    SQUEEZE=0.5
    EXPAND=2
    AM=-0.144337567
    AP=0.144337567
elif [ "$type" == "nonOrthogW" ]; then
    echo non-orthogonal W case
    SQUEEZE=0.5
    EXPAND=2
    AM=-0.144337567
    AP=0.144337567
    let NX=$NX/2
else
    echo in init.sh 'type<orthogonal|nonOrthog|nonOrthogW>' nx deltaT
    echo type must be one of orthogonal or nonOrthog, not $type
    exit
fi

# Generate the case for a mesh on the sphere with the correct time-step
cp -r dummy/system dummy/constant $case
sed -i -e 's/NX/'$NX'/g' -e 's/NZ/'$NZ'/g' -e 's/AM/'$AM'/g' -e 's/AP/'$AP'/g' \
    -e 's/SQUEEZE/'$SQUEEZE'/g' -e 's/EXPAND/'$EXPAND'/g' \
    $case/system/blockMeshDict
if [ "$type" == "nonOrthogW" ]; then
    sed -e 's/NX/'$NX'/g' -e 's/NZ/'$NZ'/g' -e 's/AM/'$AM'/g' -e 's/AP/'$AP'/g' \
    -e 's/SQUEEZE/'$SQUEEZE'/g' -e 's/EXPAND/'$EXPAND'/g' \
    dummy/system/blockMeshDictW \
     > $case/system/blockMeshDict
fi
sed -e 's/DELTAT/'$dt'/g' dummy/system/controlDict > $case/system/controlDict

# Generate the mesh on a plane
blockMesh -case $case

# Create the initial conditions
cp -r dummy/0 $case
setGaussians -case $case setGaussiansDict
#gmtFoam -case $case UT
#gv $case/0/UT.pdf &

# create the ghost mesh
createGhostMesh 3 -case $case
stitchMesh -case $case -perfect -overwrite -region ghostMesh inlet outlet2
stitchMesh -case $case -perfect -overwrite -region ghostMesh outlet inlet1

