function [gx, gy, gz] = Create_spoiler_gradients(lims, duration, riseTime)
deprecationWarning(mfilename, 'makeSpoilerGradients');
if nargin < 3
[gx, gy, gz] = makeSpoilerGradients(lims, duration);
else
    [gx, gy, gz] = makeSpoilerGradients(lims, duration, riseTime);
end