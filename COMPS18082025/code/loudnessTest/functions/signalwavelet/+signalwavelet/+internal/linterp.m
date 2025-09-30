function y = linterp(ypre, ypost, xpre, xpost, x)
%LINTERP Linearly interpolate between two points.
%  This function corresponds to algorithm in IEEE Std 181-2003 Section
%  5.3.3.2 step (b) for computing reference level instants between two
%  consecutive samples which bound or border the desired reference level.
%
%   This function is for internal use only. It may change or be removed in 
%   a future release.

%   Copyright 2011-2018 The MathWorks, Inc.
%#codegen

  y = ypre + (ypost - ypre) .* (x - xpre) ./ (xpost - xpre);
end
