#!/bin/bash -e
# Set up a test case either orthogonal or non-orthogonal with a given resolution
# without a specific time-step

if [ "$#" -ne 2 ]
then
   echo usage: initMesh.sh orthogonal'|'nonOrthog nx
   exit
fi

type=$1
let nx=$2*2
nz=$2
case=${type}/${nx}x${nz}
dt=1

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
else
    echo in init.sh 'type<orthogonal|nonOrthog>' nx
    echo type must be one of orthogonal or nonOrthog, not $type
    exit
fi

# Generate the case for a mesh on the sphere with the correct time-step
cp -r dummy/system dummy/constant $case
sed -i -e 's/NX/'$NX'/g' -e 's/NZ/'$NZ'/g' -e 's/AM/'$AM'/g' -e 's/AP/'$AP'/g' \
    -e 's/SQUEEZE/'$SQUEEZE'/g' -e 's/EXPAND/'$EXPAND'/g' \
    $case/system/blockMeshDict
sed -e 's/DELTAT/'$dt'/g' dummy/system/controlDict > $case/system/controlDict

# Generate the mesh on a plane
blockMesh -case $case

# link to the gmtDicts directory
ln -s ../../../gmtDicts $case/constant/gmtDicts
