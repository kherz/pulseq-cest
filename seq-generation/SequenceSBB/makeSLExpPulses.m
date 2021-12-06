%% make pulseq rf objects for slexp pulse
% input:  B1:      b1 amplitude in uT
%         lims:    scanner limits
% output: adia_SL: 4x2 cell array with apmlitude(n,1) and phase(n,2)
% modulation for the 4 different cases of the hsexp pulses
function adia_SL = makeSLExpPulses(B1,lims)

%% pulse definition
tp_us = 12000;
tp = tp_us*1e-6;
bw = 2500;
mu = 65;
twindow = 3500*1e-6;
ef = 3.5;
samples = tp_us;
tpulse = (1:samples)./samples*tp;
%B1 = 4; %[ut]
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]


%%
% containers for increasing amplitude and frequency
amp =  [true false];
freq = [true false];

% allocate vectors for amplitude, frequency and phase
w1 = zeros(4,samples);
dfreq = zeros(4,samples);
dphase = zeros(4,samples);

%loop through amplitude and frequency bool arrays
for ii = 1:2
    incAmp = amp(ii);
    for jj = 1:2
        incFreq = freq(jj);
        
        %row in amplitue, freq and phase array
        idx = (ii-1)*2+jj;
        
        %get amplitude case
        if incAmp == 1
            t0 = tpulse(end);
        else
            t0 = 0;
        end
        
        %calculate amplitude
        f_Abs = @ (t,t0,w1max,mu,bw) w1max./cosh( (bw*pi()/mu).*(t-t0));
        w1(idx,1:samples) = f_Abs(tpulse,t0,1,mu,bw);
        
        %window amplitude
        f_window = @(t,t0) 0.42-0.5*cos(pi*(t)./(t0))+0.08*cos(2*pi*(t)./(t0));
        [~ ,wIdx] = min(abs(tpulse-twindow));
        bm_window = f_window(tpulse(1:wIdx),tpulse(wIdx));
        if incAmp
            w1(idx,1:wIdx) = w1(idx,1:wIdx).*bm_window;
        else
            w1(idx,end-wIdx+1:end) = w1(idx,end-wIdx+1:end).*bm_window(end:-1:1);
        end
        
        %get frequency case
        if incFreq
            FreqFactor = 1;
        else
            FreqFactor = -1;
        end
        
        %calculate frequency
        f_Pha = @ (t,t0,bw,FreqFactor) -FreqFactor*bw*pi*(exp(-t./t0*ef));
        if incAmp == 1
            dfreq(idx,1:samples) = f_Pha(tpulse,tpulse(end),bw,FreqFactor);
        else
            dfreq(idx,1:samples) = f_Pha(tpulse(end:-1:1),tpulse(end),bw,-FreqFactor);
        end
        
        %make frequency modulation start with dw = 0
        [~,mIdx] = min(abs(dfreq(idx,:)));
        dfreq(idx,:) = dfreq(idx,:)-dfreq(idx,mIdx);
        
        %calculate phase -> integrrate over frequency
        dphase(idx,1) = dfreq(idx,1) * tp/samples;
        for tt = 2:samples
            dphase(idx,tt) = dphase(idx,tt-1) + (dfreq(idx,tt) * tp/samples);
        end
        
        % get phase shift to ensure phase ends with 0 for itip down pulses
        phaseShift = 0;
        if incAmp
            phaseShift = dphase(idx,tt);
        else
            phaseShift = dphase(idx,1);
        end
        
        %wrap phase in  [0 2*pi]
        for tt = 1:samples
            dphase(idx,tt) = fmod(dphase(idx,tt)-phaseShift,2*pi);
        end
        
        % shift negative phase to positive
        if ~incFreq
            dphase(idx,:) = dphase(idx,:)+2*pi;
        end
        
    end
end

%% create pulseq objects
% calculate fa
%dPhase_i = wrapToPi(dphase);
adia_SL = cell(4,2);
%dphase = wrapToPi(dphase);
name_idx = {'pre_pos'; 'pre_neg'; 'post_neg'; 'post_pos'};
for ii = 1:4
  %  fa_sl = trapz(w1(1,:))/samples*B1*gyroRatio_rad*tp;
    signal = w1(ii,:).*exp(1i*(dphase(ii,:)));
    %signal = signal*sum(signal.*lims.rfRasterTime);
    adia_SL{ii,1} = makeArbitraryRfWithPhaseArray(signal,B1*gyroRatio_rad, 'system', lims);
    adia_SL{ii,2} = name_idx{ii};
end




