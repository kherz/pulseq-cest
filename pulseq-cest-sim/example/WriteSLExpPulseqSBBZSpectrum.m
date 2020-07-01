%% Write exmpe pulseqSBB .seq file
% The APTw protocol is taken from:
% https://cest-sources.org/doku.php?id=standard_cest_protocols
% APTw_1 : APT-weighted, low DC, t_sat=1.8s (//GLINT//)
%
%     pulse shape = Gaussian
%     B1 = 2.22 uT
%     n = 20
%     t_p = 50 ms
%     t_d = 40 ms
%     DC = 0.55 and t_sat = n*(t_p+t_d) = 1.8 s
%     T_rec = 2.4/12 s (saturated/M0)
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec infos, adapt as you wish
offset_range = 4;    % [ppm]
num_offsets  = 24;    % number of measurements (not including M0)
run_m0_scan  = false;  % if you want an M0 scan at the beginning
t_rec        = 5;   % recovery time between scans [s]
m0_t_rec     = 5;    % recovery time before m0 scan [s]
sat_b1       = 4;  % mean sat pulse b1 [uT]
t_p          = 100e-3; % sat pulse duration [s]
n_pulses     = 1;    % number of sat pulses per measurement
B0           = 2.89;     % B0 [T]
spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = 'example_SLExp.seq'; % filename

%% scanner limits
% see pulseq doc for more ino
lims = mr.opts('MaxGrad',40,'GradUnit','mT/m',...
    'MaxSlew',130,'SlewUnit','T/m/s', ...
    'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6);

%% create scanner events
% satpulse
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]
fa_sat        = sat_b1*gyroRatio_rad*t_p; % flip angle of sat pulse
% create pulseq saturation pulse object
satPulse      = mr.makeBlockPulse(fa_sat, 'Duration', t_p, 'system', lims);

%% make SL pulses
adia_SL  = WriteSLExpPulseqPulses(sat_b1, lims);


% spoilers
spoilAmplitude = 0.8 .* lims.maxGrad; % [Hz/m]
spoilDuration = 4500e-6; % [s]
% create pulseq gradient object
gxSpoil=mr.makeTrapezoid('x','Amplitude',spoilAmplitude,'Duration',spoilDuration,'system',lims);
gySpoil=mr.makeTrapezoid('y','Amplitude',spoilAmplitude,'Duration',spoilDuration,'system',lims);
gzSpoil=mr.makeTrapezoid('z','Amplitude',spoilAmplitude,'Duration',spoilDuration,'system',lims);

% pseudo adc, not played out
pseudoADC = mr.makeAdc(1,'Duration', 1e-3);

%% loop through zspec offsets
offsets_ppm = linspace(-offset_range,offset_range,num_offsets);
offsets_Hz = offsets_ppm*gyroRatio_hz*B0; % Z spec offsets [Hz]
% init sequence
seq = mr.Sequence();
% add m0 scan if wished
if run_m0_scan
    seq.addBlock(mr.makeDelay(m0_t_rec));
    seq.addBlock(pseudoADC);
end

pre_sl = [];
post_sl = [];
accumPhase = 0;
% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz
    seq.addBlock(mr.makeDelay(t_rec)); % recovery time
    if currentOffset < 0
        pre_sl = adia_SL{find(ismember(adia_SL(:,2), 'pre_neg')),1};
        post_sl = adia_SL{find(ismember(adia_SL(:,2), 'post_neg')),1};
    else
        pre_sl = adia_SL{find(ismember(adia_SL(:,2), 'pre_pos')),1};
        post_sl = adia_SL{find(ismember(adia_SL(:,2), 'post_pos')),1};
    end
    
    % set frequency
   % pre_sl.phaseOffset = accumPhase;
    pre_sl.freqOffset = currentOffset;
    accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(pre_sl.signal)>0))*1e-6),2*pi);

    satPulse.phaseOffset = mod(accumPhase,2*pi);
    satPulse.freqOffset = currentOffset; % set freuqncy offset of the pulse
    accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(satPulse.signal)>0))*1e-6),2*pi);
    
    post_sl.phaseOffset = mod(accumPhase,2*pi);
    post_sl.freqOffset = currentOffset;
  %  accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(post_sl.signal)>0))*1e-6),2*pi); 
    
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

%% write sequence
seq.setDefinition('offsets_ppm', offsets_ppm);
seq.setDefinition('run_m0_scan', run_m0_scan);
seq.write(seq_filename);


