function lims = getScannerLimits(model)
% This function retuens the scanner limits for specific models
% or if no model specified a standard parameter set.
% Additional modls can be appended
% 
if nargin < 1
    lims = mr.opts('MaxGrad',40,'GradUnit','mT/m',...
        'MaxSlew',130,'SlewUnit','T/m/s', ...
        'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6,'gamma',42.5764e6); 
else
    switch upper(model)
        case {'SIM'} % no rf ringdown nor deadtime
            lims = mr.opts('MaxGrad',80,'GradUnit','mT/m',...
                'MaxSlew',200,'SlewUnit','T/m/s', ...
                'rfRingdownTime', 0, 'rfDeadTime', 0, 'rfRasterTime',1e-6,'gamma',42.5764e6);
        case {'SIEMENS_PRISMA'}
            lims = mr.opts('MaxGrad',80,'GradUnit','mT/m',...
                'MaxSlew',200,'SlewUnit','T/m/s', ...
                'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6,'gamma',42.5764e6); 
        otherwise
            warning('Scanner model unknown, retrning standard parameters!');
            lims = mr.opts('MaxGrad',40,'GradUnit','mT/m',...
                'MaxSlew',130,'SlewUnit','T/m/s', ...
                'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6,'gamma',42.5764e6); 
    end
end


