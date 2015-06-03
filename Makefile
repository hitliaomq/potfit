############################################################################
#
# potfit -- The ITAP Force Matching Program
# 	Copyright 2002-2014
#
# 	Institute for Theoretical and Applied Physics,
# 	University of Stuttgart, D-70550 Stuttgart, Germany
# 	http://potfit.sourceforge.net/
#
############################################################################
#
#   This file is part of potfit.
#
#   potfit is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   potfit is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with potfit; if not, see <http://www.gnu.org/licenses/>.
#
############################################################################
#
# Beware: This Makefile works only with GNU make (gmake)!
#
# Usage:  make <target>
#
# <target> has the form
#
#    potfit[_<parallel>][_<option>[_<option>...]]
#
# The parallelization method <parallel> can be:
#
#    mpi   compile for parallel execution, using MPI
#
###########################################################################
#
# Customizing this Makefile
#
# As potfit supports a large number of compile options, you will have to
# compile potfit freqently. Before doing so, however, you must check whether
# the settings in this Makefile fit your needs. You possibly have to
# customize these setttings. Before you can do that, we have to explain
# a bit how the compilation process works.
#
# The compilation process requires the SYSTEM variable in the Makefile to be
# set to any of the predefined values. It specifies what system you have, and
# what compiler you are using. The flags for the compiler and the linker
# are then selected as a function of this variable.
#
# Another important ingredient is the parallelization method, which is
# determined from the make target. The parallelization method is stored
# in the variable PARALLEL, which takes as value SERIAL or MPI.
#
# Depending on the value of ${SYSTEM}, a number of variables must be
# set, from which everything else is constructed.
#
# CC_SERIAL defines the compiler for serial compilation, CC_MPI the one
# to be used for parallelization
#
# BIN_DIR defines the directory where the potfit binary is put. Note that
# this directory must exist.
#
# MV defines the program used to move the potfit binary to ${BIN_DIR}.
# The default is mv, which is usually ok.
#
# The compilation options are stored in the variable CFLAGS.
# The initial value of CFLAGS is set to the variable FLAGS,
# which can be given on the command line.
#
# If the option debug was specified, ${DEBUG_FLAGS} is then appended
# to ${CFLAGS}, otherwise ${OPT_FLAGS}. If the option prof was specified
# (for profiling), ${PROF_FLAGS} is also appended to ${CFLAGS}. However,
# before appending ${OPT_FLAGS} or ${DEBUG_FLAGS} to ${CFLAGS}, some
# parallelization specific flags are appended to them:
#
#   OPT_FLAGS   += ${${PARALLEL}_FLAGS} ${OPT_${PARALLEL}_FLAGS}
#   DEBUG_FLAGS += ${${PARALLEL}_FLAGS} ${DEBUG_${PARALLEL}_FLAGS}
#
# If any of these variables is not defined, it is assumed to be empty.
# This setup should provide sufficient flexibility to set one's favorite
# flags, depending on parallelization, profiling, and optimization/debugging.
#
# Similarly, the link libraries are stored in the variable LIBS,
# to which ${${PARALLEL}_LIBS} and possibly ${PROF_LIBS} (for profiling)
# is appended.
#
# You may have to change the setting for an existing value of SYSTEM.
# or you have to add support for a new value of SYSTEM. The latter is
# best done by using the folloing template for SYSTEM=custom:
#
# ifeq (custom,${SYSTEM})
#   CC_SERIAL		= serial-compiler
#   CC_MPI		= MPI-compiler
#   OMPI_CC      	= compiler for mpicc
#   OMPI_CLINKER 	= linker for mpicc
#   OPT_FLAGS		+= generic flags for optimization
#   DEBUG_FLAGS		+= generic flags for debugging
#   PROF_FLAGS		+= flags for profiling
#   PROF_LIBS		+= libraries for profiling
#   LFLAGS_SERIAL 	+= flags for serial linking
#   LFLAGS_MPI 		+= flags for MPI linking
#   export        MPICH_CC MPICH_CLINKER
# endif
#
# Variables remaining empty need not be mentioned.

