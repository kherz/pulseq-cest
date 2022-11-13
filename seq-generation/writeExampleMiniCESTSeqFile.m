%% MiniCEST_3T_example
% Creates a minimal sequence file for an CEST protocol.

% Moritz Zaiss 2022
% moritz.zaiss@fau.de

% author name for sequence file
author = 'Moritz Zaiss';
seq_id_string = 'MiniCEST_example'; % unique seq id

%% scanner limits 
% see pulseq doc for more info
% init sequence
tic
seq = SequenceSBB(getScannerLimits()); % standard is a 3T system
seq.sys

%% create scanner events
% create pulseq saturation pulse object with FA= 3000 and tp=100ms
satPulse      = mr.makeGaussPulse( 3000*pi/180 , 'Duration', 0.1, 'system',seq.sys,'timeBwProduct', 0.2,'apodization', 0.5); % siemens-like gauss
% resample pulse for reduced file size and io time
satPulse      = resamplePulseForRLE(satPulse, 200); 

[B1cwpe,B1cwae,B1cwae_pure,alpha]= calculatePowerEquivalents(satPulse,0.1,0.05,1,1e-6*seq.sys.gamma); % get more info on the generated pulse

%% loop through zspec offsets
B0=3;  % field strength in T
offsets_ppm=[-300 -5:0.5:5];  % offset list with an M0 scan at -300 ppm
offsets_Hz = offsets_ppm *1e-6 *seq.sys.gamma  * B0;

% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz

    seq.addBlock(mr.makeDelay(2)); % recovery time of 2 s before each saturation
    satPulse.freqOffset = currentOffset; % set frequency offset of the pulse
    n_pulses=10;
    for np = 1:n_pulses
        seq.addBlock(satPulse) % add sat pulse
        if np < n_pulses % delay between pulses
            seq.addBlock(mr.makeDelay(0.05)); % add delayof 50 ms if not end of train
        end
    end
    seq.addPseudoADCBlock(); % readout trigger event
end

%% write definitions
seq.setDefinition('seq_id_string', seq_id_string);
seq.setDefinition('B0', 3);
seq.write([seq_id_string '.seq'], author);

%% plot
seq.plot();                 % plots the full sequence
seq.plotSaturationPhase();  % plots a single preparation phase

toc

%% run simulation
M_z = simulate_pulseqcest(seq, which('GM_3T_example_bmsim.yaml'));
figure(9), plot(M_z); hold on;
