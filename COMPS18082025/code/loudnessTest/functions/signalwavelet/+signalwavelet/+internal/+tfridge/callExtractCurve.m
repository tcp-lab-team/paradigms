function curve = callExtractCurve(energy,penalty)
% CALLEXTRACTCURVE Call extractCurve based on target

%   Copyright 2019 The MathWorks, Inc.

%#codegen
if coder.target('MATLAB')
    if isa(energy,'double')
        curve = signalwavelet.internal.tfridge.extractCurve_mx(energy,penalty);
    else
        curve = signalwavelet.internal.tfridge.extractCurve_mxs(energy,penalty);
    end
else
    curve = signalwavelet.internal.tfridge.extractCurve(energy,penalty);
end

end
