%% APTw_3T_DC50
% An APTw protocol with a ~90% DC and tsat of 2.2s:
%
%     pulse shape = Gaussian
%     B1 = 2 uT
%     n = 40
%     t_p = 50 ms
%     t_d = 5 ms
%     DC = 0.5 and t_sat = n*(t_p+t_d) = 2 s
%     T_rec = 2.4/12 s (saturated/M0)
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec infos, adapt as you wish
offset_list = [-4, -3.75, -3.75, -3.5, -3.5, -3.25, -3.25, -3, 3, 3.25, 3.25, 3.5, 3.5 3.75, 3.75, 4];    % [ppm]
offset_list = [-1560 -4:0.25:4];   % [ppm]
num_offsets  = numel(offset_list);    % number of measurements (not including M0)
run_m0_scan  = false;  % if you want an M0 scan with different recovertime and no sat at the beginning
t_rec        = 3.5;   % recovery time between scans [s]
m0_t_rec     = 3.5;    % recovery time before m0 scan [s]
sat_b1       = 2;  % mean sat pulse b1 [uT]
t_p          = 100e-3; % sat pulse duration [s]
t_d          = 1e-3; % delay between pulses [s]
n_pulses     = 8;    % number of sat pulses per measurement
B0           = 3;     % B0 [T]
spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = 'APTw_3T_800ms.seq'; % filename

%% scanner limits
% see pulseq doc for more ino
lims = Get_scanner_limits();

%% create scanner events
% satpulse
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]
fa_sat        = sat_b1*gyroRatio_rad*t_p; % flip angle of sat pulse
% create pulseq saturation pulse object
satPulse      = mr.makeBlockPulse(fa_sat, 'Duration', t_p, 'system', lims);

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
        
        satPulse.phaseOffset = mod(accumPhase,2*pi); % set accumulated pahse from previous rf pulse
        
        seq.addBlock(satPulse) % add sat pulse
        
        % calc phase for next rf pulse
        accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(satPulse.signal)>0))*1e-6),2*pi);
        
        if np < n_pulses % delay between pulses
            seq.addBlock(mr.makeDelay(t_d)); % add delay
            if mod(np,2) == 0
                seq.addBlock(mr.makeDelay(10e-3));
            end
        end
    end
    if spoiling % spoiling before readout
        seq.addBlock(gxSpoil,gySpoil,gzSpoil);
    end
    seq.addBlock(pseudoADC); % readout trigger event
end

[B1cwpe,B1cwae,B1cwae_pure,alpha]= calc_power_equivalents(satPulse,t_p,t_d,1,gyroRatio_hz);


%% write sequence
seq.setDefinition('offsets_ppm',offset_list);
seq.setDefinition('run_m0_scan', run_m0_scan);
seq.write(seq_filename);

%% call standard sim
Simulate_and_plot_seq_file(seq_filename, B0);


