%% download pulseq-cest dependencies 

% check if git is there
[st, rs] = system('git --version');
if st
    error('Installation failed! Please install git');
end

% get filepath of the install script
script_fp = [];
if strcmp(mfilename, 'LiveEditorEvaluationHelperESectionEval')
    script_fp = fileparts(matlab.desktop.editor.getActiveFilename);
else
    script_fp = fileparts(which(mfilename));
end
disp(['Running git in ' script_fp]);


% download the pulseq-cest-library repo
lib_path = fullfile(script_fp, '..', 'pulseq-cest-library');
if exist(lib_path, 'dir')
    disp('pulseq-cest-library already installed, skip...')
else
    disp('Installing pulseq-cest-library...');
    sys_cmd = ['git clone --depth 1 https://github.com/kherz/pulseq-cest-library.git ' lib_path];
    [st, rs] = system(sys_cmd);
    if st
        disp(rs);
        error('Installation of pulseq-cest-library failed!');
    end
    disp('...done!');
end

% download the yamlmatlab package
yaml_path = fullfile(script_fp, 'pulseq-cest-sim', 'yamlmatlab');
if exist(yaml_path, 'dir')
    disp('yamlmatlab already installed, skip...')
else
    disp('Installing yamlmatlab...');
    sys_cmd = ['git clone --depth 1 https://github.com/ewiger/yamlmatlab.git ' yaml_path];
    [st, rs] = system(sys_cmd);
    if st
        disp(rs);
        error('Installation of yamlmatlab failed!');
    end
    disp('...done!');
end

% add everything to the path
disp('Adding files to path.')
addpath(genpath(script_fp));

% done
disp('Installation finished!');


