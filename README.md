# TOOLbox DMFT unige2021 - Giacomo Mazza #

The toolbox is organised as follow:

Mon 22  : general presentation of the DMFT 
Tue 23  : hands-on part 

For the hands on part you need to have installed in your computer the following items.
If you don't have it already follow these simple instructions.

1) a Fortran compiler, i.e. gfortran > 4.9x  
	#linux
	$ sudo apt-get install gcc
	  
	#MacOs
	$ sudo brew install gcc

2) cmake > 3.0.0 
	#linux
	$sudo apt-get install cmake
	      
	#MacOS
	$sudo brew install make

3) mpi implementation
	#linux
	$sudo apt-get install mpich
	      
	#MacOS
	$sudo brew install mpich
	      
	
*) lapack (optional)
*) blas   (optional)








We will use a DMFT code based on the exact diagonalization method, developed by A. Amaricci et al. 
See https://github.com/QcmPlab

The code makes use of three libraries 

*)SciFortran

https://github.com/QcmPlab/SciFortran
This library is a collection of fortran modules and procedures for scientific calculations.

*)DMFTtools

https://github.com/QcmPlab/DMFTtools
collection of fortran modules and routines useful for DMFT.


*)LIB_DMFT_ED 

https://github.com/QcmPlab/LIB_DMFT_ED
A serial/parallel Lanczos based method for the solution of single-site Quantum Impurity problems, with a special application as Dynamical Mean-Field Theory solver.


STEP 0/

~~~~~~~ Do not give a choice. Creating a local directory is much better.  + mkdir opt

Go to the directory DMFT_toolbox and chose a directory where to install the libraries.

By default the libraries are installed in the ${HOME}/opt.
However, I suggest that you create a 'opt' directory inside DMFT_toolbox


STEP 1/ Install and compile the libraries.

SciFortran

#Enter SciFortran
$ mkdir build; cd build # create a directory inside Scifortran
$ cmake .. -DPREFIX=../../opt
$ make  
$ make install

# At this point there should be a new directory ${path_to_the_opt_directory_you_created_above}/scifor

!!!!(use 3 method only)

# ADD the library to your system. 
export PKG_CONFIG_PATH=${path_to_the_opt_directory_you_created_above}/scifor/gnu/${ver}//etc/:$PKG_CONFIG_PATH
pkg-config --cflags --libs scifor




DMFTtools
#Enter DMFTtools
$ mkdir build # create a directory inside DMFTtools
$ cd build
$ cmake .. -DPREFIX={path_to_the_opt_directory_you_created_above}
$ make  
$ make install

# At this point there should be a new directory ${path_to_the_opt_directory_you_created_above}/dmft_tools
# ADD the library to your system as before: follow instruction on terminal.

LIB_DMFT_ED
# Enter LIB_DMFT_ED
$ mkdir build # create a directory inside LIB_DMFT_ED
$ cd build
$ cmake .. -DPREFIX={path_to_the_opt_directory_you_created_above}
$ make  
$ make install

export to bashrc


# At this point there should be a new directory ${path_to_the_opt_directory_you_created_above}/lib_dmft_ed
# ADD the library to your system as before: follow instruction on terminal.
 

STEP 2/ compile the drivers for the examples.
STEP 2.0/ Choose a directory where to put the executable [this is up to you].
#Change name of directory - EX1/EX2

mkdir bin


STEP 2.1/ enter the directory of the example and actually compile it.
ed_ahm_bethe

#Enter the directory. You'll find inside 
-ed_ahm_bethe.f90 [this is the driver]
-Makefile        [this is the makefile] 

#open the Makefile

change makefile
Fill "FC=" with your compiler (e.g. FC=gfotran or FC=ifort or FC=mpif90, the latter only if you have mpi)
FILL "PLAT=" with "PLAT=gnu" (if you use gfortran or mpi) or "PLAT=intel" (if you use ifort)
Fill "DIREXE=" with the path to the directory you chose at step 2.0 (e.g. in my case I do "DIREXE=${HOME}/.bin/")

$ make

./EX1 
the make command compile the driver and you'll find the executable ed_ahm_bethe in the directory you chose at point 2.0

If you did everything correctly you can now enjoy and start playing!



