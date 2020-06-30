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

num_offsets  = 2;    % reduced for faster plotting

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

seq.plot();

%% call standard sim
M_z=Standard_pulseq_cest_Simulation(seq_filename,B0);

%% Zspec and ASYM calculation
seq = mr.Sequence;
seq.read(seq_filename);
[ppm_sort, idx] = sort(seq.definitions('offsets_ppm'));

% MTRasym contrast map generation
% if your data was acquired as in the seq file, the following code works for each pixel of such a 4D stack

if seq.definitions('run_m0_scan')
     M0=M_z(1);
     Z=M_z(2:end)/M0;
     MTRasym=Z(end:-1:1)-Z;
else
     Z=M_z;
     MTRasym=Z(end:-1:1)-Z;
end

figure,
plot(ppm_sort, Z,'Displayname','Z-spectrum'); set(gca,'xdir','reverse'); hold on;
plot(ppm_sort,MTRasym,'Displayname','MTR_{asym}');
xlabel('\Delta\omega [ppm]'); legend show;

% The single MTRAsym vlaue that would form the pixel intensity can be obtained like this:
ppm_sort(1) % test to find the right index for the offset of interest
MTRasym(1)