###########################################################################
#
#  Adjust these variables to your system
#
###########################################################################

# Currently the following systems are available:
# x86_64-icc  	64bit Intel Compiler
# x86_64-gcc    64bit GNU Compiler
# i686-icc 	32bit Intel Compiler
# i686-gcc  	32bit GNU Compiler
# i686-kim  	32bit GNU Compiler
#
#SYSTEM 		= x86_64-icc 	# Use this as fallback
#SYSTEM 		= $(shell uname -m)-icc
SYSTEM 		= i686-kim

# This is the directory where the potfit binary will be moved to.
# If it is empty, the binary will not be moved.
#BIN_DIR 	= ${HOME}/bin
#BIN_DIR 	=

# Base directory of your installation of the MKL or ACML

# General settings
MKLDIR      = /opt/intel/composer_xe_2015.1.133/mkl
ACML4DIR  	= /opt/acml4.4.0/gfortran64
ACML5DIR  	= /opt/acml5.3.1/gfortran64
LIBMDIR 	= /opt/amdlibm

# ITAP settings
#BIN_DIR 	= ${HOME}/bin/i386-linux
#MKLDIR          = /common/linux/paket/intel/compiler-11.0/cc/mkl
#ACML4DIR  	= /common/linux/paket/acml4.4.0/gfortran64

###########################################################################
#
#  Defaults for some variables
#
###########################################################################

MV		= $(shell which mv 2> /dev/null)
STRIP 		= $(shell which strip 2> /dev/null)
LIBS		+= -lm
MPI_FLAGS	+= -DMPI
DEBUG_FLAGS	+= -DDEBUG
ACML4PATH 	= ${ACML4DIR}/lib
ACML5PATH 	= ${ACML5DIR}/lib
RELEASE		= 1

###########################################################################
#
#  flags for 64bit
#
###########################################################################

ifeq (x86_64-icc,${SYSTEM})
# compiler
  CC_SERIAL     = icc
  CC_MPI        = mpicc
  OMPI_CC       = icc
  OMPI_CLINKER  = icc

# general optimization flags
  OPT_FLAGS     += -fast -xHost

# profiling and debug flags
  PROF_FLAGS    += --profile-functions
  PROF_LIBS     += --profile-functions
  DEBUG_FLAGS   += -g -Wall

# Intel Math Kernel Library
ifeq (,$(strip $(findstring acml,${MAKETARGET})))
  CINCLUDE 	+= -I${MKLDIR}/include
  LIBS 		+=  -DMKL_ILP64 -mkl=sequential  -lpthread -lm


endif

# AMD Core Math Library
ifneq (,$(strip $(findstring acml4,${MAKETARGET})))
  CINCLUDE 	+= -I${ACML4DIR}/include
  LIBS		= -L${ACML4PATH} -lpthread -lacml -lacml_mv
endif
ifneq (,$(strip $(findstring acml5,${MAKETARGET})))
   LIBMPATH 	= ${LIBMDIR}/lib/dynamic
   CINCLUDE     += -I${ACML5DIR}/include -I${LIBMDIR}/include
   LIBS		+= -L${ACML5PATH} -L${LIBMPATH} -lpthread -lacml -lamdlibm
endif

 export        OMPI_CC OMPI_CLINKER
endif

ifeq (x86_64-gcc,${SYSTEM})
# compiler
  CC_SERIAL     = gcc
  CC_MPI        = mpicc
  OMPI_CC       = gcc
  OMPI_CLINKER  = gcc

# general optimization flags
  #OPT_FLAGS     += -O3 -march=native -Wno-unused
  OPT_FLAGS     += -O3 -Wno-unused

# profiling and debug flags
  PROF_FLAGS    += -g3 -pg
  PROF_LIBS     += -g3 -pg
  DEBUG_FLAGS   += -g3 -Wall

# Intel Math Kernel Library
ifeq (,$(strip $(findstring acml,${MAKETARGET})))
  CINCLUDE      += -I${MKLDIR}/include
  LIBS 		+= -Wl,--start-group -lmkl_intel_lp64 -lmkl_sequential -lmkl_core \
		   -Wl,--end-group -lpthread -Wl,--as-needed
