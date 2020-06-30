% compile_pulseqSBB_Sim
disp('Start compilation...');
csn = mex.getCompilerConfigurations('CPP').ShortName;
if ispc && contains(csn, 'MSVCPP')
    mex CXXOPTIMFLAGS="/O3" -Isrc/3rdParty/eigen-eigen-5a0156e40feb -Isrc/3rdParty/pulseq-master/src/ src/Sim_pulseqSBB.cpp src/SimulationParameters.cpp src/3rdParty/pulseq-master/src/ExternalSequence.cpp
elseif ispc && contains(csn, 'mingw64-g++')
    mex CXXOPTIMFLAGS="-O3" -Isrc/3rdParty/eigen-eigen-5a0156e40feb -Isrc/3rdParty/pulseq-master/src/ src/Sim_pulseqSBB.cpp src/SimulationParameters.cpp src/3rdParty/pulseq-master/src/ExternalSequence.cpp
elseif isunix && contains(csn, 'g++')
    mex CXXOPTIMFLAGS="-O3" -Isrc/3rdParty/eigen-eigen-5a0156e40feb -Isrc/3rdParty/pulseq-master/src/ src/Sim_pulseqSBB.cpp src/SimulationParameters.cpp src/3rdParty/pulseq-master/src/ExternalSequence.cpp
else
    warning('No tested compiler found. Trying to compile...');
    mex -Isrc/3rdParty/eigen-eigen-5a0156e40feb -Isrc/3rdParty/pulseq-master/src/ src/Sim_pulseqSBB.cpp src/SimulationParameters.cpp src/3rdParty/pulseq-master/src/ExternalSequence.cpp
end
