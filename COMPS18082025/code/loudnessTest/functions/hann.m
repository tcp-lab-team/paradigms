function w = hann(varargin)
%HANN   Hann window.
%   HANN(N) returns the N-point symmetric Hann window in a column vector.
% 
%   HANN(N,SFLAG) generates the N-point Hann window using SFLAG window sampling.
%   SFLAG may be either 'symmetric' or 'periodic'. By default, a symmetric
%   window is returned. 
%
%   % Example:
%   %   Create a 64-point Hann window and display the result in WVTool.
%
%   L=64;
%   wvtool(hann(L))
%
%   See also BLACKMAN, HAMMING, WINDOW.

%   Copyright 1988-2018 The MathWorks, Inc.
%#codegen

% Check number of inputs

narginchk(1,2);

if coder.target('MATLAB')
    w = gencoswin('hann',varargin{:});
else
    % check for constant inputs
    allConst = true;
    coder.unroll();
    for k = 1:nargin
        allConst = allConst && coder.internal.isConst(varargin{k});
    end
    if allConst && coder.internal.isCompiled
        % codegen for constant input arguments
        w = coder.const(@feval,'hann',varargin{:});
    else
        % codegen for variable input argument
        w = gencoswin('hann',varargin{:});
    end
    
end

    
% [EOF] hann.m

% LocalWords:  SFLAG