endif

# AMD Core Math Library
ifneq (,$(strip $(findstring acml4,${MAKETARGET})))
  CINCLUDE     	+= -I${ACML4DIR}/include
  LIBS		+= -L${ACML4PATH} -lpthread -lacml -lacml_mv -Wl,--as-needed
endif
ifneq (,$(strip $(findstring acml5,${MAKETARGET})))
  LIBMPATH 	= ${LIBMDIR}/lib/dynamic
  CINCLUDE     	+= -I${ACML5DIR}/include -I${LIBMDIR}/include
  LIBS		+= -L${ACML5PATH} -L${LIBMPATH} -lpthread -lacml -lamdlibm -Wl,--as-needed
endif

 export        OMPI_CC OMPI_CLINKER
endif


###########################################################################
#
#  flags for 32bit
#
###########################################################################

ifeq (i686-icc,${SYSTEM})
# compiler
  CC_SERIAL	= icc
  CC_MPI	= mpicc
  OMPI_CC       = icc
  OMPI_CLINKER  = icc

# general optimization flags
  OPT_FLAGS	+= -fast -xHost

# profiling and debug flags
  PROF_FLAGS	+= -prof-gen
  PROF_LIBS 	+= -prof-gen
  DEBUG_FLAGS	+= -g -Wall -wd981 -wd1572

# Intel Math Kernel Library
ifeq (,$(strip $(findstring acml,${MAKETARGET})))
  CINCLUDE      += -I${MKLDIR}/include
  LIBS 		+= -Wl,--start-group -lmkl_intel -lmkl_sequential -lmkl_core \
		   -Wl,--end-group -lpthread
endif

# AMD Core Math Library
ifneq (,$(strip $(findstring acml4,${MAKETARGET})))
  CINCLUDE     	+= -I$(ACML4DIR)/include
  LIBS		+= -L${ACML4PATH} -lpthread -lacml
endif
ifneq (,$(strip $(findstring acml5,${MAKETARGET})))
  LIBMPATH 	= ${LIBMDIR}/lib/dynamic
  CINCLUDE     	+= -I$(ACML5DIR)/include -I${LIBMDIR}/include
  LIBS		+= -L${ACML5PATH} -L${LIBMPATH} -lpthread -lacml
endif

  export        OMPI_CC OMPI_CLINKER
endif

ifeq (i686-gcc,${SYSTEM})
# compiler
  CC_SERIAL	= gcc-4.8 -m32
  CC_MPI	= mpicc -m32
  OMPI_CC     	= gcc-4.8 -m32
  OMPI_CLINKER 	= gcc-4.8 -m32

# general optimization flags
  OPT_FLAGS	+= -O3 -Wno-unused
# profiling and debug flags
  PROF_FLAGS	+= -g3 -pg
  PROF_LIBS	+= -g3 -pg
  DEBUG_FLAGS	+= -g3 -Wall

# Intel Math Kernel Library
ifeq (,$(strip $(findstring acml,${MAKETARGET})))
  CINCLUDE      += -I${MKLDIR}/include
#  LIBS		+= -Wl,--start-group -lmkl_intel -lmkl_sequential -lmkl_core \
#		   -Wl,--end-group -lpthread -Wl,--as-needed
  LIBS		+= -lmkl_intel -lmkl_sequential -lmkl_core \
		   -lpthread
endif

# AMD Core Math Library
ifneq (,$(strip $(findstring acml4,${MAKETARGET})))
  CINCLUDE     	+= -I$(ACML4DIR)/include
  LIBS		+= -L${ACML4PATH} -lpthread -lacml -Wl,--as-needed
endif
ifneq (,$(strip $(findstring acml5,${MAKETARGET})))
  LIBMPATH 	= ${LIBMDIR}/lib/dynamic
  CINCLUDE     	+= -I$(ACML5DIR)/include -I${LIBMDIR}/include
  LIBS		+= -L${ACML5PATH} -L${LIBMPATH} -lpthread -lacml -Wl,--as-needed
