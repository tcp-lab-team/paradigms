function displayWignerVille(T,F,D,opts,dataOpts,funcName)
% displayWignerVille Plotting function for wvd, xwvd
%   For internal use only.

%   Copyright 2018-2019 The MathWorks, Inc.

isWVD = (dataOpts.Type == "wvd");
if isWVD
    if strcmpi(funcName,'wvd')
        plotOpts.title = getString(message('shared_signalwavelet:wvd:wvd:WVDTitle'));    
    elseif strcmp(funcName,'xwvd')
        plotOpts.title = getString(message('shared_signalwavelet:wvd:wvd:XWVDTitle')); 
    end
else
    if strcmpi(funcName,'wvd')
        plotOpts.title = getString(message('shared_signalwavelet:wvd:wvd:SPWVDTitle'));
    elseif strcmpi(funcName,'xwvd')
        plotOpts.title = getString(message('shared_signalwavelet:wvd:wvd:XSPWVDTitle'));
    end
end
plotOpts.isFsnormalized  = opts.IsNormalizedFreq;
plotOpts.threshold       = opts.MinThreshold;
plotOpts.cblbl           = getString(message('shared_signalwavelet:wvd:wvd:Amplitude')); 
plotOpts.cursorclbl      = getString(message('shared_signalwavelet:wvd:wvd:Amplitude')); 
plotOpts.imageOnlyFlag   = true;
signalwavelet.internal.convenienceplot.plotTFR(T,F,D,plotOpts);
end

% LocalWords:  wvd xwvd signalwavelet SPWVD XSPWVD
