function lims = Get_scanner_limits(model)
% This function retuens the scanner limits for specific models
% or if no model specified a standard parameter set.
% Additional modls can be appended
% 
if nargin < 1
    lims = mr.opts('MaxGrad',40,'GradUnit','mT/m',...
        'MaxSlew',130,'SlewUnit','T/m/s', ...
        'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6);
else
    switch upper(model)
        case {'SIEMENS_PRISMA'}
            lims = mr.opts('MaxGrad',80,'GradUnit','mT/m',...
                'MaxSlew',200,'SlewUnit','T/m/s', ...
                'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6);
        otherwise
            warning('Scanner model unknown, retrning standard parameters!');
            lims = mr.opts('MaxGrad',40,'GradUnit','mT/m',...
                'MaxSlew',130,'SlewUnit','T/m/s', ...
                'rfRingdownTime', 30e-6, 'rfDeadTime', 100e-6, 'rfRasterTime',1e-6);
    end
end


