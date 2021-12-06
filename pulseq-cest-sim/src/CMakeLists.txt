# Simple CMake file for Sim_pulseqSBB mex-file creation
# Kai Herz, 2020

cmake_minimum_required(VERSION 3.18.0)

project(pulseqcestmex)

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
include_directories(Matlab_INCLUDE_DIRS)

# and eigen
set(EIGEN_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/3rdParty/eigen3/Eigen CACHE PATH "eigen source directory")
if(EXISTS ${EIGEN_SRC_DIR})
   include_directories(${EIGEN_SRC_DIR})
else()
   message(FATAL_ERROR "eigen not found in expected folder, please specify path to eigen src directory" ...)
endif()

# and pulseq
set(PULSEQ_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../pulseq/src/ CACHE PATH "Pulseq src directory")
if(EXISTS ${PULSEQ_SRC_DIR})
   include_directories(${PULSEQ_SRC_DIR})
else()
   message(FATAL_ERROR "Pulseq not found in expected folder, please specify path to Pulseq src directory" ...)
endif()


set(SOURCE_FILES PulseqCESTmex.cpp
                 BlochMcConnellSolver.h
                 SimulationParameters.h
                 SimulationParameters.cpp
                 BMCSim.h
                 BMCSim.cpp
                 ${PULSEQ_SRC_DIR}/ExternalSequence.h
                 ${PULSEQ_SRC_DIR}/ExternalSequence.cpp)
				 
matlab_add_mex(NAME pulseqcestmex SRC ${SOURCE_FILES})
