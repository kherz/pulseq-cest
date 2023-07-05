%% read and plot a seq file
seq = SequenceSBB(getScannerLimits());
seq_fn=fullfile(uigetfile({'*.seq','All .seq Files'},'Choose .seq-file for simulation'));
seq.read(seq_fn);

seq.plot()    % seq.plot('TimeRange',[0 10])

seq.plotSaturationPhase();   % seq.plotSaturationPhase([0 Inf]);
seq.plotSaturationPhase([5 8]); 

%%
param_fn = fullfile(uigetfile({'*.yaml; *.yml','All .yaml Files'},'Choose .yaml-file for simulation'));
M_z = simulate_pulseqcest(seq, param_fn);


%% read the .seq-file definitions
definitions = readSequenceDefinitions(seq_fn);
% get the definitions in the file
w = definitions('offsets_ppm'); % offsets
figure, 
subplot(1,2,1), plot(M_z); title('raw'); xlabel('index');
subplot(1,2,2), plot(w(2:end),M_z(2:end)); ylim([0 1]);  set(gca,'xdir','reverse'); title('normalized'); xlabel('ppm');
