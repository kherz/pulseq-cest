%% APTw_3T_DC50
% An APTw protocol with a 50% DC and tsat of 2s:
%
%     pulse shape = Gaussian
%     B1cwpe = 2 uT
%     n_pulses = 20
%     t_p = 50 ms
%     t_d = 50 ms
%     t_sat = n*(t_p+t_d) = 2 s (1.95 s as last td is missing)
%     DC = 0.5 and 
%     t_rec = 3.5/3.5 s (saturated/M0)   (time after the last readout event and before the next saturation)
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec infos, adapt as you wish
offset_list = [-1560-4, -3.75, -3.75, -3.5, -3.5, -3.25, -3.25, -3, 3, 3.25, 3.25, 3.5, 3.5 3.75, 3.75, 4];    % [ppm]
offset_list = [-1560 -4:0.25:4];   % [ppm]
num_offsets  = numel(offset_list);    % number of measurements (not including M0)
run_m0_scan  = false;  % if you want an M0 scan with different recovertime and no sat at the beginning
t_rec        = 3.5;   % recovery time between scans [s]
m0_t_rec     = 3.5;    % recovery time before m0 scan [s]
sat_b1       = 2.31;  % mean sat pulse b1 [uT]  % 2.41 for philips pulse
t_p          = 50e-3; % sat pulse duration [s]
t_d          = 50e-3; % delay between pulses [s]
n_pulses     = 20;    % number of sat pulses per measurement. if DC changes use: n_pulses = round(2/(t_p+t_d))
tsat= n_pulses*t_p+(n_pulses-1)*t_d
B0           = 3;     % B0 [T]
spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = 'APTw_3T_DC50.seq'; % filename

%% scanner limits
% see pulseq doc for more ino
lims = Get_scanner_limits();

%% create scanner events
% satpulse
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]
fa_sat        = sat_b1*gyroRatio_rad*t_p; % flip angle of sat pulse
% create pulseq saturation pulse object
satPulse      = mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'system', lims,'timeBwProduct', 0.2,'apodization', 0.5);
%satPulse      = mr.makeSincPulse(fa_sat, 'Duration', t_p, 'system', lims,'timeBwProduct', 2,'apodization', 0.15);

[B1cwpe,B1cwae,B1cwae_pure,alpha]= calc_power_equivalents(satPulse,t_p,t_d,1,gyroRatio_hz);

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
offsets_Hz = offset_list*gyroRatio_hz*B0;

% init sequence
seq = mr.Sequence();
% add m0 scan if wished
if run_m0_scan
    seq.addBlock(mr.makeDelay(m0_t_rec));
    seq.addBlock(pseudoADC);
end

% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz
    if t_rec > 0
        seq.addBlock(mr.makeDelay(t_rec)); % recovery time
    end
    satPulse.freqOffset = currentOffset; % set freuqncy offset of the pulse
    accumPhase=0;
    for np = 1:n_pulses
        seq.addBlock(satPulse) % add sat pulse
        % calc phase for next rf pulse
         accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(satPulse.signal)>0))*1e-6),2*pi);
        
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
seq.setDefinition('offsets_ppm',offset_list);
seq.setDefinition('run_m0_scan', run_m0_scan);
seq.write(seq_filename);

%% call standard sim
Simulate_and_plot_seq_file(seq_filename, B0);

