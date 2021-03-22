% This function runs the standard simulation for a specific .seq and .yaml pair and plots the results
%
% kai.herz@tuebingen.mpg.de
% Input:  seq_fn:   filename of the .seq-file
%         param_fn: filename of the .yaml parameter file
%
% Output: Mz: Water z-magnetization at each ADC event
function M_z = Run_pulseq_cest_Simulation(seq_fn, param_fn)
if nargin < 2
    [seq_fn, seq_fp] = uigetfile({'*.seq','All .seq Files'},'Choose .seq-file for simulation');
    seq_fn = fullfile(seq_fp, seq_fn);
    [param_fn, param_fp] = uigetfile({'*.yaml; *.yml','All .yaml Files'},'Choose .yaml-file for simulation');
    param_fn = fullfile(param_fp, param_fn);
end

%% check for files
if ~exist(seq_fn, 'file')
    error('.seq file does not exist!')
end

%% read .yaml file
PMEX = Read_simulation_params(param_fn);

%% run the simulation
disp('Simulating .seq file ... ');
t_start = tic;
M_out = Sim_pulseqSBB(PMEX, seq_fn);
t_end = toc(t_start);
disp(['Simulating .seq file took ' num2str(t_end) ' s']);

%% get Z signal of water
nTotalPools = 1;
if isfield(PMEX, 'CESTPool')
    nTotalPools = nTotalPools + numel(PMEX.CESTPool);
end
M_z = M_out(nTotalPools*2+1,:);


