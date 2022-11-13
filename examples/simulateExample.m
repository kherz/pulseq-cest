% This function runs the standard simulation for the example files 
%
% kai.herz@tuebingen.mpg.de

%% filenames
% .seq-file: This file contains the saturation period
seq_fn   = which('APTw_3T_example.seq'); 
% .yaml-file: This file contains all the simulation settings
param_fn = which('GM_3T_example_bmsim.yaml'); 

%% run simulation
M_z = simulate_pulseqcest(seq_fn, param_fn);

%% read the .seq-file definitions
definitions = readSequenceDefinitions(seq_fn);

% get the definitions in the file
offsets_ppm = definitions('offsets_ppm'); % offsets
m0_offset = definitions('M0_offset');     % m0 offset frequency

figure(1);
Z = plotSimulationResults(M_z,offsets_ppm,m0_offset);
 