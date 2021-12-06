function lims = Get_scanner_limits(model)
deprecationWarning(mfilename, 'getScannerLimits');
if nargin < 1
lims = getScannerLimits();
else
lims = getScannerLimits(model);
end

