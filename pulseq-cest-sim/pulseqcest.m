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
try
    pulseqcestmex('init', PMEX, seq_fn); % init the mex library
    M = pulseqcestmex('run');            % run the simulation
    pulseqcestmex('close');              % close the library
    clear pulseqcestmex;                 % clear mex memory
catch ME
    clear pulseqcestmex;                 % clear mex memory    
    switch ME.identifier
        case 'MATLAB:mex:ErrInvalidMEXFile'
            if isunix && contains(ME.message, 'GLIBCXX')
                error(['A mismatch between your system and MATLAB libstdc++ library was detected wich leads to an error in the mex-file.' newline ...
                       'To solve this, please try to restart MATLAB from the console with a pre-load of your system libraries' newline ...
                       'You can find the exact location of the libstdc++ library by running: find /usr/lib -name libstdc++.so.6 ' newline ...
                       'Please use this library to start MATLAB from the terminal. Here is an example command for a 64-bit Ubuntu machine: ' newline ...
                       'LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 matlab' ]);
            else
                error(['A proplem with the compiled mex-file was detected! ' newline ...
                       'Please recompile by running the compile_pulseqcest function!']);
                
            end
        case 'pulseqcestmex:ParseInputStruct'
            error(['An error was detected during parsing of the PMEX input! ' newline ...
                    ME.message]);
        case 'pulseqcestmex:Initialize'
            error(['An error was detected the initialization of the mex-file! ' newline ...
                    ME.message]);
        case 'pulseqcestmex:mexFunction'
            error(['An error was detected during the simulation in the mex-file! ' newline ...
                    ME.message]);
        otherwise
            warning('Unpecified error!');
            rethrow(ME);
    end
end

