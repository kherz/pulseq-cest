%% APTw_3T_example
% Creates a sequence file for an APTw protocol according to:
% https://cest-sources.org/doku.php?id=standard_cest_protocols

% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

% author name for sequence file
author = 'Kai Herz';

%% get correct path
script_fp = fullfile(getPulseqCESTRootDir, 'seq-generation');

%% sequence definitions
% everything in defs gets written as definition in .seq-file
defs.n_pulses      = 20              ; % number of pulses
defs.tp            = 50e-3           ; % pulse duration [s]
defs.td            = 40e-3            ; % interpulse delay [s]
defs.Trec          = 2.4             ; % recovery time [s]
defs.Trec_M0       = 12             ; % recovery time before M0 [s]
defs.M0_offset     = -300           ; % m0 offset [ppm]
defs.DCsat         = (defs.tp)/(defs.tp+defs.td); % duty cycle
defs.offsets_ppm   = [defs.M0_offset linspace(-8,8,40)]; % offset vector [ppm]
defs.num_meas      = numel(defs.offsets_ppm)   ; % number of repetition
defs.Tsat          = defs.n_pulses*(defs.tp+defs.td) - ...
                         defs.td ;  % saturation time [s]
defs.B0            = 3                ; % B0 [T]
defs.seq_id_string = 'APTw_3T_example'; % unique seq id

defs.B1pa        = 2.22;  % mean sat pulse b1 [uT]
defs.spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = fullfile(script_fp, '../examples', strcat(defs.seq_id_string,'.seq')); % filename

%% scanner limits 
% see pulseq doc for more ino
% init sequence
seq = SequenceSBB(getScannerLimits());
gamma_hz  =seq.sys.gamma*1e-6;                  % for H [Hz/uT]
%% create scanner events
% satpulse
gamma_rad = gamma_hz*2*pi;        % [rad/uT]
fa_sat        = defs.B1pa*gamma_rad*defs.tp; % flip angle of sat pulse

% create pulseq saturation pulse object
satPulse      = mr.makeGaussPulse(fa_sat, 'Duration', defs.tp, 'system',seq.sys,'timeBwProduct', 0.2,'apodization', 0.5); % siemens-like gauss
% resample pulse for reduced file size and io time
satPulse      = resamplePulseForRLE(satPulse, 1000); 

[B1cwpe,B1cwae,B1cwae_pure,alpha]= calculatePowerEquivalents(satPulse,defs.tp,defs.td,0,gamma_hz);
defs.B1cwpe = B1cwpe;


%% loop through zspec offsets
offsets_Hz = defs.offsets_ppm*gamma_hz*defs.B0;


% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz
    if currentOffset == defs.M0_offset*gamma_hz*defs.B0
        if defs.Trec_M0 > 0
            seq.addBlock(mr.makeDelay(defs.Trec_M0));
        end
    else
        if defs.Trec > 0
            seq.addBlock(mr.makeDelay(defs.Trec)); % recovery time
        end
    end
    satPulse.freqOffset = currentOffset; % set freuqncy offset of the pulse
    accumPhase=0;
    for np = 1:defs.n_pulses
        satPulse.phaseOffset = mod(accumPhase,2*pi); % set accumulated pahse from previous rf pulse
        seq.addBlock(satPulse) % add sat pulse
        % calc phase for next rf pulse
        accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(satPulse.signal)>0))*1e-6),2*pi);
        if np < defs.n_pulses % delay between pulses
            seq.addBlock(mr.makeDelay(defs.td)); % add delay
        end
    end
    if defs.spoiling % spoiling before readout
        seq.addSpoilerGradients();
    end
    seq.addPseudoADCBlock(); % readout trigger event
end



%% write definitions
def_fields = fieldnames(defs);
for n_id = 1:numel(def_fields)
    seq.setDefinition(def_fields{n_id}, defs.(def_fields{n_id}));
end
seq.write(seq_filename, author);

%% plot
seq.plotSaturationPhase();

