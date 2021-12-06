%% APTw_3T_example
% Creates a sequence file for an APTw protocol according to:
% https://cest-sources.org/doku.php?id=standard_cest_protocols

% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

% author name for sequence file
author = 'Kai Herz';

%% get correct path
script_fp = []; 
if strcmp(mfilename, 'LiveEditorEvaluationHelperESectionEval')
    script_fp = fileparts(matlab.desktop.editor.getActiveFilename);
else
    script_fp = fileparts(which(mfilename));
end


%% sequence definitions
% everything in seq_defs gets written as definition in .seq-file
seq_defs.n_pulses      = 20              ; % number of pulses
seq_defs.tp            = 50e-3           ; % pulse duration [s]
seq_defs.td            = 40e-3            ; % interpulse delay [s]
seq_defs.Trec          = 2.4             ; % recovery time [s]
seq_defs.Trec_M0       = 12             ; % recovery time before M0 [s]
seq_defs.M0_offset     = -300           ; % m0 offset [ppm]
seq_defs.DCsat         = (seq_defs.tp)/(seq_defs.tp+seq_defs.td); % duty cycle
seq_defs.offsets_ppm   = [seq_defs.M0_offset linspace(-8,8,40)]; % offset vector [ppm]
seq_defs.num_meas      = numel(seq_defs.offsets_ppm)   ; % number of repetition
seq_defs.Tsat          = seq_defs.n_pulses*(seq_defs.tp+seq_defs.td) - ...
                         seq_defs.td ;  % saturation time [s]
seq_defs.B0            = 3                ; % B0 [T]
seq_defs.seq_id_string = 'APTw_3T_example'; % unique seq id

%% get info from struct
offsets_ppm = seq_defs.offsets_ppm; % [ppm]
Trec        = seq_defs.Trec;        % recovery time between scans [s]
Trec_M0     = seq_defs.Trec_M0;     % recovery time before m0 scan [s]
tp          = seq_defs.tp;          % sat pulse duration [s]
td          = seq_defs.td;          % delay between pulses [s]
n_pulses    = seq_defs.n_pulses;    % number of sat pulses per measurement. if DC changes use: n_pulses = round(2/(t_p+t_d))
B0          = seq_defs.B0;          % B0 [T]
B1pa        = 2.22;  % mean sat pulse b1 [uT]
spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = fullfile(script_fp, '../examples', strcat(seq_defs.seq_id_string,'.seq')); % filename

%% scanner limits 
% see pulseq doc for more ino
% init sequence
seq = SequenceSBB(getScannerLimits());

%% create scanner events
% satpulse
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]
fa_sat        = B1pa*gyroRatio_rad*tp; % flip angle of sat pulse

% create pulseq saturation pulse object
satPulse      = mr.makeGaussPulse(fa_sat, 'Duration', tp, 'system',seq.sys,'timeBwProduct', 0.2,'apodization', 0.5); % siemens-like gauss
% resample pulse for reduced file size and io time
satPulse      = resamplePulseForRLE(satPulse, 1000); 

[B1cwpe,B1cwae,B1cwae_pure,alpha]= calculatePowerEquivalents(satPulse,tp,td,0,gyroRatio_hz);
seq_defs.B1cwpe = B1cwpe;


%% loop through zspec offsets
offsets_Hz = offsets_ppm*gyroRatio_hz*B0;


% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz
    if currentOffset == seq_defs.M0_offset*gyroRatio_hz*B0
        if Trec_M0 > 0
            seq.addBlock(mr.makeDelay(Trec_M0));
        end
    else
        if Trec > 0
            seq.addBlock(mr.makeDelay(Trec)); % recovery time
        end
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
        seq.addSpoilerGradients();
    end
    seq.addPseudoADCBlock(); % readout trigger event
end



%% write definitions
def_fields = fieldnames(seq_defs);
for n_id = 1:numel(def_fields)
    seq.setDefinition(def_fields{n_id}, seq_defs.(def_fields{n_id}));
end
seq.write(seq_filename, author);

%% plot
seq.plotSaturationPhase();

