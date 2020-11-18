#!/bin/bash -e

mkdir -p dummy/constant
nxs=(60 120 240)
nxs=(240 480)
# Generate the mesh for all cases
for type in orthogonal; do
    i=0
    for nx in ${nxs[*]} ; do
        echo $type $nx
        ./runAll/initMesh.sh $type $nx
        let i=$i+1
    done
done

# Initialise all cases
for case in orthogonal/[1-9]* ; do
    ./runAll/init0.sh $case
done

# plot of mesh and initial conditions
case=orthogonal/120x60
gmtFoam -case $case -time 0 TUmesh
ev $case/0/TUmesh.pdf

# Set up cases with different time-steps to be run implicitly or explicitly
# with different schemes
cs=(0.25 0.5 1 2 5 10)
schemes=(upwind MPDATA)
for case in orthogonal/[1-9]*  ; do
    for c in ${cs[*]}; do
        for scheme in ${schemes[*]}; do
            cName=`echo $c | sed 's/\.//g'`
            echo $case $cName $scheme
            ./runAll/initDT.sh $case $c explicit_$scheme
            ./runAll/initDT.sh $case $c implicit_$scheme
            sed 's/SCHEME/'$scheme'/g' dummy/system/fvSchemes | sed 's/IMPLICIT/true/g' \
                 > $case/c${cName}_implicit_${scheme}/system/fvSchemes
            sed 's/SCHEME/'$scheme'/g' dummy/system/fvSchemes | sed 's/IMPLICIT/false/g'\
                 > $case/c${cName}_explicit_${scheme}/system/fvSchemes
        done
    done
done

# run all test cases
for case in orthogonal/[1-9]*/c*plicit* ; do
    nohup scalarDeformation -case $case >& $case/log &
done

exit

# plots for all test cases
for case in orthogonal/[1-9]* ; do
    for time in 5 4 3 2 1 0; do
        gmtFoam -case $case -time $time Traw
        gv $case/$time/Traw.pdf &
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
    for dtType in implicit explicit; do
        rm -f runAll/data/${type}_${res}_${dtType}_errorNormsTmp.dat
        for dir in ${type}/${res}/c*_$dtType; do
            if [ -e $dir/errorNorms.dat ]; then
                grep -h -v '^#' $dir/errorNorms.dat  >> \
                    runAll/data/${type}_${res}_${dtType}_errorNormsTmp.dat
            fi
        done
        echo '#dx dt l1 l2 linf mean var min max' > \
            runAll/data/${type}_${res}_${dtType}_errorNorms.dat
        sort -n runAll/data/${type}_${res}_${dtType}_errorNormsTmp.dat >> \
            runAll/data/${type}_${res}_${dtType}_errorNorms.dat
        rm runAll/data/${type}_${res}_${dtType}_errorNormsTmp.dat
    done
done

#1st and 2nd order lines
mkdir -p runAll/data
echo -e "#dx error1st\n10 1\n0.1 0.01" > runAll/data/1stOrder.dat
echo -e "#dx error2nd\n10 1\n1   0.01" > runAll/data/2ndOrder.dat
echo -e "#dx error3rd\n10 1\n2   0.01" > runAll/data/3rdOrder.dat

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

# pdfs for animations
case=orthogonal/120x60/c1_explicit_cubic
case=orthogonal/120x60/c1_explicit
case=orthogonal/120x60/c2_explicit
case=orthogonal/120x60/c05_explicit_MPDATA
case=orthogonal/120x60/c1_explicit_limitedCubic05
var=Traw
gmtFoam -case $case $var
mkdir -p $case/animategraphics
t=0
for time in `filename $case/[0-9]* | sort -n`; do
    eps2png $case/$time/$var.pdf
    ln -sf ../$time/$var.png $case/animategraphics/${var}_$t.png
    let t=$t+1
done

