function [B1cwpe,B1cwae,B1cwae_pure,alpha]=  calc_power_equivalents(satPulse,t_p,t_d,plot_flag,gamma_hz)
deprecationWarning(mfilename, 'calculatePowerEquivalents');
if nargin<5
gamma_hz = 42.5764;
if nargin<4
    plot_flag=0;
end
end
[B1cwpe,B1cwae,B1cwae_pure,alpha]=  calculatePowerEquivalents(satPulse,t_p,t_d,plot_flag,gamma_hz);