endif

  export        OMPI_CC OMPI_CLINKER
endif

ifeq (i686-kim,${SYSTEM})
  ifeq ($(shell kim-api-build-config --version),)
	    $(error The utility 'kim-api-build-config' not found on path; Update PATH environment variable appropriately)
  endif

  CC_SERIAL      = $(shell kim-api-build-config --cc)
  CINCLUDE      += $(shell kim-api-build-config --includes)
  FLAGS         += $(shell kim-api-build-config --cflags)
  LFLAGS_SERIAL += $(shell kim-api-build-config --ldflags)
  LIBS          += $(shell kim-api-build-config --ldlibs)

# Intel Math Kernel Library
ifeq (,$(strip $(findstring acml,${MAKETARGET})))
  CINCLUDE      += -I${MKLDIR}/include
 # LIBS		+= -Wl,--start-group -lmkl_sequential -lmkl_core \
#		   -Wl,--end-group -lpthread -Wl,--as-needed
   LIBS   += -Wl,--start-group -lmkl_intel_lp64 -lmkl_sequential -lmkl_core \
					   -Wl,--end-group -lpthread -Wl,--as-needed
endif
endif

###########################################################################
#
#  Parallelization method
#
###########################################################################

# default is serial
PARALLEL = SERIAL
# MPI
ifneq (,$(strip $(findstring mpi,${MAKETARGET})))
PARALLEL = MPI
endif


###########################################################################
#
#  Compiler, flags, libraries
#
###########################################################################

# compiler; if empty, we issue an error later
CC = ${CC_${PARALLEL}}

# optimization flags
OPT_FLAGS   += ${${PARALLEL}_FLAGS} ${OPT_${PARALLEL}_FLAGS} -DNDEBUG
DEBUG_FLAGS += ${${PARALLEL}_FLAGS} ${DEBUG_${PARALLEL}_FLAGS}

# libraries
LIBS += ${${PARALLEL}_LIBS}

# optimization or debug
CFLAGS := ${FLAGS}
ifneq (,$(findstring debug,${MAKETARGET}))
CFLAGS += ${DEBUG_FLAGS}
else
CFLAGS += ${OPT_FLAGS}
endif

# profiling support
ifneq (,$(findstring prof,${MAKETARGET}))
CFLAGS += ${PROF_FLAGS}
LIBS   += ${PROF_LIBS}
endif


###########################################################################
#
# potfit sources
#
###########################################################################

POTFITHDR   	= bracket.h elements.h optimize.h potfit.h potential.h \
		  random.h splines.h utils.h
POTFITSRC 	= bracket.c brent.c config.c elements.c errors.c forces.c linmin.c \
		  param.c potential_input.c potential_output.c potfit.c \
		  powell_lsq.c random.c simann.c splines.c utils.c



# added
###########################################################################
# to compile with kim 
# nothing new, just add kim in the maketarget
# e.g. make potfit_kim
###########################################################################
# if kim


potfit_kim: potfit_apot_pair_kim
					mv potfit_apot_pair_kim potfit_kim
potfit_kim_nolimits: potfit_eam_kim_nolimits
					mv potfit_eam_kim_nolimits potfit_kim_nolimits

ifneq (,$(strip $(findstring kim,${MAKETARGET})))
	
  POTFITSRC      += kim/kim.c kim/free_kim.c kim/force_kim.c
  
  ifneq (,$(strip $(findstring apot,${MAKETARGET})))
    POTFITHDR      += functions.h
    POTFITSRC      += functions.c
    ifneq (,$(strip $(findstring pair,${MAKETARGET})))
      POTFITSRC      += chempot.c
    endif
  endif

  ifneq (,$(strip $(findstring evo,${MAKETARGET})))
    POTFITSRC      += diff_evo.c
  endif

  ifneq (,$(strip $(findstring parab,${MAKETARGET})))
    POTFITSRC      += parabola.c
  endif


