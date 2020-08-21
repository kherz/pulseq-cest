%% Write exmpe pulseqSBB .seq file
% The APTw protocol is taken from:
% https://onlinelibrary.wiley.com/doi/full/10.1002/jmri.26645
% see Figure 2a
% and more details in 
% Zhu, H., Jones, C.K., van Zijl, P.C.M., Barker, P.B. and Zhou, J. (2010), 
% Fast 3D chemical exchange saturation transfer (CEST) imaging of the human brain. 
% Magn. Reson. Med., 64: 638-644. doi:10.1002/mrm.22546
%
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec info
offset_range = 10;    % [ppm]
num_offsets  = 7;    % number of measurements (not including M0)
run_m0_scan  = false;  % if you want an M0 scan at the beginning
t_rec        = 0;   % recovery time between scans [s]
m0_t_rec     = 12;    % recovery time before m0 scan [s]
sat_b1       = 2;  % mean sat pulse b1 [uT]
t_p          = 200e-3; % sat pulse duration [s]
t_d          = 10*1e-3; % delay between pulses [s]
n_pulses     = 4;    % number of sat pulses per measurement
B0           = 3;     % B0 [T]
spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z
gyroRatio_hz  = 42.5764; % for H [Hz/uT]

seq_filename = strcat(mfilename,'.seq'); % filename

%% scanner limits 
% see pulseq doc for more ino
lims = Get_scanner_limits();

%% create scanner events
% satpulse
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]
fa_sat        = sat_b1*gyroRatio_rad*t_p; % flip angle of sat pulse
% create pulseq saturation pulse object 
satPulse      = mr.makeBlockPulse(fa_sat, 'Duration', t_p, 'system', lims);

[B1cwpe,B1cwae,B1cwae_pure,alpha]= calc_power_equivalents(satPulse,t_p,t_d,1,gyroRatio_hz);

% spoilers
spoilRiseTime = 1e-3;
spoilDuration = 4500e-6+ spoilRiseTime; % [s]
% create pulseq gradient object
[gxSpoil, gySpoil, gzSpoil] = Create_spoiler_gradients(lims, spoilDuration, spoilRiseTime);

% pseudo adc, not played out
pseudoADC = mr.makeAdc(1,'Duration', 10e-3);

%% loop through zspec offsets
disp('Creating sequence ... ');
t_start = tic;
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
    accumPhase = 0;
    if t_rec>0 seq.addBlock(mr.makeDelay(t_rec)); end % recovery time
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
seq.setDefinition('offsets_ppm', linspace(-offset_range,offset_range,num_offsets));
seq.setDefinition('run_m0_scan', run_m0_scan);
seq.write(seq_filename);

%% plot
disp('Plotting .seq file ... ');
t_start = tic;
seq.plot();
t_end = toc(t_start);
disp(['Plotting .seq file took ' num2str(t_end) ' s']);
save_seq_plot(seq_filename);

%% call standard sim and plot results
Simulate_and_plot_seq_file(seq_filename,B0);

