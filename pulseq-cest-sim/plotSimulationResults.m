% Plot Z-spectrum and MTRasym
%
% Input:  M_z        : Z magnetization
%         offsets_ppm: frequency offsets  (ppm)
%         m0_offset  : frequency offset of the M0 scan(s) (optional)
% If no m0_offset is given, M_z is assumed as alsready normalized Z value
% for plotting
%
% Output: Z       : Z-spectrum
%         ppm_sort: offsets_ppm sorted (ascending frequency)

function [Z,ppm_sort]=plotSimulationResults(M_z,offsets_ppm,m0_offset)

% init Z with M0, ovrwrite if m0_offset is found for normalization
Z = M_z;

% m0-offset given for normalization ?
if nargin > 2
% we search for all appearances of the m0 offset and normalize by it, or by
% the mean value if all m0 offsets if multiple occur
    M0_idx = [];
    if any(offsets_ppm == m0_offset)
        M0_idx = [M0_idx find(offsets_ppm == m0_offset)];
        M0 = mean(M_z(M0_idx));
        M_z(M0_idx) = [];
        offsets_ppm(M0_idx) = [];
        Z = M_z./M0; % calculate the Z-value
    else
        warning('M0 offset not found in offsets_ppm');
    end
end

%% plot Z-spectrum and MTRasym
% sort normalized values
[ppm_sort, idx] = sort(offsets_ppm);
Z = Z(idx);
% MTRasym -> for this example we have the same distribution of offsets on
% both sides of the water, so we can calculate the asym easily.
% For different .seq-files, different steps may be neccessary
MTRasym=Z(end:-1:1)-Z;
MTRasym(1:ceil(end/2)) = NaN;

% finally, plot the Z-spectrum and the MTRasym curve
subplot(2,1,1), hold on; grid on;
plot(ppm_sort, Z,'Displayname','Z-spectrum'); set(gca,'xdir','reverse');
xlabel('\Delta\omega [ppm]'); legend show;
subplot(2,1,2), hold on; grid on;
plot(ppm_sort,MTRasym,'Displayname','MTR_{asym}'); set(gca,'xdir','reverse');
xlabel('\Delta\omega [ppm]'); legend show;
axis([ppm_sort(1) ppm_sort(end) -(2*max(abs(MTRasym))) (2*max(abs(MTRasym)))]);
