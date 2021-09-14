function [Z,ppm_sort]=Plot_pulseq_cest_Simulation(M_z,offsets_ppm,m0_offset)
deprecationWarning(mfilename, 'plotSimulationResults');
if nargin < 2
    [Z,ppm_sort]=plotSimulationResults(M_z,offsets_ppm);
else
    [Z,ppm_sort]=plotSimulationResults(M_z,offsets_ppm,m0_offset);
end