% This function runs the standard simulation for a specific .seq and .yaml pair and plots the results 
%
% kai.herz@tuebingen.mpg.de
% Input:  seq_fn:   filename of the .seq-file
%         param_fn: filename of the .yaml parameter file
%         fig_no:   (optional) figure number in which the result should be
%         plotted
%
% Output: Mz: Water z-magnetization at each ADC event
function Mz = Run_pulseq_cest_Simulation(seq_fn, param_fn, fig_no)
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
M_z=M_out(nTotalPools*2+1,:);

%% read sequence info for m0
% there are two M0 cases:
% 1: if run_m0_scan is true, the first scan is treated as an M0 scan
% 2: if this is false all offsets are searched for values > abs(295) ppm.
% These are treated as M0 scans then. If multiple scans are found, the mean
% value is used as M0
%
% If none of the cases are true, no normalization is performed
seq = mr.Sequence;
seq.read(seq_fn);
offsets_ppm = seq.definitions('offsets_ppm');
if seq.definitions('run_m0_scan')
    M_z=M_z(2:end)./M_z(1);
elseif any(abs(offsets_ppm)>295)
    M0_idx = find(abs(offsets_ppm)>295);
    M0 = mean(M_z(M0_idx));
    M_z(M0_idx) = [];
    offsets_ppm(M0_idx) = [];
    M_z = M_z./M0;
end
% sort the measured values
[ppm_sort, idx] = sort(offsets_ppm);
Z = M_z(idx);
% MTRasym -> eqaul values of both sides of the z-spectrum expected
MTRasym=Z(end:-1:1)-Z;
MTRasym(1:ceil(end/2)) = 0;


%% plot results
if nargin < 3
    figure; hold on;
else
    figure(fig_no); hold on;
end
yyaxis left;
plot(ppm_sort, Z,'Displayname','Z-spectrum'); set(gca,'xdir','reverse');
yyaxis right;
plot(ppm_sort,MTRasym,'Displayname','MTR_{asym}');
axis([ppm_sort(1) ppm_sort(end) 4*min(MTRasym) 4*max(MTRasym)])
xlabel('\Delta\omega [ppm]'); legend show;


