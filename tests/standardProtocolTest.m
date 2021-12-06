%% runs standard protol and compares it to ground thruth
script_fp = fileparts(which(mfilename));
% simulate example
seq_fn   = fullfile(script_fp, '..', 'examples', 'APTw_3T_example.seq'); 
param_fn = fullfile(script_fp, '..', 'examples', 'GM_3T_example_bmsim.yaml'); 
M_z = simulate_pulseqcest(seq_fn, param_fn);
% load ground truth and compare
load(fullfile(script_fp, 'rsc', 'ZMagAfterStandardProtocol.mat'));
assert(~any(abs(M_z(:)-ZMagAfterStandardProtocol(:))>1e-9));
