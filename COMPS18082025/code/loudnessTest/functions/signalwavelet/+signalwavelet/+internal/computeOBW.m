function [bw, flo, fhi, pwr] = computeOBW(Pxx, F, Frange, P)
%   This function is for internal use only. It may change or be removed in 
%   a future release.

%   Copyright 2018-2019 The MathWorks, Inc.
%#codegen

% compute the power from the PSD
width = signalwavelet.internal.specfreqwidth(F);
Pwr = bsxfun(@times,width,Pxx);

% cumulative rectangular integration
cumPwr = [zeros(1,size(Pwr,2),'like',Pwr); cumsum(Pwr,1)];

% place borders halfway between each estimate
cumF = [F(1,1); (F(1:end-1,1)+F(2:end,1))/2; F(end,1)];

% find the integrated power for the low and high frequency range
Plo = interpPower(cumPwr,cumF,Frange(1));
Phi = interpPower(cumPwr,cumF,Frange(2));

% return the power between the frequency range
totPwr = Phi-Plo;

% return the frequency which intercepts the borders of the occupied band
flo = interpFreq(cumPwr,cumF,Plo+(100-P)/200*totPwr);
fhi = interpFreq(cumPwr,cumF,Plo+(100+P)/200*totPwr);

% return the occupied bandwidth and the occupied bandpower
bw = fhi - flo;
pwr = P/100 * totPwr;

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

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function f = interpFreq(cumPwr, cumF, pwrThresh)

nChan = size(cumPwr,2);
f = coder.nullcopy(zeros(1,nChan,'like',cumPwr(1)+cumF(1)+pwrThresh(1)));

for iChan = 1:nChan
  idx = find(pwrThresh(iChan)<=cumPwr(:,iChan),1,'first');
  if ~isempty(idx)
    % scalar inference for codegen
    idx1 = idx(1);
    if idx1==1
       idx1=2;
    end
    f(iChan) = signalwavelet.internal.linterp(cumF(idx1-1),cumF(idx1), ...
                 cumPwr(idx1-1,iChan),cumPwr(idx1,iChan),pwrThresh(iChan));
  else
    % codegen requires both conditional branches to have the same data type
    % for 'f'
    f(iChan) = nan(1,'like',cumPwr(1)+cumF(1)+pwrThresh(1));
  end
end

end