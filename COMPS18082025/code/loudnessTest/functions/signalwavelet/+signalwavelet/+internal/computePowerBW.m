function [bw, flo, fhi, pwr, totpwr] = computePowerBW(Pxx, F, Frange, R, status)
%   This function is for internal use only. It may change or be removed in 
%   a future release.

% Pxx is the periodogram
% F is the frequency vector
% Frange is the frequency range, example: [0 Nyquist]
% R is the db-down point to be measured, example: R = -10*log10(2);

%   Copyright 2018-2019 The MathWorks, Inc.
%#codegen

if isempty(Frange)
  [flo, fhi, pwr, totpwr] = computeFreqBordersFromMaxLevel(Pxx, F, R, status);
else
  [flo, fhi, pwr, totpwr] = computeFreqBordersFromRange(Pxx, F, R, Frange, status);
end

% return the occupied bandwidth
bw = fhi - flo;

end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function [fLo, fHi, pwr, totpwr] = computeFreqBordersFromMaxLevel(Pxx, F, R, status)

% return the frequency widths of each frequency bin
dF = signalwavelet.internal.specfreqwidth(F);

% integrate the PSD to get the power spectrum
P = bsxfun(@times,Pxx,dF);

% correct density if a one-sided spectrum 
if F(1)==0
  Pxx(1,:) = 2*Pxx(1,:);
end

% correct Nyquist bin
if status.hasNyquist && strcmp(status.inputType,'time')
  Pxx(end,:) = 2*Pxx(end,:);
end

% get the reference level for the PSD
[refPSD, iCenter] = max(Pxx,[],1);

% drop by the rolloff factor
refPSD = refPSD*10^(R/10);

nChan = size(Pxx,2);
% do not initialize in codegen
fLo = coder.nullcopy(zeros(1,nChan,'like',Pxx(1)+F(1)));
fHi = coder.nullcopy(fLo);
pwr = coder.nullcopy(fLo);

% cumulative rectangular integration
cumPwr = [zeros(1,nChan,'like',P); cumsum(P,1)];
totpwr = cumPwr(end,:);

% place borders halfway between each estimate
cumF = [F(1,1); (F(1:end-1,1)+F(2:end,1))/2; F(end,1)];

% loop over each channel
for iChan = 1:nChan
  iC = iCenter(iChan);
  iL = find(Pxx(1:iC,iChan)<=refPSD(iChan),1,'last');
  iR = find(Pxx(iC:end,iChan)<=refPSD(iChan),1,'first')+iC-1;
  [fLo(iChan), fHi(iChan), pwr(iChan)] = ...
      getBW(iL,iR,iC,iC,Pxx(:,iChan),F,cumPwr(:,iChan),cumF,refPSD(iChan));
end

end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function [fLo, fHi, pwr, totpwr] = computeFreqBordersFromRange(Pxx, F, R, Frange, status)

% return the frequency widths of each frequency bin
dF = signalwavelet.internal.specfreqwidth(F);

% multiply the PSD by the width to get the power within each bin
P = bsxfun(@times,Pxx,dF);

% find all elements within the specified range
idx = find(Frange(1)<=F & F<=Frange(2));

% compute the total power within the range
totPwr = sum(P(idx,:),1);

% get the reference level for the PSD
refPSD = totPwr ./ sum(dF(idx),1);

% drop by the rolloff factor
refPSD = refPSD*10^(R/10);

% correct dc if a one-sided spectrum 
if F(1)==0
  Pxx(1,:) = 2*Pxx(1,:);
end

% correct Nyquist bin
if status.hasNyquist && strcmp(status.inputType,'time')
  Pxx(end,:) = 2*Pxx(end,:);
end

% search for the frequency in the center of the channel
Fcenter = sum(Frange,'all')/2;
iLeft = find(F<Fcenter,1,'last');
iRight = find(F>Fcenter,1,'first');

nChan = size(Pxx,2);
% do not initialize in codegen
fLo = coder.nullcopy(zeros(1,nChan,'like',Pxx(1)+F(1)));
fHi = coder.nullcopy(fLo);
pwr = coder.nullcopy(fLo);

% Cumulative rectangular integration
cumSxx = [zeros(1,nChan,'like',P); cumsum(P,1)];
totpwr = cumSxx(end,:);

% place borders halfway between each estimate
cumF = [F(1,1); (F(1:end-1,1)+F(2:end,1))/2; F(end,1)];

iL = [];
iR = [];
% loop over each channel
for iChan = 1:nChan
  if ~isempty(iRight)
    iL = find(Pxx(1:iRight(1),iChan)<=refPSD(iChan),1,'last');
  end
  if ~isempty(iLeft)
    iR = find(Pxx(iLeft(1):end,iChan)<=refPSD(iChan),1,'first')+iLeft(1)-1;
  end
  [fLo(iChan), fHi(iChan), pwr(iChan)] = ...
      getBW(iL,iR,iLeft,iRight,Pxx(:,iChan),F,cumSxx(:,iChan),cumF,refPSD(iChan));
end

end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function [fLo, fHi, pwr] = getBW(iL, iR, iLeft, iRight, Pxx, F, cumPwr, cumF, refPSD)

% codegen requires all conditional branches to have the same datatype
if isempty(iL)
  fLo = cast(F(1),'like',F(1)+Pxx(1));
elseif iL(1)==iRight(1)
  fLo = cast(nan,'like',F(1)+Pxx(1));
else
  % use log interpolation to get power bandwidth
  fLo = signalwavelet.internal.linterp(F(iL(1)),F(iL(1)+1), ...
            log10(max(Pxx(iL(1)),realmin)),log10(max(Pxx(iL(1)+1),realmin)),log10(refPSD));
end

if isempty(iR)
  fHi = cast(F(end),'like',F(1)+Pxx(1));
elseif iR(1)==iLeft(1)
  fHi = cast(nan,'like',F(1)+Pxx(1));
else
  % use log interpolation to get power bandwidth
  fHi = signalwavelet.internal.linterp(F(iR(1)),F(iR(1)-1), ...
            log10(max(Pxx(iR(1)),realmin)),log10(max(Pxx(iR(1)-1),realmin)),log10(refPSD));
end

% find the integrated power for the low and high frequency range
pLo = interpPower(cumPwr,cumF,fLo);
pHi = interpPower(cumPwr,cumF,fHi);
pwr = pHi-pLo;

end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function p = interpPower(cumPwr, cumF, f)

idx = find(f<=cumF,1,'first');
if ~isempty(idx)
  % scalar inference for codegen
  idx1 = idx(1);
  if idx1==1
    p = signalwavelet.internal.linterp(cumPwr(1,:),cumPwr(2,:),cumF(1),cumF(2),f);
  else
    p = signalwavelet.internal.linterp(cumPwr(idx1,:),cumPwr(idx1-1,:), ...
                                cumF(idx1),cumF(idx1-1),f);
  end
else
  % codegen requires both conditional branches to have the same data type
  % for 'p'
  p = nan(1,size(cumPwr,2),'like',cumPwr(1)+cumF(1)+f(1));
end

end