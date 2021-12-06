%% Write exmpe pulseqSBB .seq file
% The IOPA3D protocol is taken from:
% to be published
%
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec info
offset_range = 7;    % [ppm]

num_offsets  = 50;    % number of measurements (not including M0)
run_m0_scan  = true;  % if you want an M0 scan at the beginning
t_rec        = 1;   % recovery time between scans [s]
m0_t_rec     = 1;    % recovery time before m0 scan [s]
sat_b1       = 3;  % mean sat pulse b1 [uT]
t_p          = 3000e-3; % sat pulse duration [s]
t_d          = 0; % delay between pulses [s]
n_pulses     = 1;    % number of sat pulses per measurement
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
satPulse      = mr.makeBlockPulse(fa_sat, 'Duration', t_p, 'system', lims);

% spoilers
spoilAmplitude = 0.8 .* lims.maxGrad; % [Hz/m]
spoilDuration = 4500e-6; % [s]
% create pulseq gradient object 
gxSpoil=mr.makeTrapezoid('x','Amplitude',spoilAmplitude,'Duration',spoilDuration,'system',lims);
gySpoil=mr.makeTrapezoid('y','Amplitude',spoilAmplitude,'Duration',spoilDuration,'system',lims);
gzSpoil=mr.makeTrapezoid('z','Amplitude',spoilAmplitude,'Duration',spoilDuration,'system',lims);

% pseudo adc, not played out
pseudoADC = mr.makeAdc(1,'Duration', 10e-3);

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
    if t_rec>0 seq.addBlock(mr.makeDelay(t_rec)); end % recovery time
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
ppm_sort(3) % test to find the right index for the offset of interest
MTRasym(3)


