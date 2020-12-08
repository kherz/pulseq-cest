% This function runs the standard simulation for the example files 
%
% kai.herz@tuebingen.mpg.de

%% filenames for .seq-file and simulation parameters
% get correct path
script_fp = []; 
if strcmp(mfilename, 'LiveEditorEvaluationHelperESectionEval')
    script_fp = fileparts(matlab.desktop.editor.getActiveFilename);
else
    script_fp = fileparts(which(mfilename));
end

%% filenames
% .seq-file: This file contains the saturation period
seq_fn   = fullfile(script_fp, 'APTw_3T_example.seq'); 
% .yaml-file: This file contains all the simulation settings
param_fn = fullfile(script_fp, 'GM_3T_example_bmsim.yaml'); 

%% run silumation
Run_pulseq_cest_Simulation(seq_fn, param_fn);

