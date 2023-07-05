%% OH_3T_example
% Creates a sequence file for a Z-spectrum with adiabatic SL pulses
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

% author name for sequence file
author = 'Kai Herz';

%% get correct path
script_fp = fullfile(getPulseqCESTRootDir, 'seq-generation');

%% sequence definitions
% everything in defs gets written as definition in .seq-file
defs.n_pulses      = 1              ; % number of pulses
defs.tp            = 100e-3         ; % pulse duration [s]
defs.Trec          = 5              ; % recovery time [s]
defs.Trec_M0       = 5             ; % recovery time before M0 [s]
defs.M0_offset     = -300           ; % m0 offset [ppm]
defs.DCsat         = 1              ; % duty cycle
defs.offsets_ppm   = [defs.M0_offset linspace(-4,4,24)]; % offset vector [ppm]
defs.num_meas      = numel(defs.offsets_ppm); % number of repetition
defs.Tsat          = defs.tp + 2*12e-3;  % locking + 2 x adiabatic pulses
defs.B0            = 3               ; % B0 [T]
defs.seq_id_string = 'OH_3T_example' ; % unique seq id
defs.B1pa        = 4;  % mean sat pulse b1 [uT]
defs.spoiling    = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = fullfile(script_fp, '../examples', strcat(defs.seq_id_string,'.seq')); % filename

%% init sequence
seq = SequenceSBB(getScannerLimits());
gamma_hz  = seq.sys.gamma*1e-6;                  % for H [Hz/uT]
%% create scanner events
% satpulse
gamma_rad = gamma_hz*2*pi;        % [rad/uT]
fa_sat        = defs.B1pa*gamma_rad*defs.tp; % flip angle of sat pulse
% create pulseq saturation pulse object
satPulse      = mr.makeBlockPulse(fa_sat, 'Duration', defs.tp, 'system', seq.sys);
defs.B1cwpe = defs.B1pa;

%% make SL pulses
adia_SL  = makeSLExpPulses(defs.B1pa, seq.sys);

%% loop through zspec offsets
offsets_Hz = defs.offsets_ppm*gamma_hz*defs.B0; % Z spec offsets [Hz]

pre_sl = [];
post_sl = [];
accumPhase = 0;
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
    if currentOffset < 0
        pre_sl = adia_SL{find(ismember(adia_SL(:,2), 'pre_neg')),1};
        post_sl = adia_SL{find(ismember(adia_SL(:,2), 'post_neg')),1};
    else
        pre_sl = adia_SL{find(ismember(adia_SL(:,2), 'pre_pos')),1};
        post_sl = adia_SL{find(ismember(adia_SL(:,2), 'post_pos')),1};
    end
    % set frequency
    pre_sl.freqOffset = currentOffset;
    accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(pre_sl.signal)>0))*1e-6),2*pi);
    
    satPulse.phaseOffset = mod(accumPhase,2*pi);
    satPulse.freqOffset = currentOffset; % set freuqncy offset of the pulse
    accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(satPulse.signal)>0))*1e-6),2*pi);
    
    post_sl.phaseOffset = mod(accumPhase,2*pi);
    post_sl.freqOffset = currentOffset;
    for np = 1:defs.n_pulses
        seq.addBlock(pre_sl)
        seq.addBlock(satPulse) % add sat pulse
        seq.addBlock(post_sl)
        if np < defs.n_pulses % delay between pulses
            seq.addBlock(mr.makeDelay(defs.t_d)); % add delay
        end
    end
    if defs.spoiling % spoiling before readout
        seq.addSpoilerGradients();
    end
    seq.addPseudoADCBlock(); % readout trigger event
    accumPhase = 0;
end

%% write definitions
def_fields = fieldnames(defs);
for n_id = 1:numel(def_fields)
    seq.setDefinition(def_fields{n_id}, defs.(def_fields{n_id}));
end
seq.write(seq_filename, author);


