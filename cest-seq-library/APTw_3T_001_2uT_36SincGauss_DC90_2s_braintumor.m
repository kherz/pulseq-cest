%% APTw_3T_001_2uT_36SincGauss_DC90_2s_braintumor
% An APTw protocol with above 90% DC and tsat of 2 s:
%
%     pulse shape = Sinc-Gaussian
%     B1cwpe = 2 uT
%     n_pulses = 36
%     tp = 50 ms
%     td = 5 ms
%     Tsat = n*(tp+td) = 2 s (1.975 s as last td is missing)
%     DCsat = 0.5 and 
%     Trec = 3.5/3.5 s (saturated/M0)
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec infos, adapt as you wish
offset_list = [-1560 -4:0.25:4];   % [ppm]
num_offsets = numel(offset_list);    % number of measurements (not including M0)
run_m0_scan = false;  % if you want an M0 scan with different recovertime and no sat at the beginning
Trec        = 3.5;   % recovery time between scans [s]
Trec_M0     = 3.5;    % recovery time before m0 scan [s]
B1pa        = 1.78;  % mean sat pulse b1 [uT]
tp          = 50e-3; % sat pulse duration [s]
td          = 5e-3; % delay between pulses [s]
n_pulses    = 36;    % number of sat pulses per measurement. if DC changes use: n_pulses = round(2/(t_p+t_d))
B0          = 3;     % B0 [T]
spoiling    = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

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

%satPulse      = mr.makeGaussPulse(fa_sat, 'Duration', t_p,'system',lims,'timeBwProduct', 0.2,'apodization', 0.5); % siemens-like gauss
satPulse      = mr.makeSincPulse(fa_sat, 'Duration', tp, 'system', lims,'timeBwProduct', 2,'apodization', 0.15); % philips-like sinc

[B1cwpe,B1cwae,B1cwae_pure,alpha]= calc_power_equivalents(satPulse,tp,td,1,gyroRatio_hz);

% spoilers
spoilRiseTime = 1e-3;
spoilDuration = 4500e-6+ spoilRiseTime; % [s]
% create pulseq gradient object
[gxSpoil, gySpoil, gzSpoil] = Create_spoiler_gradients(lims, spoilDuration, spoilRiseTime);

% pseudo adc, not played out
pseudoADC = mr.makeAdc(1,'Duration', 1e-3);

%% loop through zspec offsets
offsets_Hz = offset_list*gyroRatio_hz*B0;

% init sequence
seq = mr.Sequence();
% add m0 scan if wished
if run_m0_scan
    seq.addBlock(mr.makeDelay(Trec_M0));
    seq.addBlock(pseudoADC);
end

% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz
    if Trec > 0
        seq.addBlock(mr.makeDelay(Trec)); % recovery time
    end
    satPulse.freqOffset = currentOffset; % set freuqncy offset of the pulse
    accumPhase=0;
    for np = 1:n_pulses     
        satPulse.phaseOffset = mod(accumPhase,2*pi); % set accumulated pahse from previous rf pulse
        seq.addBlock(satPulse) % add sat pulse
        % calc phase for next rf pulse
        accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(satPulse.signal)>0))*1e-6),2*pi);
        if np < n_pulses % delay between pulses
            seq.addBlock(mr.makeDelay(td)); % add delay
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

%% plot
save_seq_plot(seq_filename);

%% call standard sim
Simulate_and_plot_seq_file(seq_filename, B0);




