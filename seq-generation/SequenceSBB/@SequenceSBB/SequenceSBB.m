classdef SequenceSBB < mr.Sequence
    % A subclass of the Pulseq mr.Sequence class which implements all the
    % Pulseq-CEST features
    % Kai Herz, 2021
    
    methods
        
        % contructor
        % passes arguments to parent constructr
        function obj = SequenceSBB(varargin)
            if nargin<1
                sys=mr.opts();
            else
                sys=varargin{1};
            end
            obj = obj@mr.Sequence(sys);
        end
        
        % adds the pseudo ADC block at which the readout is called / the
        % magnetization vector is returned
        function addPseudoADCBlock(obj)
            pseudoADC = mr.makeAdc(1, 'Duration', 1e-3);
            addBlock(obj, pseudoADC);
        end
        
        % adds spoiler gradients for all three axis
        % these are the standard spoiler we use, if all axes have a
        % gradient event the transverse magnetization in the simulation is
        % nulled
        % Input: system limits
        function addSpoilerGradients(obj, lims)
            if nargin < 2
                lims = obj.sys;
            end
            % spoilers
            spoilRiseTime = 1e-3;
            spoilDuration = 4500e-6+ spoilRiseTime; % [s]
            % create pulseq gradient object
            [gxSpoil, gySpoil, gzSpoil] = makeSpoilerGradients(lims, spoilDuration, spoilRiseTime);
            addBlock(obj, gxSpoil, gySpoil, gzSpoil);
        end
        
        % plots the saturation phase from the first to the second adc
        % event.       
        function p = plotSaturationPhase(obj)
            t=0; tADC=[];
            for iB=1:length(obj.blockEvents)
                block = obj.getBlock(iB);
                t = t+mr.calcDuration(block);
                if ~isempty(block.adc)
                    tADC(end+1) = t; % save time of ADC events here
                    if numel(tADC) == 2
                        break;
                    end
                end
            end
            
            % plot only from first to second ADC,
            p = obj.plot('TimeRange',[tADC(1)-0.02 tADC(2)],'timeDisp','s');
            % get the rf axis
            for rf_mag_id = 1:numel(p.Children)
                if strcmp('RF mag (Hz)', p.Children(rf_mag_id).YLabel.String)
                    break;
                end
            end
            rf_ax = p.Children(rf_mag_id);
            % how many ticks do we need?
            max_tick = ceil(str2num(rf_ax.YTickLabel{end})/(obj.sys.gamma*1e-6));
            ticks = [];
            if max_tick < 3
                tick = 0:0.5:max_tick;
            else
                tick = 0:max_tick;
            end
            % scale to get uT.
            rf_ax.YTick = tick*(obj.sys.gamma*1e-6);
            rf_ax.YLim = [0 rf_ax.YTick(end)];
            for cl = 1:numel(rf_ax.YTick)
                rf_ax.YTickLabel{cl} = tick(cl);
            end
            rf_ax.YLabel.String = 'RF mag (uT)';
        end
        
        % write the seq file. The parent class write function is used, but
        % we add some additional information for the Pulseq-CEST files
        % input: filename: seq filename (string)
        % input: author: seq file author (string)
        function write(obj, filename, author)
            
            if nargin < 3
                author = 'unknown';
            end
            if ~ischar(author) && ~isstring(author) 
                author = 'unknown';
            end
            
            % write seq file with parent function
            write@mr.Sequence(obj,filename);
            % insert pulseq-cest info
            [fp, fn, fe] = fileparts(filename);
            filenameTmp = fullfile(fp,[fn 'tmp' fe]);
            fid = fopen(filename, 'r');
            fidTmp = fopen(filenameTmp, 'w');
            id = 0;
            while ~feof(fid)
                fprintf(fidTmp, [fgetl(fid) '\n']);
                id = id +1;
                if id == 3
                    fprintf(fidTmp, '# Created for Pulseq-CEST\n');
                    fprintf(fidTmp, '# https://pulseq-cest.github.io/\n');
                    fprintf(fidTmp, ['# Created by: ' author '\n']);
                    fprintf(fidTmp, ['# Created at: ' datestr(now) '\n\n']);
                end
            end
            fclose(fid);
            fclose(fidTmp);
            movefile(filenameTmp,filename, 'f');
        end
    end
end