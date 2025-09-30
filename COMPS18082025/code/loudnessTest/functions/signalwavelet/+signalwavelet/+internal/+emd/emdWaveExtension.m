function [extpksLoc, extpksVal, extbtmLoc, extbtmVal] = emdWaveExtension(endLoc, endVal, pkLoc, pkVal, btmLoc, btmVal, direction)
%EMDWAVEEXTENSION  Utility function for computing wave extension.
% This function is only for internal use

%   Copyright 2017 The MathWorks, Inc.

%#codegen
numExtendedWave = 3;

% compute wave amplitude, period and mean level
% assume extended wave w(t)=Asin(2*pi*t/P + phase) + m
% where A is the amplitude, P is the period, m is the mean level
A = abs(pkVal-btmVal)/2;
P = 2*abs(pkLoc-btmLoc);

coder.varsize('extpksLoc',3);
coder.varsize('extpksVal',3);
coder.varsize('extbtmLoc',3);
coder.varsize('extbtmVal',3);

% return empty if pkLoc==btmLoc
if(P~=0)
    m = endVal - A*sin(2*pi/P*(endLoc-pkLoc)+pi/2);
    
    % get extended wave location and value
    kpks = floor((endLoc-pkLoc)/P);
    kpks = kpks + (kpks<0);
    extpksLoc = (kpks+direction*(1:numExtendedWave)')*P+pkLoc;
    extpksLoc = extpksLoc(extpksLoc~=endLoc);
    extpksVal = (m + A) *ones(length(extpksLoc),1);
    
    kbtm = floor((endLoc-btmLoc)/P);
    kbtm = kbtm + (kbtm<0);
    extbtmLoc = (kbtm+direction*(1:numExtendedWave)')*P+btmLoc;
    extbtmLoc = extbtmLoc(extbtmLoc~=endLoc);
    extbtmVal = (m - A)*ones(length(extbtmLoc),1);
    
    % flip index to maintain monotonicity
    if(direction<0)
        extpksLoc = flipud(extpksLoc);
        extbtmLoc = flipud(extbtmLoc);
    end
else
    extpksLoc=[];
    extpksVal=[];
    extbtmLoc=[];
    extbtmVal=[];
end
end