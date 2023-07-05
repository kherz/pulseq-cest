%% read and plot a seq file
seq = SequenceSBB(getScannerLimits());
seq_fn=fullfile(uigetfile({'*.seq','All .seq Files'},'Choose .seq-file for simulation'));
seq.read(seq_fn);

seq.plot()    % seq.plot('TimeRange',[0 10])

seq.plotSaturationPhase();   % seq.plotSaturationPhase([0 Inf]);

%%
param_fn = fullfile(uigetfile({'*.yaml; *.yml','All .yaml Files'},'Choose .yaml-file for simulation'));

M_z = simulate_pulseqcest(seq, param_fn);


%% read the .seq-file definitions
definitions = readSequenceDefinitions(seq_fn);
% get the definitions in the file
offsets_ppm = definitions('offsets_ppm'); % offsets
m0_offset = definitions('M0_offset');     % m0 offset frequency
figure(1);
Z = plotSimulationResults(M_z,offsets_ppm,m0_offset);

