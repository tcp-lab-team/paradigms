function [wvdMatResult,freqVec] = xwvdImpl(dataOpts,opts)
% XwvdImpl Calculate xvwd.
%   For internal use only.

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

isWvd = (dataOpts.Type == "wvd"); % WVD or SPWVD?

if isa(dataOpts.XData,'single') || isa(dataOpts.YData,'single')
    outType = 'single';
    x = single(dataOpts.XData);
    y = single(dataOpts.YData);
else
    outType = 'double';
    x = double(dataOpts.XData);
    y = double(dataOpts.YData);
end

N2 = length(x); % Signal length after length has increased.
freqVec = linspace(0,1,opts.NumFrequencyPoints)';
nTime = opts.NumTimePoints;

if isWvd % WVD
    nFreq = N2; % Use Nt=Nf for xwvd.
    nVec = 0:nTime-1;
    mVec = 0:nFreq-1;
    % Repmat is used to enable variable size unbounded code generation
    posLagMat = repmat(nVec,nFreq,1) + repmat(mVec',1,nTime) + 1;
    negLagMat = repmat(nVec,nFreq,1) - repmat(mVec',1,nTime) + 1;
    isNoTimeSupport = (posLagMat>N2) | (negLagMat<1);
    posLagMat(isNoTimeSupport) = 1; % Replace nonphysical t values with 1.
    negLagMat(isNoTimeSupport) = 1;
    kMat = x(posLagMat) .* conj(y(negLagMat));
    kMat(isNoTimeSupport) = 0;
else % SPWVD
    nFreq = opts.NumFrequencyPoints;
    funcName = "xwvd";
    [G1,g2] = signalwavelet.internal.wvd.getSpwvdWindowParams(opts,funcName,dataOpts);
    % Add zeros to account for regions of no support.
    halfDoppWinIx = ceil(length(G1)/2);
    G1Append = [G1(1:halfDoppWinIx); zeros(2*nFreq-numel(G1),1,outType);G1(halfDoppWinIx+1:end)];
    halfLagWinIx = ceil(length(g2)/2);
    g2Append = [g2(1:halfLagWinIx); zeros(N2-numel(g2),1,outType);g2(halfLagWinIx+1:end)];
    
    nVec = 0:N2-1;
    mVec = 0:2*nFreq-1;
    posLagMat = repmat(nVec,2*nFreq,1) + repmat(mVec',1,nTime) + 1;
    negLagMat = repmat(nVec,2*nFreq,1) - repmat(mVec',1,nTime) + 1;
    isNoTimeSupport = (posLagMat>N2) | (negLagMat<1);
    posLagMat(isNoTimeSupport) = 1; % Replace nonphysical t values with 1.
    negLagMat(isNoTimeSupport) = 1;
    
    % kMat = g2.' .* x(posLagMat) .* conj(y(negLagMat)); Repmat is used to enable variable size unbounded code generation
    kMat = repmat(g2Append.',size(posLagMat,1),1) .* x(posLagMat) .* conj(y(negLagMat));
    kMat(isNoTimeSupport) = 0;
    % Take FFT n->l to transform to the ambiguity domain.
    afMat = fft(kMat,[],2);
    % afWinMat = G1 .* afMat;Repmat is used to enable variable size unbounded code generation
    afWinMat = repmat(G1Append,1,size(afMat,2)) .* afMat;
    
    % Take IDFT l->n to return to the time-lag domain.
    kMat = ifft(afWinMat,[],2);
end

% Transform to the time-frequency domain with FFT m->k.
wvdMat = fft(kMat);

% Reverse f orientation so that zero frequency is at the bottom of
% wdMat. Return single-sided spectrum.
if isWvd
    wvdMatResult = flipud(wvdMat(N2/2+1:end,:));
else
    wvdMatResult = flipud(wvdMat(nFreq+1:end,:));
end

end

% LocalWords:  xvwd WVD SPWVD Nt xwvd af IDFT wd Vec XM Coloumn NX
