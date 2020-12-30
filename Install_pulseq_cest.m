%% download pulseq-cest dependencies
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de
%
% get filepath of the install script
script_fp = [];
if strcmp(mfilename, 'LiveEditorEvaluationHelperESectionEval')
    script_fp = fileparts(matlab.desktop.editor.getActiveFilename);
else
    script_fp = fileparts(which(mfilename));
end

% pulseq-cest-library path
lib_path = fullfile(script_fp, '..', 'pulseq-cest-library');
% yamlmatlab path
yaml_path = fullfile(script_fp, 'pulseq-cest-sim', 'yamlmatlab');

% check if git is there
[st, rs] = system('git --version');
has_git = ~st;
if has_git %good, we can just clone everything
    disp('git found, cloning external libraries...');
    disp(['Running git in ' script_fp]);
    % download the pulseq-cest-library repo
    if exist(lib_path, 'dir')
        disp('pulseq-cest-library already installed, skip...')
    else
        disp('Installing pulseq-cest-library...');
        sys_cmd = ['git clone https://github.com/kherz/pulseq-cest-library.git ' lib_path];
        [st, rs] = system(sys_cmd);
        if st
            disp(rs);
            error('Installation of pulseq-cest-library failed!');
        end
        disp('...done!');
    end
    
    % download the yamlmatlab package
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
else % no git, try to download
    disp('git not found, trying to install without it...');
    % download the pulseq-cest-library repo
    if exist(lib_path, 'dir')
        disp('pulseq-cest-library already installed, skip...')
    else
        disp('Installing pulseq-cest-library...');
        pulseq_lib_zip = "https://github.com/kherz/pulseq-cest-library/archive/master.zip";
        unzip(pulseq_lib_zip,script_fp);
        movefile(fullfile(script_fp, 'pulseq-cest-library-master'),lib_path);
        disp('...done!');
    end
    % download the yamlmatlab package
    if exist(yaml_path, 'dir')
        disp('yamlmatlab already installed, skip...')
    else
        disp('Installing yamlmatlab...');
        yamlmatlab_zip = "https://github.com/ewiger/yamlmatlab/archive/master.zip";
        unzip(yamlmatlab_zip,script_fp);
        movefile(fullfile(script_fp, 'yamlmatlab-master'),yaml_path);
        disp('...done!');
    end
end
% add everything to the path
disp('Adding files to path.')
addpath(genpath(script_fp));

% done
disp('Installation finished!');

