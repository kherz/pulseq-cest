function [gx, gy, gz] = Create_spoiler_gradients(lims, duration, riseTime)
% This function creates spoiler objects in x y and z direction based on the
% maximal spoiler amplitude
% A specified rise-/falltime can be set, otherwise minimum times are used
% Duration is defined as FlatTime + risteTime
%
% kai.herz@tuebingen.mpg.de
if nargin < 2
    error('Scanner limits and duration are need as input!');
end

spoilAmplitude = 0.8 .* lims.maxGrad; % [Hz/m]
minRiseTime = abs(spoilAmplitude)/lims.maxSlew;
minRiseTime = ceil(minRiseTime/lims.gradRasterTime)*lims.gradRasterTime;

if nargin == 3
    if riseTime < minRiseTime
       warning(['Specified riseTime is shorter than minimum! ' num2str(minRiseTime) ' s is used instead!']);
       riseTime = minRiseTime; 
    end
else
    riseTime = minRiseTime;
end
    
spoilDuration = duration+riseTime; % [s]

% create pulseq gradient object 
gx=mr.makeTrapezoid('x','Amplitude',spoilAmplitude,'Duration',spoilDuration,'riseTime', riseTime, 'system',lims);
gy=mr.makeTrapezoid('y','Amplitude',spoilAmplitude,'Duration',spoilDuration,'riseTime', riseTime, 'system',lims);
gz=mr.makeTrapezoid('z','Amplitude',spoilAmplitude,'Duration',spoilDuration,'riseTime', riseTime, 'system',lims);

end