#!/bin/bash

# AVR GNU development tools install script
# $Id: buildavr.sh,v 1.21 2004/11/09 02:25:48 rmoffitt Exp $
# Modified by AJ Erasmus    2005/03/22
# Use the same source and patches as for WinAVR 20050214
# Updated script to compile the C and C++ compilers, as well
# as allow the output of dwarf-2 debug information 2005/03/25
# Updated script to add new devices 2005/03/26

# modified and updated 2014,2015 by Ralph Doncaster to build only
# binutils, avr-gcc and avr-libc

# Copyright (C) 2003-2004 Rod Moffitt rod@rod.info http://rod.info
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

# run the script as is to get a list of the files necessary to build,
# takes optionally three arguments, the location of the source files,
# where to install and build the tools and the path where to output a
# log file

# start of configuration, edit these defaults to suit your environment, or
# simply override them via the command line - you will need write
# permission to $prefix (make sure it's empty or non-existent!)

# location of source tarballs
archive=${PWD}

#
#Save base/build dir
#
base=${PWD}
patchdir="$base/patches"

#
# Check , then get package versions 
#
if [ ! -e ${base}/package-versions ]
then
echo The file ${base}/package-versions must exist 
exit 1
fi
#

#
# Get package versions 
#
source ${base}/package-versions
#

# GNU tools will be installed under this directory
#prefix=${prefix:-/usr/local/target}
prefix=/usr/local/xtensa

# build log file - see this if any errors occur
buildlog=/tmp/buildgcc.log

# what are we building for?
target=xtensa

# default configure flags
configureflags='--prefix=$prefix --quiet --with-dwarf2 --disable-nls --disable-werror CFLAGS="-Wno-format-security "'

# end of configuration


