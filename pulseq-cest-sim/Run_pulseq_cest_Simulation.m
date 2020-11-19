%% Run pulseq SBB simulation
% example for a Z-spectrum for GM at 3T with
% - 2 CEST pools
% - a Lorentzian shaped MT pool
%
% All parameters are saved in a struct which is the input for the mex file
%
% Kai Herz, 2020
% kai.herz@tuebingen.mpg.de

%% filenames for .seq-file and simulation parameters
script_fp = []; % get correct path
if strcmp(mfilename, 'LiveEditorEvaluationHelperESectionEval')
    script_fp = fileparts(matlab.desktop.editor.getActiveFilename);
else
    script_fp = fileparts(which(mfilename));
end

seq_fn   = [script_fp '/example/example_APTw.seq'];              % seq-file
param_fn = [script_fp '/example/standard_cest_sim_params.yaml']; % yaml-file

%% read params
PMEX = Read_simulation_params(param_fn);

%% run sim
M_out = Sim_pulseqSBB(PMEX, seq_fn);

%% get z signal
nTotalPools = 1;
if isfield(PMEX, 'CESTPool')
    nTotalPools = nTotalPools + numel(PMEX.CESTPool);
end
M_z=M_out(nTotalPools*2+1,:);
%% plot zspec
seq = mr.Sequence;
seq.read(seq_fn);
if isKey(seq.definitions, 'run_m0_scan')
    if seq.definitions('run_m0_scan')
        M_z = M_z(2:end)./M_z(1); % normalize by first scan
    end
end

if isKey(seq.definitions, 'offsets_ppm')  % try to get the ppm values from the seq file
    offsets_ppm = seq.definitions('offsets_ppm');
    if any(abs(offsets_ppm)>295) % everything above 295 ppm is m0
        M0_idx = find(abs(offsets_ppm)>295);
        M0 = mean(M_z(M0_idx));
        M_z(M0_idx) = [];
        offsets_ppm(M0_idx) = [];
        M_z = M_z./M0;
    end
    
    [ppm_sort, idx] = sort(offsets_ppm);
    Z = M_z(idx);
    % MTRasym -> eqaul values of both sides of the z-spectrum expected
    MTRasym=Z(end:-1:1)-Z;
    MTRasym(1:ceil(end/2)) = 0; % set duplictes to 0 
    
    % plot z-spec and asym
    figure;
    yyaxis left;
    plot(ppm_sort, Z);
    axis([ppm_sort(1) ppm_sort(end) 0 1])
    set(gca,'xdir','reverse');
    ylabel('M/(M_0)');
    yyaxis right;
    plot(ppm_sort,MTRasym);
    axis([ppm_sort(1) ppm_sort(end) min(MTRasym)*4 max(MTRasym)*4])
    set(gca, 'xdir', 'reverse' )
    ylabel('MTR_{asym}');
    xlabel('\Delta\omega [ppm]');
    
else % plot just as ADC index
    plot(M_z);
    xlabel('ADC index');
end
title('Z-spec');





