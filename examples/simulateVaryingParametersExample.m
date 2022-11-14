% This function demonstrates how to run the same sequence with multiple
% parameter combinations without the need to decode the sequence all the
% time
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
seq_fn   = fullfile(script_fp, 'OH_3T_example.seq');
% .yaml-file: This file contains all the simulation settings
param_fn = fullfile(script_fp, 'GM_3T_example_bmsim.yaml');

%% read Parameters
PMEX = readSimulationParameters(param_fn);
nTotalPools = 1;
if isfield(PMEX, 'CESTPool')
    nTotalPools = nTotalPools + numel(PMEX.CESTPool);
end

%% lets vary T2 of the water
T2 = 0.05:0.005:0.1;
nT2 = numel(T2);
results = cell(nT2,2);

%% this is the standard way with seq encoding every time
disp('Running .seq decoding every time...');
tic;
for t = 1:nT2
    PMEX.WaterPool.R2 = 1/T2(t);
    M = pulseqcest(PMEX, seq_fn);
    results{t,1} = M(nTotalPools*2+1,:);
    results{t,2} = T2(t);
end
toc;

%% now we run the simulation with different call modes and check the time
disp('Running .seq decoding only once...');
tic;
pulseqcestmex('init', PMEX, seq_fn);     % init the mex library
for t = 1:nT2
    PMEX.WaterPool.R2 = 1/T2(t);
    pulseqcestmex('update', PMEX);       % update the struct without decoding the seq file again
    M = pulseqcestmex('run');            % run the simulation
    results{t,1} = M(nTotalPools*2+1,:);
    results{t,2} = T2(t);
end
pulseqcestmex('close');                  % close the library
clear pulseqcestmex; 
toc;


%% read the .seq-file definitions
definitions = readSequenceDefinitions(seq_fn);

% get the definitions in the file
offsets_ppm = definitions('offsets_ppm'); % offsets

% plot everything
figure(1); hold on;
for t = 1:nT2
    Mz = results{t,1};
    plot(offsets_ppm(2:end),Mz(2:end)./Mz(1),'Displayname',['T_2: ' num2str(results{t,2}) ' s']); set(gca,'xdir','reverse');
end
ylabel('Z');
xlabel('\Delta\omega [ppm]'); legend show;
grid on;