else # kim





  ifneq (,$(strip $(findstring pair,${MAKETARGET})))
    POTFITSRC      += force_pair.c 
  endif

  ifneq (,$(strip $(findstring eam,${MAKETARGET})))
    ifneq (,$(strip $(findstring meam,${MAKETARGET})))
      POTFITSRC      += force_meam.c
    else ifneq (,$(strip $(findstring coulomb,${MAKETARGET})))
      POTFITSRC      += force_eam_elstat.c
    else ifneq (,$(strip $(findstring dipole,${MAKETARGET})))
      POTFITSRC      += force_eam_elstat.c
    else
      POTFITSRC      += force_eam.c 
    endif
  endif

  ifneq (,$(strip $(findstring coulomb,${MAKETARGET})))
    ifeq (,$(strip $(findstring eam,${MAKETARGET})))
      POTFITSRC      += force_elstat.c
    endif
  endif

  ifneq (,$(strip $(findstring dipole,${MAKETARGET})))
    ifeq (,$(strip $(findstring eam,${MAKETARGET})))
      POTFITSRC      += force_elstat.c
    endif
  endif

  ifneq (,$(strip $(findstring adp,${MAKETARGET})))
    POTFITSRC      += force_adp.c
  endif

  ifneq (,$(strip $(findstring stiweb,${MAKETARGET})))
    POTFITSRC      += force_stiweb.c
  endif

  ifneq (,$(strip $(findstring tersoff,${MAKETARGET})))
    POTFITSRC      += force_tersoff.c
  endif

  ifneq (,$(strip $(findstring apot,${MAKETARGET})))
    POTFITHDR      += functions.h
    POTFITSRC      += functions.c
    ifneq (,$(strip $(findstring pair,${MAKETARGET})))
      POTFITSRC      += chempot.c
    endif
  else
    ifneq (,$(strip $(findstring meam,${MAKETARGET})))
      POTFITSRC 	+= rescale_meam.c
    else
      POTFITSRC      += rescale.c
    endif
  endif

  ifneq (,$(strip $(findstring evo,${MAKETARGET})))
    POTFITSRC      += diff_evo.c
  endif

  ifneq (,$(strip $(findstring parab,${MAKETARGET})))
    POTFITSRC      += parabola.c
  endif

endif  #kim
# added ends



MPISRC          = mpi_utils.c

#########################################################
#
# potfit Configuration rules
#
#########################################################

HEADERS := ${POTFITHDR}

# serial or mpi
ifneq (,$(strip $(findstring mpi,${MAKETARGET})))
SOURCES	:= ${POTFITSRC} ${MPISRC}
else
SOURCES	:= ${POTFITSRC}
endif

###  INTERACTIONS  #######################################

INTERACTION = 0


# pair interactions
ifneq (,$(findstring pair,${MAKETARGET}))
  CFLAGS += -DPAIR
  INTERACTION = 1
endif

# embedded atom method (EAM) potentials
ifneq (,$(strip $(findstring eam,${MAKETARGET})))
  ifneq (,$(findstring 1,${INTERACTION}))
    ERROR += More than one potential model specified
  endif
  ifneq (,$(strip $(findstring meam,${MAKETARGET})))
    CFLAGS  += -DMEAM
  else ifneq (,$(strip $(findstring tbeam,${MAKETARGET})))
    CFLAGS  += -DTBEAM
  else
    CFLAGS  += -DEAM
  endif
  INTERACTION = 1
endif

# COULOMB
ifneq (,$(strip $(findstring coulomb,${MAKETARGET})))
  ifeq (,$(strip $(findstring eam,${MAKETARGET})))
    ifneq (,$(findstring 1,${INTERACTION}))
      ERROR += More than one potential model specified
    endif
  endif
  ifeq (,$(strip $(findstring apot,${MAKETARGET})))
    ERROR += COULOMB does not support tabulated potentials
  endif
  CFLAGS  += -DCOULOMB
  INTERACTION = 1
endif

