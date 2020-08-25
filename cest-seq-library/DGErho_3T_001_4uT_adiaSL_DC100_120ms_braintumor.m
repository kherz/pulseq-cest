%% DGErho_3T_001_4uT_adiaSL_DC100_0.12s_braintumor
% The DGErho protocol is taken from:
%Herz et al..

% 
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec infos, adapt as you wish
offsets_ppm = [-300 0.6 0.9 1.2 1.5 -300 0.6 0.9 1.2 1.5]; % Z spec offsets [ppm]
run_m0_scan  = false;  % if you want an M0 scan at the beginning
Trec        = 4;   % recovery time between scans [s]
Trec_M0     = 12;    % recovery time before m0 scan [s]
B1pa       = 4;  % mean sat pulse b1 [uT]
tp          = 120e-3; % sat pulse duration [s]
n_pulses     = 1;    % number of sat pulses per measurement
B0           = 3;     % B0 [T]
spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = strcat(mfilename,'.seq'); % filename

%% scanner limits 
% see pulseq doc for more ino
lims = Get_scanner_limits();

%% create scanner events
% satpulse
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]
fa_sat        = B1pa*gyroRatio_rad*tp; % flip angle of sat pulse
% create pulseq saturation pulse object 
satPulse      = mr.makeBlockPulse(fa_sat, 'Duration', tp, 'system', lims);
adia_SL  = WriteSLExpPulseqPulses(B1pa, lims);

% spoilers
spoilRiseTime = 1e-3;
spoilDuration = 4500e-6+ spoilRiseTime; % [s]
% create pulseq gradient object
[gxSpoil, gySpoil, gzSpoil] = Create_spoiler_gradients(lims, spoilDuration, spoilRiseTime);

% pseudo adc, not played out
pseudoADC = mr.makeAdc(1,'Duration', 1e-3);

%% loop through zspec offsets
disp('Creating sequence ... ');
t_start = tic;
offsets_Hz = offsets_ppm*gyroRatio_hz*B0; % Z spec offsets [Hz]
% init sequence
seq = mr.Sequence();
% add m0 scan if wished
if run_m0_scan 
    seq.addBlock(mr.makeDelay(Trec_M0));
    seq.addBlock(pseudoADC);
end

% loop through offsets and set pulses and delays
pre_sl = [];
post_sl = [];
accumPhase = 0;
% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz
    seq.addBlock(mr.makeDelay(Trec)); % recovery time
    if currentOffset < 0
        pre_sl = adia_SL{find(ismember(adia_SL(:,2), 'pre_neg')),1};
        post_sl = adia_SL{find(ismember(adia_SL(:,2), 'post_neg')),1};
    else
        pre_sl = adia_SL{find(ismember(adia_SL(:,2), 'pre_pos')),1};
        post_sl = adia_SL{find(ismember(adia_SL(:,2), 'post_pos')),1};
    end
    % set frequency
    pre_sl.freqOffset = currentOffset;
    accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(pre_sl.signal)>0))*1e-6),2*pi);

    satPulse.phaseOffset = mod(accumPhase,2*pi);
    satPulse.freqOffset = currentOffset; % set freuqncy offset of the pulse
    accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(satPulse.signal)>0))*1e-6),2*pi);
    
    post_sl.phaseOffset = mod(accumPhase,2*pi);
    post_sl.freqOffset = currentOffset;    
    for np = 1:n_pulses
        seq.addBlock(pre_sl)
        seq.addBlock(satPulse) % add sat pulse
        seq.addBlock(post_sl)
        if np < n_pulses % delay between pulses
            seq.addBlock(mr.makeDelay(t_d)); % add delay
        end
    end
    if spoiling % spoiling before readout
        seq.addBlock(gxSpoil,gySpoil,gzSpoil);
    end
    seq.addBlock(pseudoADC); % readout trigger event
    accumPhase = 0;
end
t_end = toc(t_start);
disp(['Creating sequence took ' num2str(t_end) ' s']);

%% write sequence
seq.setDefinition('offsets_ppm',offsets_ppm);
seq.setDefinition('run_m0_scan', run_m0_scan);
seq.write(seq_filename);

%% plot
disp('Plotting .seq file ... ');
t_start = tic;
seq.plot();
t_end = toc(t_start);
disp(['Plotting .seq file took ' num2str(t_end) ' s']);
save_seq_plot(seq_filename);

%% call standard sim
disp('Simulating .seq file ... ');
t_start = tic;
M_z=Standard_pulseq_cest_Simulation(seq_filename,B0);
t_end = toc(t_start);
disp(['Simulating .seq file took ' num2str(t_end) ' s']);

%% Zspec and ASYM calculation
seq = mr.Sequence;
seq.read(seq_filename);

% plot z value 
figure,
plot(M_z,'Displayname','Z'); hold on;
xlabel('Measurement No.'); legend show;





