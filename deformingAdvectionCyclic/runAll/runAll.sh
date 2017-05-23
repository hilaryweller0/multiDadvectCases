#!/bin/bash -e

nxs=(60 120 240 480 960)
# Generate the mesh for all cases
for type in orthogonal nonOrthogW; do
    i=0
    for nx in ${nxs[*]} ; do
        echo $type $nx
        ./runAll/initMesh.sh $type $nx
        let i=$i+1
    done
done

# Initialise all cases
for case in orthogonal/[1-9]* nonOrthogW/[1-9]* ; do
    ./runAll/init0.sh $case
done

# plot of mesh and initial conditions
case=nonOrthogW/120x60
gmtFoam -case $case -time 0 TUmesh
ev $case/0/TUmesh.pdf

#rm -r orthogonal/[1-9]*/c*plicit nonOrthogW/[1-9]*/c*plicit

# Set up cases with different time-steps to be run implicitly or explicitly
cs=(0.5 1 2 5 10)
for case in orthogonal/[1-9]* nonOrthogW/[1-9]* ; do
	for c in ${cs[*]}; do
        echo $case $c
        ./runAll/initDT.sh $case $c explicit
        ./runAll/initDT.sh $case $c implicit
	done
done

# run all test cases
cs=(05 1 2 5 10)
for c in ${cs[*]}; do
    #for rootCase in orthogonal/[1-9]* nonOrthogW/[1-9]* ; do
    for rootCase in orthogonal/240x120 nonOrthogW/240x120 ; do
        case=$rootCase/c${c}_implicit
        nohup scalarDeformationWithGhosts implicit -case $case >& $case/log &
        sleep 1
        case=$rootCase/c${c}_explicit
        nohup scalarDeformationWithGhosts explicit -case $case >& $case/log &
    done
done

exit

# plots for all test cases
for case in orthogonal/[1-9]* nonOrthogW/[1-9]* ; do
    for time in 5 4 3 2 1 0; do
        gmtFoam -case $case -time $time T
        gv $case/$time/T.pdf &
    done
done

# Cacluate error measures for all cases (as necessary)
for case in */[1-9]*/c*plicit; do
    if [ -e $case/5/T ] && [ ! -e $case/errorNorms.dat ]; then
        ./runAll/calcErrors.sh $case
    fi
done


# plot errors
# assemble errors for convergence with resolution
for dir in orthog* nonOrthog*; do
    for dt in c1_implicit c10_implicit c1_explicit; do
        cat $dir/*/$dt/errorNorms.dat | head -1 > $dir/${dt}_errorNorms.dat
        grep -h -v '^#' $dir/*/$dt/errorNorms.dat | sort -n >> $dir/${dt}_errorNorms.dat
    done
done

# assemble errors for convergence with time-step
res=120x60
for type in orthogonal nonOrthogW; do
    rm -f runAll/data/${type}_${res}_errorNormsTmp.dat
    for dir in ${type}*; do
        grep -h -v '^#' $dir/$res/errorNorms.dat  >> \
            runAll/data/${type}_${res}_errorNormsTmp.dat
    done
    echo '#dx dt l1 l2 linf mean var min max' > \
        runAll/data/${type}_${res}_errorNorms.dat
    sort -n runAll/data/${type}_${res}_errorNormsTmp.dat >> \
        runAll/data/${type}_${res}_errorNorms.dat
    rm runAll/data/${type}_${res}_errorNormsTmp.dat
done

#1st and 2nd order lines
mkdir -p runAll/data
echo -e "#dx error1st\n10 1\n0.1 0.01" > runAll/data/1stOrder.dat
echo -e "#dx error2nd\n10 1\n0.316 1e-3" > runAll/data/2ndOrder.dat
echo -e "#dx error3rd\n10 1\n1 1e-3" > runAll/data/3rdOrder.dat

# create plots
mkdir -p plots
#gmtPlot runAll/plotl2.gmt
#gmtPlot runAll/plotlinf.gmt
gmtPlot runAll/plotl2_c1.gmt
gmtPlot runAll/plotlinf_c1.gmt
gmtPlot runAll/plotl2_c10.gmt
gmtPlot runAll/plotlinf_c10.gmt
gmtPlot runAll/plotl2_dt.gmt
gmtPlot runAll/plotlinf_dt.gmt

## Plot a load of results
#for case in */100x100/dt* */400x400/dt_2.5 ; do
#    ./runAll/plotResults.sh $case
#done

# Number of iterations
for case in *thog*/[1-9]*; do
    nIts=`grep Iterations $case/log | \
          awk 'BEGIN {sum=0} {sum=sum+$15} END{print sum}'`
    nTs=`grep Courant $case/log | wc | awk '{print $1-1}'`
    nItsPerDT=`echo $nIts $nTs | awk '{print $1/$2}'`

    echo $nIts $nItsPerDT > $case/nIterations.dat
done
for type in *thog*; do
    echo '#' case totalIts perDt > $type/nIterations.dat
    for case in $type/[1-9]*; do
        echo $case | paste - $case/nIterations.dat \
            >> $type/nIterations.dat
    done
done

