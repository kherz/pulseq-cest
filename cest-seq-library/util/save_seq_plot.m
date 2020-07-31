function save_seq_plot(seq_fn)
% this function plots the seq file from the first to second adc
% (or the entire sequence if it contains less than 2 adc events)
% and writes a png file with the seq plot with the same filename as the seq
% file
% foo\bar.seq -> foo\bar.png

% check for seq file
if ~exist(seq_fn, 'file')
    error([seq_fn ' does not exist']);
end

% read file
seq = mr.Sequence;
seq.read(seq_fn);

% with time unit ms and RF unit µT
t=0;
adc_counter = 0;
tADC=zeros(2,1);
for iB=1:length(seq.blockEvents)
    block = seq.getBlock(iB);
    t=t+mr.calcDuration(block);
    if ~isempty(block.adc)
        adc_counter = adc_counter+1;
        tADC(adc_counter)=t; % save time of ADC events here
    end
    if adc_counter == 2
        break;
    end
end



if adc_counter < 2 % plot all if only 1 adc
    fig_seq = seq.plot('timeDisp','ms','rfDisp','uT','gammaHz',42.5764);
else % plot from first to second adc
    fig_seq = seq.plot('TimeRange',[tADC(1)-0.02 tADC(2)],'timeDisp','ms','rfDisp','uT','gammaHz',42.5764);
end
set(fig_seq, 'Position', get(0, 'Screensize'));
% get data and save figure
f_data    = getframe(fig_seq);
[fp, fn] = fileparts(seq_fn);
imwrite(f_data.cdata, fullfile(fp, [fn '.png']), 'png');
