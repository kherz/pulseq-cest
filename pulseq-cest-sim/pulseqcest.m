% call the mex function for a parameter setting and a seq file
% Input:  PMEX       : parameter struct for mex function
%         seq_fn     : seq filename
%
% Output: M          : final magnetitzation vector at each offset     
function M = pulseqcest(PMEX, seq_fn)

% output init
M = [];

% check if PMEX is valid
if ~isstruct(PMEX)
   error('PMEX must be a sctruct with all simulation parameters!') 
end

% check for seq-file
if ~exist(seq_fn, 'file')
    error('.seq file does not exist!')
end

% call the mex file with different call modes
pulseqcestmex('init', PMEX, seq_fn); % init the mex library
M = pulseqcestmex('run');            % run the simulation
pulseqcestmex('close');              % close the library
