% this function prepares long pulse objects for a better perormance of the
% run length encoding (rle) algorithm used to save the shapes in the pulseq files
% The pulse signal is first resampled to a chosen amount of samples and
% then resampled to the original raster using a nearest neigbour
% interpolation. this results in a series of samples with the same
% amplitude, beneficial for rle
% input: pulse:          original pulseq pulse event
%        nSamples:       number of samples for resampling
% output resampledPulse: pulse event with same raster time as pulse
function resampledPulse = resamplePulseForRLE(pulse, nSamples)
% detect zero padding
idx = numel(pulse.signal);
while pulse.signal(idx) < 1e-9
idx = idx-1;
end
% temp containers for new amplidute and time
tmpTime = linspace(pulse.t(1),pulse.t(idx), nSamples);
% resample 
tmpPulse = interp1(pulse.t(1:idx), pulse.signal(1:idx), tmpTime);
resampledPulse = pulse;
% return to original raster
resampledPulse.signal(1:idx) = interp1(tmpTime, tmpPulse, pulse.t(1:idx), 'nearest', 'extrap');
