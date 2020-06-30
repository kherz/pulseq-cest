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
offset_range = 10;    % [ppm]
num_offsets  = 40;    % number of measurements (not including M0)
run_m0_scan  = true;  % if you want an M0 scan at the beginning
t_rec        = 2.4;   % recovery time between scans [s]
m0_t_rec     = 12;    % recovery time before m0 scan [s]
sat_b1       = 2.22;  % mean sat pulse b1 [uT]
t_p          = 50e-3; % sat pulse duration [s]
t_d          = 40e-3; % delay between pulses [s]
n_pulses     = 20;    % number of sat pulses per measurement
B0           = 3;     % B0 [T]
spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = 'example_APTw.seq'; % filename

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
satPulse      = mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', lims);

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
offsets_Hz = linspace(-offset_range,offset_range,num_offsets)*gyroRatio_hz*B0; % Z spec offsets [Hz]
% init sequence
seq = mr.Sequence();
% add m0 scan if wished
if run_m0_scan 
    seq.addBlock(mr.makeDelay(m0_t_rec));
    seq.addBlock(pseudoADC);
end

% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz
    seq.addBlock(mr.makeDelay(t_rec)); % recovery time
    satPulse.freqOffset = currentOffset; % set freuqncy offset of the pulse
    for np = 1:n_pulses
        seq.addBlock(satPulse) % add sat pulse
        if np < n_pulses % delay between pulses
            seq.addBlock(mr.makeDelay(t_d)); % add delay
        end
    end
    if spoiling % spoiling before readout
       seq.addBlock(gxSpoil,gySpoil,gzSpoil); 
    end
    seq.addBlock(pseudoADC); % readout trigger event
end

%% write sequence
seq.setDefinition('offsets_ppm', linspace(-offset_range,offset_range,num_offsets));
seq.setDefinition('run_m0_scan', run_m0_scan);
seq.write(seq_filename);


