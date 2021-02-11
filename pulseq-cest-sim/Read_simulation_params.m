%% read yaml parameter file
% pulseq-cest project

% Kai Herz, 2020
% kai.herz@tuebingen.mpg.de

function PMEX = Read_simulation_params(yaml_fn)

PMEX = [];

%% check for file
if ~exist(yaml_fn, 'file')
    error('yaml parameter file does not exist!')
end

%% read struct
params = yaml.ReadYaml(yaml_fn);

%% get water pool
if ~isfield(params, 'water_pool')
    error('Water pool must be defined in "water_pool"');
end
wp = params.water_pool;
if ~isfield(wp, 'f') || ~isfield(wp, 'r1') || ~isfield(wp, 'r2')
    error('"water_pool" must contain "f", "r1" and "r2"');
end
PMEX.WaterPool.R1 = str2param(wp.r1); % Hz
PMEX.WaterPool.R2 = str2param(wp.r2); % Hz
PMEX.WaterPool.f  = str2param(wp.f);  % proton fraction


%% CEST pools
num_pools = 0;
if isfield(params, 'cest_pool')
    cp = params.cest_pool;
    pool_names = fieldnames(cp);
    num_pools = numel(pool_names);
    for p = 1:num_pools
        cpool = cp.(pool_names{p});
        if ~isfield(cpool, 'f') || ~isfield(cpool, 'r1') || ~isfield(cpool, 'r2') || ...
                ~isfield(cpool, 'k') || ~isfield(cpool, 'dw')
            error([pool_names{p} ' must contain "f", "r1" , "r2", "k" and "dw"']);
        end
        PMEX.CESTPool(p).R1 = str2param(cpool.r1);
        PMEX.CESTPool(p).R2 = str2param(cpool.r2);
        PMEX.CESTPool(p).f  = str2param(cpool.f);
        PMEX.CESTPool(p).dw = str2param(cpool.dw);
        PMEX.CESTPool(p).k  = str2param(cpool.k);
    end
else
    warning('No CEST pools found in param files! specify with "cest_pool"');
end

%% MT pool
if isfield(params, 'mt_pool')
    mt = params.mt_pool;
    if ~isfield(mt, 'f') || ~isfield(mt, 'r1') || ~isfield(mt, 'r2') || ...
            ~isfield(mt, 'k') || ~isfield(mt, 'dw') || ~isfield(mt, 'lineshape')
        error('"mt_pool" must contain "f", "r1" , "r2", "k", "dw" and "lineshape"');
    end
    if ~strcmp(mt.lineshape, 'SuperLorentzian') && ~strcmp(mt.lineshape, 'Lorentzian') && ...
            ~strcmp(mt.lineshape, 'None')
        error([mt.lineshape ' is invalid. Please use "None", "Lorentzian" or "SuperLorentzian"']);
    end
    PMEX.MTPool.R1        = str2param(mt.r1);
    PMEX.MTPool.R2        = str2param(mt.r2);
    PMEX.MTPool.k         = str2param(mt.k);
    PMEX.MTPool.f         = str2param(mt.f);
    PMEX.MTPool.dw        = str2param(mt.dw);
    PMEX.MTPool.Lineshape = mt.lineshape;
else
    warning('No MT pool found in param files! specify with "mt_pool"');
end


%% Put together an initial Magnetization vector (fully relaxed)
% [MxA, MxB, MxD, MyA, MyB, MyD, MzA, MzB, MzD, MzC]
% -> A: Water Pool, B: 1st CEST Pool, D: 2nd CEST Pool, C: MT Pool
% Cest pools would continue in the same way with E, F, G ...
nTotalPools = num_pools+1; % cest + water
PMEX.M = zeros(nTotalPools*3,1);
PMEX.M(nTotalPools*2+1,1)= PMEX.WaterPool.f;
for ii = 2:nTotalPools
    PMEX.M(nTotalPools*2+ii,1)= PMEX.CESTPool(ii-1).f;
end
if isfield(PMEX, 'MTPool') && size(PMEX.M,1) == nTotalPools*3 % add MT pool
    PMEX.M = [PMEX.M; PMEX.MTPool.f];
end

%% scale init vector
if isfield(params, 'scale')
    PMEX.M = PMEX.M * str2param(params.scale);
end

%% scanner parameters
if ~isfield(params, 'b0') || ~isfield(params, 'gamma')
    error('Parameter file must contain "b0" and "gamma"');
end
PMEX.Scanner.B0    = str2param(params.b0);    % field strength [T]
PMEX.Scanner.Gamma = str2param(params.gamma); % gyromagnetic ratio [rad/uT]

if isfield(params, 'b0_inhom')
    PMEX.Scanner.B0Inhomogeneity = str2param(params.b0_inhom);
end

if isfield(params, 'rel_b1')
    PMEX.Scanner.relB1 = str2param(params.rel_b1);
end


%% more optinal paramters
if isfield(params, 'verbose')
    PMEX.Verbose = logical(str2param(params.verbose));
end
if isfield(params, 'reset_init_mag')
    PMEX.Verbose = logical(str2param(params.reset_init_mag));
end
if isfield(params, 'max_pulse_samples')
    PMEX.Verbose = str2param(params.max_pulse_samples);
end

    function value = str2param(str)
        value = nan;
        if isnumeric(str) || islogical(str)
            value = str;
        elseif  isstr(str)
            slash_pos = strfind(str, '/'); % check if fraction
            if isempty(slash_pos)
                value = str2double(str);
            else
                n1 = str2double(str(1:slash_pos-1));
                n2 = str2double(str(slash_pos+1:end));
                value = n1/n2;
            end
        end
        if isnan(value)
            error(['Could not parse a numeric value from ' str] );
        end
    end
end


