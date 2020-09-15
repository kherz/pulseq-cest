# Simple CMake file for Sim_pulseqSBB mex-file creation
# Kai Herz, 2020

cmake_minimum_required(VERSION 3.18.0)

project(Sim_pulseqSBB)

# need c++11 standards
set (CMAKE_CXX_STANDARD 11)

# O2 is faster than O3, but CMAKE makes O3 standard for GCC
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
   string(REPLACE "-O3 " "" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
   set(CMAKE_CXX_FLAGS_RELEASE "-O2 ${CMAKE_CXX_FLAGS_RELEASE}")
endif()

#specify build type
if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE Release)
endif()

# we need matlab
find_package(Matlab REQUIRED)

include_directories(3rdParty/eigen-eigen-5a0156e40feb)
include_directories(3rdParty/pulseq-master/src)
include_directories(Matlab_INCLUDE_DIRS)

set(SOURCE_FILES Sim_pulseqSBB.cpp
                 BlochMcConnellSolver.h
                 Sim_pulseqSBB_T.h
				 SimulationParameters.h
				 SimulationParameters.cpp
				 3rdParty/pulseq-master/src/ExternalSequence.cpp)
			 		
matlab_add_mex(NAME Sim_pulseqSBB SRC ${SOURCE_FILES})

