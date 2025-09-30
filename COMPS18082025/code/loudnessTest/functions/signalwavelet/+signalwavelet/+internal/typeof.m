function ty = typeof(var)
%TYPEOF return the underlying data-type for a variable
%   TYPEOF(VAR) is the same as CLASS(VAR) for standard MATLAB data-types
%   (double, single, etc.) and the same as CLASSUNDERLYING(VAR) for custom
%   types that support underlying data.
%
%   Example:
%   typeof( single(1) ) => 'single'
%   typeof( gpuArray(single(2)) ) => 'single'

%   Copyright 2019-2020 The MathWorks, Inc.
%#codegen

ty = underlyingType(var);

