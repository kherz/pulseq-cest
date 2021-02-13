
function Plot_pulseq_cest_Simulation(M_z,offsets_ppm,m0_offset)
%% normalization
% The normalization depends on the M0 offset an their positions in the .seq-file
% In this example, the M0 offset is set as a definition in the APTw_3T_example.seq
% It can be accessed with the correct key and is used as the normalization
% value

% we search for all appearances of the m0 offset and normalize by it, or by
% the mean value if all m0 offsets if multiple occur
M0_idx = [];
if any(offsets_ppm == m0_offset)
    M0_idx = [M0_idx find(offsets_ppm == m0_offset)];
    M0 = mean(M_z(M0_idx));
    M_z(M0_idx) = [];
    offsets_ppm(M0_idx) = [];
    Z = M_z./M0; % calculate the Z-value
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
hold on;
yyaxis left;
plot(ppm_sort, Z,'Displayname','Z-spectrum'); set(gca,'xdir','reverse');
xlabel('\Delta\omega [ppm]'); legend show;
yyaxis right;
plot(ppm_sort,MTRasym,'Displayname','MTR_{asym}');
axis([ppm_sort(1) ppm_sort(end) -(2*max(abs(MTRasym))) (2*max(abs(MTRasym)))])