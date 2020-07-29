%% Write exmpe pulseqSBB .seq file
% The APTw protocol is taken from:
% https://onlinelibrary.wiley.com/doi/full/10.1002/jmri.26645
% see Figure 2b
% and 
% Keupp J, Baltes C, Harvey PR, van den Brink J. Parallel RF transmission
% based MRI technique for highly sensitive detection of amide proton
% transfer in the human brain. In: Proc 19th Annual Meeting ISMRM, Montreal;
% 2011. p 710.
%
% Togao O, Hiwatashi A, Keupp J, et al. Amide proton transfer imaging of diffuse gliomas: Effect of saturation pulse length in parallel transmission-based technique. 
% PLoS One 2016;11:e0155925.
% 
%
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec info
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]
B0           = 3;    % B0 [T]
offset_range = 6;    % [ppm]
offsets_ppm = [-1560 -offset_range:0.5:offset_range]; % Z spec offsets [Hz]

offsets_Hz = offsets_ppm*gyroRatio_hz*B0; % Z spec offsets [Hz]

run_m0_scan  = false;  % if you want an M0 scan at the beginning
t_rec        = 2.4;   % recovery time between scans [s]
m0_t_rec     = 12;    % recovery time before m0 scan [s]
sat_b1       = 2;  % mean sat pulse b1 [uT]
t_p          = 50e-3; % sat pulse duration [s]
t_d          = 0.001*1e-3; % delay between pulses [s]
n_pulses     = 40;    % number of sat pulses per measurement

spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = strcat(mfilename,'.seq'); % filename

%% scanner limits 
% see pulseq doc for more ino
lims = Get_scanner_limits();

%% create scanner events
% satpulse
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
disp('Creating sequence ... ');
t_start = tic;
% init sequence
seq = mr.Sequence();
% add m0 scan if wished
if run_m0_scan 
    seq.addBlock(mr.makeDelay(m0_t_rec));
    seq.addBlock(pseudoADC);
end

% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz
    accumPhase = 0;
    seq.addBlock(mr.makeDelay(t_rec)); % recovery time
    satPulse.freqOffset = currentOffset; % set freuqncy offset of the pulse
    for np = 1:n_pulses
        satPulse.phaseOffset = accumPhase;
        seq.addBlock(satPulse) % add sat pulse
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
t_end = toc(t_start);
disp(['Creating sequence took ' num2str(t_end) ' s']);
%% write sequence
seq.setDefinition('offsets_ppm', offsets_ppm);
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
Simulate_and_plot_seq_file(seq_filename,B0);