function buildandinstall()
{
   mkdir -p $prefix/source $prefix/build

   cd $prefix/source

   if [ ! -e ${base}/ok-build-${binutilsbase} ] 
   then
   echo "($0) installing binutils source"
   tar xf $archive/${binutilstar}
   cerror "binutils source installation failed"

   cd ${binutilsbase}

#   echo "($0) patching binutils source"

#
#for file in $patchdir/${binutilsbase}/*; do
#    echo "Patching with $file"
#    patch -p0 < $file
#    cerror "binutils patching failed"
#done
#

#

   mkdir -p ../../build/${binutilsbase}
   cd ../../build/${binutilsbase}

   echo "($0) configuring binutils source"
   ../../source/${binutilsbase}/configure -v --target=${target} \
      --prefix=$prefix --quiet --enable-install-libbfd --with-dwarf2 --disable-werror CFLAGS="-Wno-format-security "
   cerror "binutils configuration failed"

#  Hack to prevent docs to be build , it will fail if texinfo is v5.xx (as in Mint 17)
#   echo "MAKEINFO = :" >> Makefile 

   echo "($0) building binutils"
   make -j${Cores} all 
   make install clean
   cerror "binutils build failed"
   touch ${base}/ok-build-${binutilsbase}
   fi

   #
   # path to the newly installed binutils is needed to build GCC
   #
   PATH=$prefix/bin:$PATH
   # two lines below special for Ubuntu 
   LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
   LD_RUN_PATH=$PREFIX/lib:$LD_RUN_PATH
   export PATH
   export LD_LIBRARY_PATH
   export LD_RUN_PATH

   cd $prefix/source

   if [ ! -e ${base}/ok-build-${gccbase} ] 
   then
   echo "($0) installing GMP source"
   tar xf $archive/${gmptar}
   cerror "GMP source installation failed"

   echo "($0) installing mpfr source"
   tar xf $archive/${mpfrtar}
   cerror "MPFR source installation failed"

   echo "($0) installing mpc source"
   tar xf $archive/${mpctar}
   cerror "MPC source installation failed"

   echo "($0) installing GCC source"
   tar xf $archive/${gcccoretar}
   cerror "GCC source installation failed"

   #
   # Copy GMP & MPFR sources into GCC directory
   #
   rm -rf ${gccbase}/gmp
   rm -rf ${gccbase}/mpfr
   rm -rf ${gccbase}/mpc
   mkdir -p ${gccbase}/gmp
   mkdir -p ${gccbase}/mpfr
   mkdir -p ${gccbase}/mpc

   cp -rfp ${gmpbase}/* ${gccbase}/gmp
   cp -rfp ${mpfrbase}/* ${gccbase}/mpfr
   cp -rfp ${mpcbase}/* ${gccbase}/mpc

   cd $prefix/source
   cd ${gccbase}
#
#
#   echo "($0) patching GCC source"
#
#for file in $patchdir/${gccbase}/*; do
#    echo "Patching with $file"
#    patch -p0 < $file
#    cerror "gcc patching failed"
#done

#
# MPFR 	 requires a cumulative patchfile (Might not be needed for other versions) 
# http://www.mpfr.org/mpfr-current/ 
#
   #cd $prefix/source
   #cd ${gccbase}/mpfr
#
#
#   echo "($0) patching MPFR source"
#

#for file in $patchdir/${mpfrbase}/*; do
#    echo "Patching with $file"
#    patch -N -Z -p1 < $file
#    cerror "mpfr patching failed"
#done
#  

#
   cd $prefix/source
   cd ${gccbase}
#
   mkdir -p ../../build/${gcccore}
   cd ../../build/${gcccore}

   echo "($0) configuring GCC source"
   ../../source/${gccbase}/configure -v --target=${target} --disable-nls \
      --without-mpc --without-mpfr --without-gmp --with-gnu-ld --with-gnu-as --prefix=$prefix --enable-languages="c,c++" --with-dwarf2 
#      --with-gnu-ld --with-gnu-as --prefix=$prefix --enable-languages="c,c++" --with-dwarf2 
   cerror "GCC configuration failed"

#  Hack to prevent docs to be build , it will fail if texinfo is v5.xx (as in Mint 17)
#   echo "MAKEINFO = :" >> Makefile 

   echo "($0) building GCC"
#   make all install clean LANGUAGES="c obj-c++"
   make -j${Cores} all LANGUAGES="c c++"
   make install clean
   cerror "GCC build failed"
   touch ${base}/ok-build-${gccbase}
   fi

#
#
#
#   cd $prefix/source

#   if [ ! -e ${base}/ok-build-${avrlibcbase} ] 
#   then
#   echo "($0) installing libc"
#   tar xf $archive/${avrlibctar}
#   cerror "libc source installation failed"

#
# Drop avr-libc patching for now , i cant get the Atmel sources to work
# We are skipping support for the xmega32x1 & xmega128b1
# See - avrlibc : http://distribute.atmel.no/tools/opensource/avr-gcc/
#
#   cd $prefix/source
#   cd ${avrlibcbase}
#
   echo "($0) patching libc source"
#
#
#for file in $patchdir/${avrlibcbase}/*; do
#    echo "Patching with $file"
#    patch -p0 < $file
#    cerror "libc patching failed"
#done
#  

#   cd $prefix/source
#   cd ${avrlibcbase}

#   sh reconf
#   sh doconf
#   ./bootstrap
#   cerror "libc source setup failed"

#   mkdir -p ../../build/${avrlibcbase}
#   cd ../../build/${avrlibcbase}
#
#   echo "($0) configuring libc source"
#   CC=$prefix/bin/avr-gcc ../../source/${avrlibcbase}/configure -v \
#      --build=`../../source/${avrlibcbase}/config.guess` --target=${target} --host=avr --prefix=$prefix --quiet
#   cerror "libc configuration failed"

#   echo "($0) building libc"
#   make -j${Cores} all
#   make install clean
#   cerror "libc build failed"
#   touch ${base}/ok-build-${avrlibcbase}

#   fi  # libcbase

   # strip all the binaries
   find $prefix -type d -name bin -exec find \{\} -type f \; | xargs strip > /dev/null 2>&1

   cecho "\n"
   cecho "${cyan}installation of ${target} GNU tools complete\n"
   cecho "${cyan}add ${GREEN}$prefix/bin${cyan} to your path to use the ${target} GNU tools\n"
   cecho "${cyan}you might want to run the following to save disk space:\n"
   cecho "\n"
   cecho "${green}rm -rf $prefix/source $prefix/build\n"
}

# color definitions
RED='\e[1;31m'
green='\e[0;32m'
GREEN='\e[1;32m'
cyan='\e[0;36m'
yellow='\e[0;33m'
NC='\e[0m' # no color

function cecho()
{
   echo -ne "($green$0$NC) $1$NC"
}

function cerror()
{
   if [ $? -ne 0 ];
   then
      cecho "$RED$1$NC\n"
      exit
   fi
}

function ask()
{
   cecho "$@ [y/n] "
   read ans

   case "$ans" in
      y*|Y*) return 0 ;;
      *) return 1 ;;
   esac
}

# source command line overrides

until [ -z "$1" ];
do
   eval "$1"
   shift
done

cecho "${cyan}about to build and install ${target} GNU development tools using\n"
cecho "${cyan}the following settings (override via the command line):\n"
cecho "\n"
cecho "   ${yellow}archive=${archive} $cyan(location of source tarballs)\n"
cecho "   ${yellow}prefix=${prefix} $cyan(installation prefix/directory)\n"
cecho "   ${yellow}buildlog=${buildlog} $cyan(build log)\n"
cecho "\n"
ask "${cyan}proceed?";

if [ "$?" -eq 1 ]
then
   exit
fi

# check on target directory

if [ -d $prefix ];
then
   cecho "\n"
   ask "${RED}$prefix already exists, continue?";

   if [ "$?" -eq 1 ]
   then
      exit
   fi
fi

mkdir -p $prefix 2> /dev/null

if [ ! -w $prefix ];
then
   cecho "\n"
   cecho "${RED}failed! to create install directory $prefix\n";
   exit
fi

# check for required files

missingfiles=;

for file in $sourcefiles;
do
   if [ ! -f $archive/$file ];
   then
      missingfiles="${missingfiles} $file";
   fi
done

if [ -n "$missingfiles" ];
then
   cecho "\n"
   cecho "${RED}error! required source file(s):\n";
   cecho "\n"

   for file in $missingfiles;
   do
      cecho "   ${yellow}$file\n"
   done

   cecho "\n"
   cecho "${cyan}were missing - download them to $archive first\n";
   exit
fi

buildandinstall 2>&1 | tee $buildlog

exit

