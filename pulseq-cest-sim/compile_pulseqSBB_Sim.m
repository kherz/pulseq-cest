% compile_pulseqSBB_Sim
% get filepath
script_fp = [];
if strcmp(mfilename, 'LiveEditorEvaluationHelperESectionEval')
    script_fp = fileparts(matlab.desktop.editor.getActiveFilename);
else
    script_fp = fileparts(which(mfilename));
end
%cd(script_fp);

% check for eigen and clone if not there
eigen_path = fullfile(script_fp, 'src', '3rdParty', 'eigen3');
if ~exist(eigen_path, 'dir')
    % try to clone eigen
    disp('eigen not found, trying to clone...');
    [st, rs] = system('git --version');
    if st
        error(['Installation failed! Please install git or download the eigen library manually https://gitlab.com/libeigen/eigen/' ...
                ' and put it to ' eigen_path]);
    end
    sys_cmd = ['git clone -b 3.3.8 --depth 1 https://gitlab.com/libeigen/eigen.git ' eigen_path];
    [st, rs] = system(sys_cmd);
    if st
        disp(rs);
        error('Cloning of eigen failed!');
    end
    disp('...done!');
end

% get all file paths
i_eigen = ['-I' eigen_path];
i_pulseq = ['-I' fullfile(script_fp, 'src', '3rdParty', 'pulseq-master', 'src')];
f_sbb = fullfile(script_fp, 'src', 'Sim_pulseqSBB.cpp');
f_sp = fullfile(script_fp, 'src', 'SimulationParameters.cpp');
f_es = fullfile(script_fp, 'src', '3rdParty', 'pulseq-master', 'src', 'ExternalSequence.cpp');
opt_flag = 'CXXOPTIMFLAGS=""'; % gets overwritten if supported compiler is found

% compile simulation
disp('Checking compilers...');
csn = mex.getCompilerConfigurations('CPP').ShortName;
if ispc && contains(csn, 'MSVCPP')
    opt_flag = 'CXXOPTIMFLAGS="/O2"'; 
elseif ispc && contains(csn, 'mingw64-g++')
    opt_flag = 'CXXOPTIMFLAGS="-O2"';
elseif isunix && contains(csn, 'g++')
    opt_flag = 'CXXOPTIMFLAGS="-O2"';
else
    warning('No tested compiler found. Trying to compile...');
end
disp(['Start compilation with ' mex.getCompilerConfigurations('CPP').Name '...']);
mex(opt_flag, i_eigen, i_pulseq, f_sbb, f_sp, f_es, '-outdir', script_fp);
