%% generate hyperbolic secant half passage pulses
function hs_pulse = makeHSHalfPassagePulse(B1,lims)

hs_pule = [];
if nargin < 2 
    error('Need b1 and lims as input');
end

%% pulse definition
tp_us = 8000;
tp = tp_us*1e-6;
bw = 1200;
mu = 6;
samples = tp_us;
tpulse = (1:samples)./samples*tp;
gyroRatio_hz  = 42.5764;                  % for H [Hz/uT]
gyroRatio_rad = gyroRatio_hz*2*pi;        % [rad/uT]


%%
%get amplitude case
t0 = tpulse(end);

%calculate amplitude
f_Abs = @ (t,t0,w1max,mu,bw) w1max./cosh( (bw*pi()/mu).*(t-t0));
w1 = f_Abs(tpulse,t0,1,mu,bw);

beta = bw * pi / mu;
f_Pha = @ (t,t0,bw) (bw * pi * tanh(beta *(t-t0)));
%calculate frequency
%f_Pha = @ (t,t0,bw,FreqFactor) -FreqFactor*bw*pi*(exp(-t./t0*ef));
dfreq = f_Pha(tpulse,tpulse(end),bw);


%make frequency modulation start with dw = 0
dfreq = dfreq-dfreq(end);

%calculate phase -> integrrate over frequency
dphase = dfreq * tp/samples;
for tt = 2:samples
    dphase(tt) = dphase(tt-1) + (dfreq(tt) * tp/samples);
end

% get phase shift to ensure phase ends with 0 for itip down pulses
phaseShift = dphase(tt);

%wrap phase in  [0 2*pi]
for tt = 1:samples
    dphase(tt) = fmod(dphase(tt)-phaseShift,2*pi);
end

% shift negative phase to positive
dphase = dphase+2*pi;
signal = w1.*exp(1i*(dphase));
hs_pulse = makeArbitraryRfWithPhaseArray(signal,B1*gyroRatio_rad, 'system', lims);
 
end





