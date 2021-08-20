%% download pulseq-cest dependencies
% Kai Herz 2021
% kai.herz@tuebingen.mpg.de
%
% get filepath of the install script
script_fp = [];
if strcmp(mfilename, 'LiveEditorEvaluationHelperESectionEval')
    script_fp = fileparts(matlab.desktop.editor.getActiveFilename);
else
    script_fp = fileparts(which(mfilename));
end

%pulseq path
pulseq_path = fullfile(script_fp, 'pulseq-cest-sim', 'pulseq');
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
    
    %clone pulseq
    cloneRepo(pulseq_path, 'https://github.com/pulseq/pulseq.git', 1, 'v1.3.0');
    % clone pulseq-cest-library
    cloneRepo(lib_path, 'https://github.com/kherz/pulseq-cest-library.git');
    % clone yamlmatlab
    cloneRepo(yaml_path, 'https://github.com/ewiger/yamlmatlab.git', 1);
    
else % no git, try to download
    disp('git not found, trying to install without it...');
    
    % download pulseq
    unzipRepo(pulseq_path, 'https://github.com/pulseq/pulseq.git', 'v1.3.0');
    % download pulseq-cest-library
    unzipRepo(lib_path, 'https://github.com/kherz/pulseq-cest-library.git');
    % download yamlmatlab
    unzipRepo(yaml_path, 'https://github.com/ewiger/yamlmatlab.git');
end
% add everything to the path
disp('Adding files to path.')
addpath(genpath(script_fp));

% done
disp('Installation finished!');

% clone the repo with git
% path: path where to clone
% repo: repo url
% depth: for shallow clone
% tag: tag which should be cloned
function cloneRepo(path, repo, depth, tag)
% get repo info
[~,fn,~] = fileparts(repo);
% skip if already there
if exist(path, 'dir')
    disp([fn  ' already installed, skip...']);
else
    disp(['Installing ' fn '...']);
    sys_cmd = 'git clone';
    if nargin > 2 % add epth if wished
        sys_cmd = [sys_cmd ' --depth ' num2str(depth)];
        if nargin > 3
            sys_cmd = [sys_cmd ' -b ' tag];
        end
    end
    sys_cmd = [sys_cmd ' ' repo ' ' path];
    [st, rs] = system(sys_cmd);
    if st
        disp(rs);
        error(['Installation of ' fn ' failed!']);
    end
    disp('...done!');
end

end

% unzip repo directly from url
% path: path where to unzip
% repo: repo url
% tag: tag which should be unzipped
function unzipRepo(path, repo, tag)
% get repo info
[fp,fn,~] = fileparts(repo);
% skip if already there
if exist(path, 'dir')
    disp([fn ' already installed, skip...']);
else
    repo_zip = 'master.zip';
    if nargin > 2
        repo_zip = ['refs/tags/' tag '.zip'];
    end
    repo_zip = [fp '/' fn '/archive/' repo_zip];
    disp(['Installing ' fn '...']);
    % copy in currect folder
    fn = unzip(repo_zip,pwd);
    movefile(fn{1},path);
    % move to final path
    disp('...done!');
end

end



