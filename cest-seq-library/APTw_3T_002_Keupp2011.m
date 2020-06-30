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

offsets_ppm = offsets_ppm([1,7,21]); % reduced for faster plotting

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
lims = mr.opts('MaxGrad',40,'GradUnit','mT/m',...
    'MaxSlew',130,'SlewUnit','T/m/s', ...
    'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6);

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
seq.setDefinition('offsets_ppm', offsets_ppm);
seq.setDefinition('run_m0_scan', run_m0_scan);
seq.write(seq_filename);

seq.plot();

%% call standard sim
M_z=Standard_pulseq_cest_Simulation(seq_filename,B0);

%% Zspec and ASYM calculation
seq = mr.Sequence;
seq.read(seq_filename);
[ppm_sort, idx] = sort(seq.definitions('offsets_ppm'));

% MTRasym contrast map generation
% if your data was acquired as in the seq file, the following code works for each pixel of such a 4D stack

M0=M_z(1); % first is normalization scan at -1560 ppm
ppm_sort=ppm_sort(2:end);
Z=M_z(2:end)/M0;
MTRasym=Z(end:-1:1)-Z;


figure,
plot(ppm_sort, Z,'Displayname','Z-spectrum'); set(gca,'xdir','reverse'); hold on;
plot(ppm_sort,MTRasym,'Displayname','MTR_{asym}');
xlabel('\Delta\omega [ppm]'); legend show;

% The single MTRAsym vlaue that would form the pixel intensity can be obtained like this:
ppm_sort(1) % test to find the right index for the offset of interest
MTRasym(1)



