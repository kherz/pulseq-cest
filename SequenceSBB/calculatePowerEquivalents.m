function [B1cwpe,B1cwae,B1cwae_pure,alpha]=  calculatePowerEquivalents(satPulse,t_p,t_d,plot_flag,gamma_hz)
if nargin<5
gamma_hz = 42.5764;
if nargin<4
    plot_flag=0;
end
end
[B1]=satPulse.signal/gamma_hz; % rad/s
tpulse=satPulse.t;
DC=t_p/(t_p+t_d);

alpha=trapz(tpulse,B1*gamma_hz*360);                % flip angle of saturation pulse in degree
alpha_rad=alpha*pi/180;                             % flip angle of saturation pulse in rad

B1cwpe = sqrt( trapz(tpulse,B1.^2)./((t_p/DC)) );   % power equivalent over pulse train
B1cwae = alpha_rad/(gamma_hz*2*pi*t_p)*DC;          % amplitude equivalent over pulse train
B1cwae_pure= alpha_rad/(gamma_hz*2*pi*t_p); % amplitude equivalent over single pulse (original input definition)

if plot_flag
figure(),plot(linspace(0,tpulse(end),numel(B1)),B1); hold on; 
ylabel('B1 amplitude in uT');
xlabel(sprintf('tp in s\ncw-power-equivalent =%.3f uT\ncw-ampl-equivalent = %.3f uT\ncw-ampl-equivalent over single pulse =%.3f uT\n flip angle = %.2f degree',...
    B1cwpe,B1cwae,B1cwae_pure,alpha));
end