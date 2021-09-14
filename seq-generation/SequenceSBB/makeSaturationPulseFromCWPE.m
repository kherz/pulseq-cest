function sat_pulse = makeSaturationPulseFromCWPE(shape, b1_cwpe, tp,td,lims)
% Generate a sat pulse based on the specified B1 continous wave power
% equivalent
%
% input:
% shape: 'Gauss', 'Sinc', 'block'
% b1_amp: desired amplitude for specified type
% tp: pulse duration
% td: interpulse delay
% lims: scanner limits
%
% output: 
% pulseq sat pulse type
%
% kai.herz@tuebingen.mpg.de

% output init
sat_pulse = [];

if nargin < 5
    error('Needs shape, b1, tp, td and lims as input');
end

gamma_hz = lims.gamma*1e-6;
dummy_b1 = 1;
dummy_fa = tp*dummy_b1*gamma_hz*2*pi;

% make dummy fulse with b1 = 1
if strcmpi(shape, 'gauss')
    sat_pulse_dummy = mr.makeGaussPulse(dummy_fa, 'Duration', tp,'system',lims,'timeBwProduct', 0.2,'apodization', 0.5);
elseif strcmpi(shape, 'sinc')
    sat_pulse_dummy = mr.makeSincPulse(dummy_fa, 'Duration', tp, 'system', lims,'timeBwProduct', 2,'apodization', 0.15);
elseif strcmpi(shape, 'block')
    sat_pulse_dummy = mr.makeBlockPulse(dummy_fa, 'Duration', tp, 'system', lims);
else
    error('invalid shape')
end

%find scaling b1
real_b1 = sqrt(b1_cwpe^2 * (tp+td) ./ trapz(sat_pulse_dummy.t,(sat_pulse_dummy.signal/gamma_hz).^2));
real_fa = tp*real_b1*gamma_hz*2*pi;

% create final pulse
if strcmpi(shape, 'gauss')
    sat_pulse = mr.makeGaussPulse(real_fa, 'Duration', tp,'system',lims,'timeBwProduct', 0.2,'apodization', 0.5);
elseif strcmpi(shape, 'sinc')
    sat_pulse = mr.makeSincPulse(real_fa, 'Duration', tp, 'system', lims,'timeBwProduct', 2,'apodization', 0.15);
elseif strcmpi(shape, 'block')
    sat_pulse = mr.makeBlockPulse(real_fa, 'Duration', tp, 'system', lims);
end






