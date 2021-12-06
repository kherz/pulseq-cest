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
    cloneRepo(pulseq_path, 'https://github.com/pulseq/pulseq.git', 'commit', 'ed8cf4231dc7a5caaf828211486287afcdbac230');
    % clone pulseq-cest-library
    cloneRepo(lib_path, 'https://github.com/kherz/pulseq-cest-library.git');
    % clone yamlmatlab
    cloneRepo(yaml_path, 'https://github.com/ewiger/yamlmatlab.git', 'depth', 1);
    
else % no git, try to download
    disp('git not found, trying to install without it...');
    
    % download pulseq
    unzipRepo(pulseq_path, 'https://github.com/pulseq/pulseq.git','commit', 'ed8cf4231dc7a5caaf828211486287afcdbac230');
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

% apply a system command and throw error if sth goes wrong
% cmd: the command that should be run
function applySystemCommand(cmd)
[st, rs] = system(cmd);
if st
    disp(rs);
    error(['The command: "' cmd '" failed!']);
end
end

% clone the repo with git
% path: path where to clone
% repo: repo url
% optional parser optins
% depth: for shallow clone
% tag: tag which should be cloned
% commit: to checkout a specific commit after clone
function cloneRepo(path, repo, varargin)
p = inputParser;
addOptional(p,'depth', []);
addOptional(p,'tag', []);
addOptional(p,'commit', []);
% get repo info
[~,fn,~] = fileparts(repo);
% skip if already there
if exist(path, 'dir')
    disp([fn  ' already installed, skip...']);
else
    parse(p,varargin{:});
    disp(['Installing ' fn '...']);
    % if there is a specific commit, we ignore tag and depth
    if ~isempty(p.Results.commit)
        % clone master
        applySystemCommand(['git clone ' repo ' ' path]);
        % run checkout in thecorrect path
        currentPath = pwd;
        cd(path);
        applySystemCommand(['git checkout ' p.Results.commit]);
        cd(currentPath);
    else
        sys_cmd = 'git clone';
        if ~isempty(p.Results.depth)
            sys_cmd = [sys_cmd ' --depth ' num2str(p.Results.depth)];
        end
        if ~isempty(p.Results.tag)
            sys_cmd = [sys_cmd ' -b ' p.Results.tag];
        end
        applySystemCommand([sys_cmd ' ' repo ' ' path]);
    end
    disp('...done!');
end

end

% unzip repo directly from url
% path: path where to unzip
% repo: repo url
% tag: tag which should be unzipped
function unzipRepo(path, repo, varargin)
p = inputParser;
addOptional(p,'tag', []);
addOptional(p,'commit', []);
parse(p,varargin{:});
% get repo info
[fp,fn,~] = fileparts(repo);
% skip if already there
if exist(path, 'dir')
    disp([fn ' already installed, skip...']);
else
    if ~isempty(p.Results.commit)
        repo_zip = [p.Results.commit '.zip'];
    elseif ~isempty(p.Results.tag)
        repo_zip = ['refs/tags/' p.Results.tag '.zip'];
    else
        repo_zip = 'master.zip';
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



