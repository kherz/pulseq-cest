<<<<<<< HEAD:seq-generation/SequenceSBB/makeArbitraryRfWithPhaseArray.m
function [rf, delay] = makeArbitraryRfWithPhaseArray(signal,flip,varargin)
=======
function [rf, gz, delay] = makeArbitraryRf(signal,flip,varargin)
>>>>>>> f1aff29 (changed pulseq version to 1.4):pulseq-cest-sim/src/3rdParty/pulseq-master/matlab/+mr/makeArbitraryRf.m
%makeArbitraryRf Create an RF pulse with the given pulse shape.
%   rf=makeArbitraryRf(singal, flip) Create RF pulse with complex signal 
%   and given flip angle (in radians)
%
%   rf=makeArbitraryRf(..., 'FreqOffset', f,'PhaseOffset',p)
%   Create block pulse with frequency offset and phase offset.
%
%   [rf, gz]=makeArbitraryRf(..., 'Bandwidth', bw, 'SliceThickness', st) 
%   Create RF pulse and corresponding slice select gradient. The bandwidth
%   of the pulse must be given for the specified shape.
%
%   See also  Sequence.makeSincPulse, Sequence.addBlock

validPulseUses = mr.getSupportedRfUse();

persistent parser
if isempty(parser)
    parser = inputParser;
    parser.FunctionName = 'makeArbitraryRf';
    
    % RF params
    addRequired(parser, 'signal', @isnumeric);
    addRequired(parser, 'flipAngle', @isnumeric);
    addOptional(parser, 'system', mr.opts(), @isstruct);
    addParamValue(parser, 'freqOffset', 0, @isnumeric);
    addParamValue(parser, 'phaseOffset', 0, @isnumeric);
    addParamValue(parser, 'timeBwProduct', 0, @isnumeric);
    addParamValue(parser, 'bandwidth', 0, @isnumeric);
    % Slice params
    addParamValue(parser, 'maxGrad', 0, @isnumeric);
    addParamValue(parser, 'maxSlew', 0, @isnumeric);
    addParamValue(parser, 'sliceThickness', 0, @isnumeric);
    % Delay
    addParamValue(parser, 'delay', 0, @isnumeric);
    addParamValue(parser, 'dwell', mr.opts().rfRasterTime, @isnumeric);
    % whether it is a refocusing pulse (for k-space calculation)
    addOptional(parser, 'use', '', @(x) any(validatestring(x,validPulseUses)));
end
parse(parser, signal, flip,varargin{:});
opt = parser.Results;

<<<<<<< HEAD:seq-generation/SequenceSBB/makeArbitraryRfWithPhaseArray.m
signal = signal*flip/(2*pi);

N=  length(signal);
t = (1:N)*opt.system.rfRasterTime;
=======
signal = signal./abs(sum(signal.*opt.dwell))*flip/(2*pi);

N=  length(signal);
duration = N*opt.dwell;
t = ((1:N)-0.5)*opt.dwell;
>>>>>>> f1aff29 (changed pulseq version to 1.4):pulseq-cest-sim/src/3rdParty/pulseq-master/matlab/+mr/makeArbitraryRf.m

rf.type = 'rf';
rf.signal = signal;
rf.t = t;
<<<<<<< HEAD:seq-generation/SequenceSBB/makeArbitraryRfWithPhaseArray.m
rf.shape_dur=t(end);
=======
rf.shape_dur=duration;
>>>>>>> f1aff29 (changed pulseq version to 1.4):pulseq-cest-sim/src/3rdParty/pulseq-master/matlab/+mr/makeArbitraryRf.m
rf.freqOffset = opt.freqOffset;
rf.phaseOffset = opt.phaseOffset;
rf.deadTime = opt.system.rfDeadTime;
rf.ringdownTime = opt.system.rfRingdownTime;
rf.delay = opt.delay;
if ~isempty(opt.use)
    rf.use=opt.use;
end
if rf.deadTime > rf.delay
    rf.delay = rf.deadTime;
end

<<<<<<< HEAD:seq-generation/SequenceSBB/makeArbitraryRfWithPhaseArray.m
if rf.ringdownTime > 0
    tFill = (1:round(rf.ringdownTime/1e-6))*1e-6;  % Round to microsecond
    rf.t = [rf.t rf.t(end)+tFill];
    rf.signal = [rf.signal, zeros(size(tFill))];
=======
if nargout>1
    assert(opt.sliceThickness > 0, 'SliceThickness must be provided');
    assert(opt.bandwidth > 0, 'Bandwidth of pulse must be provided');
    warning('FIXME: there are some potential issues with the bandwidth and related parameters, double check (e-mail communication)');
    if opt.maxGrad > 0
        opt.system.maxGrad = opt.maxGrad;
    end
    if opt.maxSlew > 0
        opt.system.maxSlew = opt.maxSlew;
    end
    
    BW = opt.bandwidth;
    if opt.timeBwProduct > 0
        BW = opt.timeBwProduct/duration;
    end

    amplitude = BW/opt.sliceThickness;
    area = amplitude*opt.duration;
    gz = mr.makeTrapezoid('z', opt.system, 'flatTime', opt.duration, ...
                          'flatArea', area);
    
    if rf.delay > gz.riseTime
        gz.delay = ceil((rf.delay - gz.riseTime)/opt.system.gradRasterTime)*opt.system.gradRasterTime; % round-up to gradient raster
    end
    if rf.delay < (gz.riseTime+gz.delay)
        rf.delay = gz.riseTime+gz.delay; % these are on the grad raster already which is coarser 
    end
end

% v1.4 finally eliminates RF zerofilling
% if rf.ringdownTime > 0
%     tFill = (1:round(rf.ringdownTime/1e-6))*1e-6;  % Round to microsecond
%     rf.t = [rf.t rf.t(end)+tFill];
%     rf.signal = [rf.signal, zeros(size(tFill))];
% end
if rf.ringdownTime > 0 && nargout > 2
    delay=mr.makeDelay(mr.calcDuration(rf)+rf.ringdownTime);
>>>>>>> f1aff29 (changed pulseq version to 1.4):pulseq-cest-sim/src/3rdParty/pulseq-master/matlab/+mr/makeArbitraryRf.m
end

if rf.ringdownTime > 0 && nargout > 1
    delay=mr.makeDelay(mr.calcDuration(rf)+rf.ringdownTime);
end
