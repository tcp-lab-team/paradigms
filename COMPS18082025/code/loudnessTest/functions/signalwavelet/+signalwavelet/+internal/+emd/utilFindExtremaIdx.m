function [locMax, locMin] = utilFindExtremaIdx(x) %#codegen
%UTILFINDEXTREMAIDX  Utility function to find local maxima and minima.
% This function is only for empirical mode decomposition

%   Copyright 2017 The MathWorks, Inc.
nx = length(x);
nmax = 0;
nmin = 0;
locMax = zeros(nx,1);
locMin = zeros(nx,1);
if nx >= 3
    dright = x(2) - x(1);
    for k = 2:nx-1
        dleft = dright;
        dright = x(k+1) - x(k);
        if dleft > 0 && dright <= 0
            nmax = nmax + 1;
            locMax(nmax) = k;
        elseif dleft < 0 && dright >= 0
            nmin = nmin + 1;
            locMin(nmin) = k;
        end
    end
end
locMax = locMax(1:nmax,1);
locMin = locMin(1:nmin,1);
end
