This code solve DMFT using the exact diagonalization method.
The code is developed by A. Amaricci et al. 
See https://github.com/QcmPlab
If you use the code please cite
Amaricci et al, "EDIpack: A parallel exact diagonalization package for quantum impurity problems" arXiv 2105.06806

This version of the code makes use of three libraries.

COMPILATION OF THE LIBRARIES

#enter the directory LIBS
$ cd LIBS

#create an opt dir
$ mkdir opt

*)SciFortran
https://github.com/QcmPlab/SciFortran
This library is a collection of fortran modules and procedures for scientific calculations. Loosely inspired by scipy.

#enter SciFortran
$ cd SciFortran

#create a build directory and enter
$ mkdir build; cd build

$ cmake ../ -DPREFIX=../../opt
$ make
$ make install

#add the library to the system
$ export PKG_CONFIG_PATH={your_path}/TOOLbox_unige2021/DMFT_ExactDiagonalization/LIBS/opt/scifor/gnu/4.7.3/etc/:$PKG_CONFIG_PATH
$ pkg-config --cflags --libs scifor
 

*) DMFTtools
https://github.com/QcmPlab/DMFTtools
collection of fortran modules and routines useful for DMFT.

#enter DMFTtools
$ cd DMFTtools

#create a build directory and enter
$ mkdir build; cd build

$ cmake ../ -DPREFIX=../../opt
$ make
$ make install


#add the library to the system
export PKG_CONFIG_PATH={your_path}/TOOLbox_unige2021/DMFT_ExactDiagonalization/LIBS/opt/dmft_tools/gnu/2.2.3/etc/:$PKG_CONFIG_PATH
$ pkg-config --cflags --libs scifor

*)LIB_DMFT_ED 
https://github.com/QcmPlab/LIB_DMFT_ED
A serial/parallel Lanczos based method for the solution of single-site Quantum Impurity problems, with a special application as Dynamical Mean-Field Theory solver.

$ cd LIB_DMFT_ED

#create a build directory and enter
$ mkdir build; cd build

$ cmake ../ -DPREFIX=../../opt
$ make
$ make install


#add the library to the system
$ export PKG_CONFIG_PATH=/Users/giacomo/project_src/TOOLbox_unige2021/DMFT_ExactDiagonalization/LIBS/opt/dmft_ed/gnu/0.1.1/etc/:$PKG_CONFIG_PATH
$ pkg-config --cflags --libs dmft_ed


#COMPILATION OF THE CODE

#enter the ED_superconductivity/SRC directory

#compile the code
$ make

#this command creates an executable ed_ahm_bethe inside the same dir. 

# RUN THE CODE

in the directory DATA/init_run/ you find
- inputAHM.conf  (input file)
- hamiltonian.restart (resonable hamiltonian to start a run for uloc \sim -2.0)
- run.sh   (bash script to lunch run at different U in series)


enjoy!