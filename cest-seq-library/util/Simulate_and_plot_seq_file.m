function [Z, MTRasym, ppm_sort] = Simulate_and_plot_seq_file(seq_fn, B0, fig_no)
% This function runs the standard simulation for a specific .seq file
% and field strength and plots the results
% An equal distribution of offsets at both sides of the spectra and only unique values
% are expected. 
%
% kai.herz@tuebingen.mpg.de

% check input
if nargin < 2
    error('Usage: Input 1: a valid .seq filename; Input 2: field strength [T]');
end

% run standard siulation
disp('Simulating .seq file ... ');
t_start = tic;
M_z=Standard_pulseq_cest_Simulation(seq_fn,B0);
t_end = toc(t_start);
disp(['Simulating .seq file took ' num2str(t_end) ' s']);

% read sequence info for m0
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


% plot results
if nargin < 3
    figure; hold on;
else % plot in specific figure
    figure(fig_no); hold on;
end
yyaxis left;
plot(ppm_sort, Z,'Displayname','Z-spectrum'); set(gca,'xdir','reverse');
yyaxis right;
plot(ppm_sort,MTRasym,'Displayname','MTR_{asym}');
axis([ppm_sort(1) ppm_sort(end) 4*min(MTRasym) 4*max(MTRasym)])
xlabel('\Delta\omega [ppm]'); legend show;


