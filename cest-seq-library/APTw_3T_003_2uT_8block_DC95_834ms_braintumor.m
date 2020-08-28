%% APTw_3T_003_2uT_block_DC95_0.83s_braintumor.seq           
% An APTw protocol with B1cwpe = 2 uT, a DC ~96% and t_sat of 833 ms:
%
%     pulse shape = block
%     B1cwpe = 2 uT
%     n = 8
%     tp = 0.1 s
%     td = 1 ms and 10 ms for odd and even resp. (to have shortest possible delay at Siemens)
%     Tsat = n*tp + (n/2-1)*10 + (n/2)*1 = 834 ms
%     DCsat = n*tp/Tsat = 96.04% 
%     Trec = 3.5/3.5 s (saturated/M0)  (time after the last readout event and before the next saturation)
%
% Kai Herz 2020
% kai.herz@tuebingen.mpg.de

%% Zspec infos, adapt as you wish
offset_list = [-4, -3.75, -3.75, -3.5, -3.5, -3.25, -3.25, -3, 3, 3.25, 3.25, 3.5, 3.5 3.75, 3.75, 4];    % [ppm]
offset_list = [-1560 -4:0.25:4];   % [ppm]
num_offsets  = numel(offset_list);    % number of measurements (not including M0)
run_m0_scan  = false;  % if you want an M0 scan with different recovertime and no sat at the beginning
Trec        = 3.5;   % recovery time between scans [s]
Trec_M0      = 3.5;    % recovery time before m0 scan [s]
B1pa         = 2;  % mean sat pulse b1 [uT]
tp           = 100e-3; % sat pulse duration [s]
td           = 1e-3; % delay between pulses [s]
n_pulses     = 8;    % number of sat pulses per measurement
B0           = 3;     % B0 [T]
spoiling     = 1;     % 0=no spoiling, 1=before readout, Gradient in x,y,z

seq_filename = strcat(mfilename,'.seq'); % filename

%% scanner limits
% see pulseq doc for more ino
lims = Get_scanner_limits();

%% create scanner events
% satpulse
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]
fa_sat        = B1pa*gyroRatio_rad*tp; % flip angle of sat pulse
% create pulseq saturation pulse object
satPulse      = mr.makeBlockPulse(fa_sat, 'Duration', tp, 'system', lims);

% spoilers
spoilRiseTime = 1e-3;
spoilDuration = 4500e-6+ spoilRiseTime; % [s]
% create pulseq gradient object
[gxSpoil, gySpoil, gzSpoil] = Create_spoiler_gradients(lims, spoilDuration, spoilRiseTime);

% pseudo adc, not played out
pseudoADC = mr.makeAdc(1,'Duration', 1e-3);

%% loop through zspec offsets
offsets_Hz = offset_list*gyroRatio_hz*B0;

% init sequence
seq = mr.Sequence();
% add m0 scan if wished
if run_m0_scan
    seq.addBlock(mr.makeDelay(Trec_M0));
    seq.addBlock(pseudoADC);
end

% loop through offsets and set pulses and delays
for currentOffset = offsets_Hz
    if Trec > 0
        seq.addBlock(mr.makeDelay(Trec)); % recovery time
    end
    satPulse.freqOffset = currentOffset; % set freuqncy offset of the pulse
    accumPhase=0;
    for np = 1:n_pulses
        
        satPulse.phaseOffset = mod(accumPhase,2*pi); % set accumulated pahse from previous rf pulse
        
        seq.addBlock(satPulse) % add sat pulse
        
        % calc phase for next rf pulse
        accumPhase = mod(accumPhase + currentOffset*2*pi*(numel(find(abs(satPulse.signal)>0))*1e-6),2*pi);
        
        if np < n_pulses % delay between pulses
            if mod(np,2) == 0
                seq.addBlock(mr.makeDelay(10e-3));
            else
                seq.addBlock(mr.makeDelay(td)); % add delay
            end
        end
    end
    if spoiling % spoiling before readout
        seq.addBlock(gxSpoil,gySpoil,gzSpoil);
    end
    seq.addBlock(pseudoADC); % readout trigger event
end

[B1cwpe,B1cwae,B1cwae_pure,alpha]= calc_power_equivalents(satPulse,tp,td,1,gyroRatio_hz);


%% write sequence
seq.setDefinition('offsets_ppm',offset_list);
seq.setDefinition('run_m0_scan', run_m0_scan);
seq.write(seq_filename);

%% plot
save_seq_plot(seq_filename);

%% call standard sim
Simulate_and_plot_seq_file(seq_filename, B0);


