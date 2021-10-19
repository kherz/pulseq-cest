% This function runs the standard simulation for a specific .seq and .yaml pair and plots the results
%
% kai.herz@tuebingen.mpg.de
% Input:  seq_fn:   filename of the .seq-file
%         param_fn: filename of the .yaml parameter file
%
% Output: Mz: Water z-magnetization at each ADC event
function M_z = simulate_pulseqcest(seq_fn, param_fn)
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
PMEX = readSimulationParameters(param_fn);

%% simulation start
disp('Simulating .seq file ... ');
t_start = tic;
%% multiple isochromats
if isfield(PMEX, 'isochromats') && (PMEX.isochromats.numIsochromats > 1)
    r2dash  = 1/PMEX.isochromats.t2star - PMEX.WaterPool.R2;
    nIsochromats = PMEX.isochromats.numIsochromats;
    dwSpins = Composite();
    dwSpins = r2dash*tan(pi*.9*linspace(-.5,.5,nIsochromats));
    dwSpins = dwSpins./(PMEX.Scanner.B0*PMEX.Scanner.Gamma);
    % prepare parallel pool and indices to spread optimal
    pp = gcp;
    Mpar = cell(nIsochromats,1);
    % every worker gets a set of indices in the dwSpins array
    workerIds = mat2cell((1:nIsochromats)', diff(fix(linspace(0, nIsochromats, pp.NumWorkers+1))), 1);
    spmd 
        PMEX_local = PMEX; % local variable for parfor loop
        % one process for each worker
        pulseqcestmex('init', PMEX, seq_fn);
        for dwIdx = workerIds{labindex}(:)'
            PMEX_local.Scanner.B0Inhomogeneity = dwSpins(dwIdx);
            pulseqcestmex('update', PMEX_local);
            Mpar{dwIdx} = pulseqcestmex('run');
        end
        pulseqcestmex('close');
    end
    % combine data from all workes in single cell
    Mcomb = [Mpar{:}];
    Mcomb = Mcomb(~cellfun('isempty',Mcomb));
    Mcomb = cell2mat(Mcomb');
    % reshape and calculate mean
    M_out = mean(reshape(Mcomb, [size(Mcomb,1), size(Mcomb,2)/nIsochromats, nIsochromats]),3);
else
    %% single isochromat case (standard)
    M_out = pulseqcest(PMEX, seq_fn);
end

%% simulation end
t_end = toc(t_start);
disp(['Simulating .seq file took ' num2str(t_end) ' s']);

%% get Z signal of water
nTotalPools = 1;
if isfield(PMEX, 'CESTPool')
    nTotalPools = nTotalPools + numel(PMEX.CESTPool);
end
M_z = M_out(nTotalPools*2+1,:);


