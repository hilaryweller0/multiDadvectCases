#!/bin/bash -e

# run all test cases
cs=(05 1 2 5 10)
for c in ${cs[*]}; do
    for res in 480x240 960x480 1920x960; do
        for rootCase in orthogonal nonOrthogW; do
            case=$rootCase/$res/c${c}_implicit
            scalarDeformationWithGhosts implicit -case $case >& $case/log &
            sleep 1
            case=$rootCase/$res/c${c}_explicit
            scalarDeformationWithGhosts explicit -case $case >& $case/log
        done
    done
done
