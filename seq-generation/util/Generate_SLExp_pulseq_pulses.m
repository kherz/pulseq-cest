%% write pulseq rf objects for slexp pulse
function adia_SL = Generate_SLExp_pulseq_pulses(B1,lims)

% if nargin <2
%     lims = 0;
% end
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

end

%% C++ fmod function (same as on VB and VE)
function m = fmod(a, b)
if a == 0
    m = 0;
else
    m = mod(a, b) + (b*(sign(a) - 1)/2);
end
end


function rf = makeArbitraryRfWithPhaseArray(signal,flip,varargin)
%makeArbitraryRf Create an RF pulse with the given pulse shape.
%   rf=makeArbitraryRf(singal, flip) Create RF pulse with complex signal 
%   and given flip angle (in radians)
%
%   rf=makeArbitraryRf(..., 'FreqOffset', f,'PhaseOffset',p)
%   Create block pulse with frequency offset and phase offset.
%
%   [rf, gz]=makeArbitraryRf(..., 'Bandwidth', bw, 'SliceThickness', st) 
%   Create RF pulse and corresponding slice select gradient. The bandwidth
%   of the pulse must be given for the specified shape.
%
%   See also  Sequence.makeSincPulse, Sequence.addBlock

validPulseUses = {'excitation','refocusing','inversion'};

persistent parser
if isempty(parser)
    parser = inputParser;
    parser.FunctionName = 'makeArbitraryRf';
    
    % RF params
    addRequired(parser, 'signal', @isnumeric);
    addRequired(parser, 'flipAngle', @isnumeric);
    addOptional(parser, 'system', mr.opts(), @isstruct);
    addParamValue(parser, 'freqOffset', 0, @isnumeric);
    addParamValue(parser, 'phaseOffset', 0, @isnumeric);
    addParamValue(parser, 'timeBwProduct', 0, @isnumeric);
    addParamValue(parser, 'bandwidth', 0, @isnumeric);
    % Slice params
    addParamValue(parser, 'maxGrad', 0, @isnumeric);
    addParamValue(parser, 'maxSlew', 0, @isnumeric);
    addParamValue(parser, 'sliceThickness', 0, @isnumeric);
    % Delay
    addParamValue(parser, 'delay', 0, @isnumeric);
    % whether it is a refocusing pulse (for k-space calculation)
    addOptional(parser, 'use', '', @(x) any(validatestring(x,validPulseUses)));
end
parse(parser, signal, flip,varargin{:});
opt = parser.Results;

signal = signal*flip/(2*pi);

N=  length(signal);
t = (1:N)*opt.system.rfRasterTime;

rf.type = 'rf';
rf.signal = signal;
rf.t = t;
rf.freqOffset = opt.freqOffset;
rf.phaseOffset = opt.phaseOffset;
rf.deadTime = opt.system.rfDeadTime;
rf.ringdownTime = opt.system.rfRingdownTime;
rf.delay = opt.delay;
if ~isempty(opt.use)
    rf.use=opt.use;
end
if rf.deadTime > rf.delay
    rf.delay = rf.deadTime;
end

if rf.ringdownTime > 0
    tFill = (1:round(rf.ringdownTime/1e-6))*1e-6;  % Round to microsecond
    rf.t = [rf.t rf.t(end)+tFill];
    rf.signal = [rf.signal, zeros(size(tFill))];
end

end





