function fp = getPulseqCESTRootDir()
fp = fileparts(which('install_pulseqcest'));
if isempty(fp)
    error('pulseq-cest not found in PATH');
end