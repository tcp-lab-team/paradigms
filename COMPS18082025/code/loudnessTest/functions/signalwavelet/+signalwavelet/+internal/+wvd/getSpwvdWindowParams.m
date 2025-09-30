function [G1,g2,maxLag,nFreqWin,nhFreqWin] = getSpwvdWindowParams(opts,funcName,dataOpts)
% getSpwvdWindowParams Generate SPWVD windows and obtain window params.
% The WVD kernel is G1[l]*g2[m] where l and m are lag and Doppler indices.
%   For internal use only.


%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

% XWVD or WVD
isCrossWVD = (funcName == "xwvd");

if isCrossWVD   % XWVD
    if isa(dataOpts.XData,'single') || isa(dataOpts.YData,'single')
        timeWin = single(opts.TimeWindow);
        freqWin = single(opts.FrequencyWindow);
        
    else
        timeWin = opts.TimeWindow;
        freqWin = opts.FrequencyWindow;
    end
else  % WVD
    if isa(dataOpts.Data,'single')
        timeWin = single(opts.TimeWindow);
        freqWin = single(opts.FrequencyWindow);
        
    else
        timeWin = opts.TimeWindow;
        freqWin = opts.FrequencyWindow;
    end
end

nTimeWin = length(timeWin);
nFreqWin = length(freqWin);

nhFreqWin = floor(nFreqWin/2);
maxLag = floor(nTimeWin/2);

if isCrossWVD % XWVD
    if isa(dataOpts.XData,'single') || isa(dataOpts.YData,'single')
        G1 = single(circshift(freqWin,ceil(length(freqWin)/2)));
        g2 = single(circshift(timeWin,ceil(length(timeWin)/2)));
    else
        G1 = circshift(freqWin,ceil(length(freqWin)/2));
        g2 = circshift(timeWin,ceil(length(timeWin)/2));
    end
    N = length(dataOpts.XData)/2;
else % WVD
    if isa(dataOpts.Data,'single')
        G1 = single(circshift(freqWin,ceil(length(freqWin)/2)));
        g2 = single(circshift(timeWin,ceil(length(timeWin)/2)));
    else
        G1 = circshift(freqWin,ceil(length(freqWin)/2));
        g2 = circshift(timeWin,ceil(length(timeWin)/2));
    end
    N = length(dataOpts.Data)/2;   
end

% Nt must be even. nFreqWin must be odd. +1 to get even lower bound.
coder.internal.errorIf(opts.NumTimePoints < nFreqWin || opts.NumTimePoints > 2*N,...
    'shared_signalwavelet:wvd:wvd:NumTimePointsInvalid',(nFreqWin+1),(2*N));

coder.internal.errorIf(opts.NumFrequencyPoints < ceil((nTimeWin+1)/2) || opts.NumFrequencyPoints > N,...
    'shared_signalwavelet:wvd:wvd:NumFrequencyPointsInvalid',(ceil((nTimeWin+1)/2)),(N));
end

% LocalWords:  SPWVD wvd xwvd Nt signalwavelet Func