# DIPOLE
ifneq (,$(strip $(findstring dipole,${MAKETARGET})))
  ifeq (,$(strip $(findstring eam,${MAKETARGET})))
    ifneq (,$(findstring 1,${INTERACTION}))
      ERROR += More than one potential model specified
    endif
  endif
  ifeq (,$(strip $(findstring apot,${MAKETARGET})))
    ERROR += DIPOLE does not support tabulated potentials
  endif
  CFLAGS  += -DCOULOMB -DDIPOLE
  INTERACTION = 1
endif

# angular dependent potentials (ADP)
ifneq (,$(strip $(findstring adp,${MAKETARGET})))
  ifneq (,$(findstring 1,${INTERACTION}))
    ERROR += More than one potential model specified
  endif
  CFLAGS  += -DADP
  INTERACTION = 1
endif

# Stillinger-Weber potentials (STIWEB)
ifneq (,$(strip $(findstring stiweb,${MAKETARGET})))
  ifneq (,$(findstring 1,${INTERACTION}))
    ERROR += More than one potential model specified
  endif
  ifeq (,$(findstring apot,${MAKETARGET}))
    ERROR += STIWEB does not work without the apot flag
  endif
  CFLAGS  += -DSTIWEB
  INTERACTION = 1
endif

# Tersoff potentials (TERSOFF and TERSOFFMOD)
ifneq (,$(strip $(findstring tersoff,${MAKETARGET})))
  ifneq (,$(findstring 1,${INTERACTION}))
    ERROR += "More than one potential model specified."
  endif
  ifeq (,$(findstring apot,${MAKETARGET}))
    ERROR += "TERSOFF does not work without the apot flag!"
  endif
  ifneq (,$(findstring tersoffmod,${MAKETARGET}))
    CFLAGS += -DTERSOFFMOD
  endif
  CFLAGS  += -DTERSOFF
  INTERACTION = 1
endif

ifneq (,$(findstring 0,${INTERACTION}))
  ERROR += "No interaction model specified."
endif

# EVO - for differential evolution
ifneq (,$(findstring evo,${MAKETARGET}))
CFLAGS += -DEVO
endif

# APOT - for analytic potentials
ifneq (,$(findstring apot,${MAKETARGET}))
  ifneq (,$(findstring resc,${MAKETARGET}))
    ERROR += "Analytic potentials are incompatible with the rescale option!"
  endif
CFLAGS += -DAPOT
endif

# Stress
ifneq (,$(findstring stress,${MAKETARGET}))
CFLAGS += -DSTRESS
endif

# Disable gauge punishments for EAM/ADP
ifneq (,$(findstring nopunish,${MAKETARGET}))
CFLAGS += -DNOPUNISH
endif

ifneq (,$(findstring limit,${MAKETARGET}))
WARNING += "limit is now mandatory -- "
endif

ifneq (,$(findstring parab,${MAKETARGET}))
ERROR += "parab is no longer supported, please remove it from your target -- "
endif

ifneq (,$(findstring wzero,${MAKETARGET}))
ERROR += "wzero is no longer supported, please remove it from your target -- "
endif

ifneq (,$(findstring dist,${MAKETARGET}))
ifeq (,$(findstring MPI,${PARALLEL}))
CFLAGS += -DPDIST
else
ERROR += "dist is not mpi parallelized -- "
endif
endif

ifneq (,$(findstring newscale,${MAKETARGET}))
ERROR += "newscale is no longer supported, please remove it from your target -- "
endif

ifneq (,$(findstring fweight,${MAKETARGET}))
CFLAGS += -DFWEIGHT
endif

ifneq (,$(findstring contrib,${MAKETARGET}))
CFLAGS += -DCONTRIB
endif

# force acml4 or acml5 over acml
ifneq (,$(findstring acml,${MAKETARGET}))
ifeq (,$(findstring acml4,${MAKETARGET}))
ifeq (,$(findstring acml5,${MAKETARGET}))
ERROR += The acml target is obsolete. Please use acml4 or acml5.
endif
endif
endif

ifneq (,$(findstring acml4,${MAKETARGET}))
CFLAGS += -DACML -DACML4
endif

