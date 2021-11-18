%% reads the standard parameter file and checks for all fields
script_fp = fileparts(which(mfilename));
param_fn = fullfile(script_fp, '..', 'examples', 'GM_3T_example_bmsim.yaml'); 
PMEX = readSimulationParameters(param_fn);
% test fields
assert(isfield(PMEX, 'WaterPool'));
assert(isfield(PMEX.WaterPool, 'R1'));
assert(isfield(PMEX.WaterPool, 'R2'));

assert(isfield(PMEX, 'MTPool'));
assert(isfield(PMEX.MTPool, 'R1'));
assert(isfield(PMEX.MTPool, 'R2'));
assert(isfield(PMEX.MTPool, 'k'));
assert(isfield(PMEX.MTPool, 'f'));
assert(isfield(PMEX.MTPool, 'dw'));
assert(isfield(PMEX.MTPool, 'Lineshape'));

assert(isfield(PMEX, 'CESTPool'));
assert(isfield(PMEX.CESTPool, 'R1'));
assert(isfield(PMEX.CESTPool, 'R2'));
assert(isfield(PMEX.CESTPool, 'k'));
assert(isfield(PMEX.CESTPool, 'f'));
assert(isfield(PMEX.CESTPool, 'dw'));

assert(isfield(PMEX, 'M'));

assert(isfield(PMEX, 'Scanner'));
assert(isfield(PMEX.Scanner, 'B0'));



