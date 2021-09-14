function saveSaturationPhasePlot(seq_fn)
% this function writes a png file with the seq plot with the same filename as the seq
% file
% foo\bar.seq -> foo\bar.png
if ~exist(seq_fn, 'file')
    error([seq_fn ' does not exist']);
end
% read file
seq = SequenceSBB;
seq.read(seq_fn);

% call the internal plot function of the SequenceSBB
fig_seq = seq.plotSaturationPhase();

set(fig_seq, 'Position', get(0, 'Screensize'));
% get data and save figure
f_data    = getframe(fig_seq);
[fp, fn] = fileparts(seq_fn);
imwrite(f_data.cdata, fullfile(fp, [fn '.png']), 'png');
