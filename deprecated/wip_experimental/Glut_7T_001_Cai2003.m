%% Write .seq file
% The gluCEST protocol is taken from:
% Cai K, Haris M, Singh A, et al. Magnetic resonance imaging of glutamate.
% Nat Med. 2012;18(2):302-306. Published 2012 Jan 22. doi:10.1038/nm.2615
%
% Supp. Info if this paper:
% New pulse sequence codes were developed for both Varian and Siemens scanners to use a
% frequency selective saturation pulse followed by a segmented RF spoiled gradient echo
% (GRE) readout sequence. To take into account scanner system limitations, the sequence
% uses saturation pulse trains with variable shapes and durations as well as delays. Results
% with minimal artifacts were obtained using a series of 10 to 30 Hanning windowed
% rectangular pulses of 100 ms duration each separated by a 200 ?s delay. The excitation
% bandwidth of this saturation pulse train was 5 Hz for a 1 s saturation duration with a 1
% bandwidth of 20 Hz.
%
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec infos, adapt as you wish
offset_range = 5;    % [ppm]
num_offsets  = 50;    % number of measurements (not including M0)
run_m0_scan  = false;  % if you want an M0 scan at the beginning
t_rec        = 2;   % recovery time between scans [s]
m0_t_rec     = 12;    % recovery time before m0 scan [s]
sat_b1       = 1.96;  % mean sat pulse b1 [uT]
t_p          = 100e-3; % sat pulse duration [s]
t_d          = 0.2*1e-3; % delay between pulses [s]
n_pulses     = 10;    % number of sat pulses per measurement
B0           = 7;     % B0 [T]
spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = strcat(mfilename,'.seq'); % filename

%% scanner limits
% see pulseq doc for more ino
lims = Get_scanner_limits();

%% create scanner events
% satpulse
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]
fa_sat        = sat_b1*gyroRatio_rad*t_p; % flip angle of sat pulse
% create pulseq saturation pulse object
satPulse      = mr.makeGaussPulse(fa_sat, 'Duration', t_p, 'timeBwProduct', 0.2,'apodization', 0.5, 'system', lims);

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


%% call standard sim
Simulate_and_plot_seq_file(seq_filename, B0);



