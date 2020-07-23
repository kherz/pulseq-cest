%% Run pulseq SBB simulation
% example for a Z-spectrum for GM at 3T with
% - 2 CEST pools
% - a Lorentzian shaped MT pool
%
% All parameters are saved in a struct which is the input for the mex file
%
% Kai Herz, 2020
% kai.herz@tuebingen.mpg.de


%% Water properties
PMEX.WaterPool.R1 = 1/1.3;     % Hz
PMEX.WaterPool.R2 = 1/(75e-3); % Hz
PMEX.WaterPool.f  = 1;         % proton fraction

%% CEST pools
% pool 1 -> 50 mmol Amide pool
PMEX.CESTPool(1).R1 = PMEX.WaterPool.R1;
PMEX.CESTPool(1).R2 = PMEX.WaterPool.R2;
PMEX.CESTPool(1).f  = 50e-3/111; % fraction
PMEX.CESTPool(1).dw = 3.5; % chemical shift from water [ppm]
PMEX.CESTPool(1).k  = 40; % exchange rate [Hz]

% pool 2 -> 25 mmol Amine pool
PMEX.CESTPool(2).R1 = PMEX.WaterPool.R1;
PMEX.CESTPool(2).R2 = PMEX.WaterPool.R2;
PMEX.CESTPool(2).f  = 25e-3/111; % fraction
PMEX.CESTPool(2).dw = 2; % chemical shift from water [ppm]
PMEX.CESTPool(2).k  = 1000; % exchange rate [Hz]

%% MT pool
PMEX.MTPool.R1        = 1;
PMEX.MTPool.R2        = 1e5;
PMEX.MTPool.k         = 23;
PMEX.MTPool.f         = 0.0500;
PMEX.MTPool.dw        = -2;
PMEX.MTPool.Lineshape = 'Lorentzian';

%% Put together an initial Magnetization vector (fully relaxed)
% [MxA, MxB, MxD, MyA, MyB, MyD, MzA, MzB, MzD, MzC]
% -> A: Water Pool, B: 1st CEST Pool, D: 2nd CEST Pool, C: MT Pool
% Cest pools would continue in the same way with E, F, G ...
nTotalPools = numel(PMEX.CESTPool)+1; % cest + water
PMEX.M = zeros(nTotalPools*3,1);
PMEX.M(nTotalPools*2+1,1)= PMEX.WaterPool.f;
for ii = 2:nTotalPools
    PMEX.M(nTotalPools*2+ii,1)= PMEX.CESTPool(ii-1).f;
    PMEX.M(nTotalPools*2+1,1) = PMEX.M(nTotalPools*2+1,1) - PMEX.CESTPool(ii-1).f;
end
if isfield(PMEX, 'MTPool') && size(PMEX.M,1) == nTotalPools*3 % add MT pool
    PMEX.M = [PMEX.M; PMEX.MTPool.f];
end

% say you have a magnetization Mi of 50% after the readout. Scale the M
% vector here according to that (ca. 0.5 for FLASH)
PMEX.M = PMEX.M * 0.5;


%% Scanner parameters
PMEX.Scanner.B0    = 3; % field strength [T]
PMEX.Scanner.Gamma = 267.5153; % gyromagnetic ratio [rad/uT]
% optional
% PMEX.Scanner.B0Inhomogeneity = 0.0; % field inhomogeneity [ppm]
% PMEX.Scanner.relB1           = 1.0; % relative B1

%% more optinal paramters
% PMEX.Verbose         = false; % for verbose output, defalut false
% PMEX.ResetInitMag    = true;  % true if magnetization should be set to
% PMEX.M after each ADC, defaultrue
% PMEX.MaxPulseSamples = 100;   % max samples for shaped pulses

%% get seq filename
seq_fp = [];
if strcmp(mfilename, 'LiveEditorEvaluationHelperESectionEval')
    seq_fp = fileparts(matlab.desktop.editor.getActiveFilename);
else
    seq_fp = fileparts(which(mfilename));
end
seq_fn = [seq_fp '/example/example_APTw.seq'];

%% run sim

%[seq_fn, path] = uigetfile({'*.seq','All .seq Files'},'mytitle','cest-seq-library');

%seq_fn=[path seq_fn];
M_out = Sim_pulseqSBB(PMEX, seq_fn);
M_z=M_out(nTotalPools*2+1,:);
%% plot zspec
figure(99), hold on;
try % try to get the ppm values from the seq file
    seq = mr.Sequence;
    seq.read(seq_fn);
    [ppm_sort, idx] = sort(seq.definitions('offsets_ppm'));
    plot(ppm_sort, M_z(idx));
    set ( gca, 'xdir', 'reverse' )
    xlabel('offset [ppm]');
catch % plot just as ADC index
    plot(M_z);
    xlabel('ADC index');
end
title('Z-spec');
ylabel('M');

%% exemplary MTRasym contrast map generation
% if your data was acquired as in the seq file, the following code works for each pixel of such a 4D stack

if seq.definitions('run_m0_scan')
    M0=M_z(1);
    Z=M_z(2:end)/M0;
    MTRasym=Z(end:-1:1)-Z;
else
    Z=M_z;
    MTRasym=Z(end:-1:1)-Z;
end

figure,
plot(ppm_sort, Z); set(gca,'xdir','reverse'); hold on;
plot(ppm_sort,MTRasym);
xlabel('ADC index');

% The single MTRAsym vlaue that would form the pixel intensity can be obtained like this:
ppm_sort(17) % test to find the right index for the offset of interest
MTRasym(17)