ifneq (,$(findstring acml5,${MAKETARGET}))
CFLAGS += -DACML -DACML5
endif

ifneq (,$(findstring resc,${MAKETARGET}))
CFLAGS += -DRESCALE
endif



############################################
# added    to enable KIM and NOLIMITS in the preprocessor
ifneq (,$(findstring kim,${MAKETARGET}))
  CFLAGS += -DKIM
endif
ifneq (,$(findstring nolimits,${MAKETARGET}))
  CFLAGS += -DNOLIMITS
endif
#added ends#


# Substitute .o for .c to get the names of the object files
OBJECTS := $(subst .c,.o,${SOURCES})

###########################################################################
#
# 	Check for bzr binary
#
###########################################################################

ifneq (,$(shell `which git 2> /dev/null`))
  GIT = 1
else
  GIT = 0
endif

###########################################################################
#
#	 Rules
#
###########################################################################

# all objects depend on headers
${OBJECTS}: ${HEADERS}

# How to compile *.c files
# special rules for force computation
powell_lsq.o: powell_lsq.c
	${CC} ${CFLAGS} ${CINCLUDE} -c powell_lsq.c

# special rules for function evaluation
utils.o: utils.c
	${CC} ${CFLAGS} ${CINCLUDE} -c utils.c

# generic compilation rule
.c.o:
ifeq (,$@)
ifeq (,${MAKETARGET})
	@echo -e "Usage:"
	@echo -e "  make potfit_[interaction]_[options]\n"
	@echo "For more details on compiling potfit please look at the Makefile"
	@exit
endif
else
	${CC} ${CFLAGS} -c $<
endif

# How to link
${MAKETARGET}: ${OBJECTS}
	${CC} ${LFLAGS_${PARALLEL}} -o $@ ${OBJECTS} ${LIBS}
ifneq (,${STRIP})
  ifeq (,$(findstring prof,${MAKETARGET}))
    ifeq (,$(findstring debug,${MAKETARGET}))
#	${STRIP}  -R .comment $@
    endif
  endif
endif
ifneq (,${BIN_DIR})
  ifneq (,${MV})
	${MV} $@ ${BIN_DIR} && rm -f $@
  endif
endif

# First recursion only set the MAKETARGET Variable
.DEFAULT:
ifneq (,${CC})
	${MAKE} MAKETARGET='$@' STAGE2
else
	@echo "There is no compiler defined for this option."
	@echo -e "Please adjust the Makefile.\n"
	@exit
endif

potfit:
	@echo -e "\nError:\tYou cannot compile potfit without any options."
	@echo -e "\tAt least an interaction is required.\n"

# Second recursion sets MAKETARGET variable and compiles
# An empty MAKETARGET variable would create an infinite recursion, so we check
STAGE2:
ifneq (,${ERROR})
	@echo -e "\nError: ${ERROR}\n"
else
ifneq (,${MAKETARGET})
	@echo "${WARNING}"
ifeq (0,${RELEASE})
ifeq (1,${GIT})
	@echo -e "Writing git data to version.h\n"
	@rm -f version.h
	@echo -e "#define VERSION_INFO \"potfit-git (r"`git rev-list HEAD | wc -l`")\"\n" > version.h
else
	@echo -e "Writing fake git data to version.h\n"
	@rm -f version.h
	@echo -e "#define VERSION_INFO \"potfit-`basename ${PWD}` (r ???)\"" > version.h
endif
else
	@rm -f version.h
	@echo  "#define VERSION_INFO \"potfit-0.7.0\"" > version.h
endif
	${MAKE} MAKETARGET='${MAKETARGET}' ${MAKETARGET}
else
	@echo 'No TARGET specified.'
endif
endif
###########################################################################
#
#	 Misc. TARGETs
#
###########################################################################

clean:
	rm -f *.o *.u *~ \#* *.V *.T *.O *.il version.h 

# added 
###########################################################################
# remove kim stuff
###########################################################################
	rm -f  potfit_* kim/*.o
# added ends


help:
	@echo "Usage: make potfit[_<parallel>][_<option>[_<option>...]]"

