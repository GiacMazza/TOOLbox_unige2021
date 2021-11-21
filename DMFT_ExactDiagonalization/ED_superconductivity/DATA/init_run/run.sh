#!/bin/bash                                                                      

EXE=ed_ahm_bethe
EXEDIR=Users/giacomo/project_src/TOOLbox_unige2021/DMFT_ExactDiagonalization/ED_superconductivity/SRC/
NBATH=6

HRESTART=hamiltonian.restart

run()
{
    VAR=$1
    U=${VAR}
    HERE=`pwd`
    DIR=$HERE/uloc${U}
    HDIR=${HERE}/hrestart
    if [ ! -d $DIR ] 
    then
	mkdir -p ${DIR}    
	cd ${DIR}	
	#!
	cp $HERE/inputAHM.conf .
	#
	#
	# check for a directory for reading the hamiltonian.restart
	if [ -d ${HDIR} ]
	then
	    cp ${HDIR}/${HRESTART} .
	else
	    echo 'hrestart does not exist'
	    mkdir ${DIR}
	fi
	#
	# store the seed used in the calculation
	mkdir -p Hseed
	cp ${HRESTART} Hseed
	#
	TIME=`date`
	echo "start @ '${TIME}'"
	${EXEDIR}/${EXE} ULOC=${U},0,0 NBATH=${NBATH} > LOG.file 2>&1
	TIME=`date`
	echo "stop @ '${TIME}'"	
	#
	cp ${HRESTART} ${HDIR}
	cd $HERE
    else
	echo 'skip'
    fi

}

RANGE_FILE=list_u
VARLIST=`sed -n 'p;' $RANGE_FILE` #TRANSFORMS A LIST FILE INTO A ROW LIST
for VAR in $VARLIST;
do    
    run $VAR
done
