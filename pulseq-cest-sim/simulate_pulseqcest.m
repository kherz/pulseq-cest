% This function runs the standard simulation for a specific .seq and .yaml
% pair and returns the Z-magnetization
%
% kai.herz@tuebingen.mpg.de
% Input:  seq:   filename of the .seq-file / seq object
%         param: filename of the .yaml parameter file / param object / struct
%
% Output: M_z: Water z-magnetization at each ADC event
function M_z = simulate_pulseqcest(seq, param)

%% uigetfile if function is called without arguments
if nargin < 2
    [seq_fn, seq_fp] = uigetfile({'*.seq','All .seq Files'},'Choose .seq-file for simulation');
    seq = fullfile(seq_fp, seq_fn);
    [param_fn, param_fp] = uigetfile({'*.yaml; *.yml','All .yaml Files'},'Choose .yaml-file for simulation');
    param = fullfile(param_fp, param_fn);
end

%% check seq input
if isa(seq,'mr.Sequence')
    seq_fn = [seq.definitions('seq_id_string') '.seq'];
    seq.write(seq_fn);
else
    seq_fn=seq;
    % check for files
    if ~exist(seq_fn, 'file')
        error('.seq file does not exist!')
    end
end

%% check param input
if ischar(param) || ischar(param)
    PMEX = readSimulationParameters(param);
else
    PMEX = param;
end

%% check B0
definitions = readSequenceDefinitions(seq_fn);
if PMEX.Scanner.B0 ~= definitions('B0')
    warning(['B0 in yaml (' num2str(PMEX.Scanner.B0)  ...
        'T) and seq ('  num2str(definitions('B0'))  'T) file different!'])
end

%% simulation start
disp('Simulating .seq file ... ');
t_start = tic;
%% multiple isochromats
if isfield(PMEX, 'isochromats') && (PMEX.isochromats.numIsochromats > 1)
    % prepare off-resonances
    r2dash  = 1/PMEX.isochromats.t2star - PMEX.WaterPool.R2;
    nIsochromats = PMEX.isochromats.numIsochromats;
    dwSpins = r2dash*tan(pi*.9*linspace(-.5,.5,nIsochromats));
    dwSpins = dwSpins./(PMEX.Scanner.B0*PMEX.Scanner.Gamma);
    % allocate cell array for magnetization vecors
    Mpar = cell(nIsochromats,1);
    spmd
        PMEX_local = PMEX; % local variable for parfor loop
        pulseqcestmex('init', PMEX, seq_fn); % one process for each worker
        for dwIdx = drange(1:numel(dwSpins))
            PMEX_local.Scanner.B0Inhomogeneity = dwSpins(dwIdx);
            pulseqcestmex('update', PMEX_local);
            Mpar{dwIdx} = pulseqcestmex('run');
        end
        pulseqcestmex('close');
    end
    clear pulseqcestmex; % clear mex memory
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


