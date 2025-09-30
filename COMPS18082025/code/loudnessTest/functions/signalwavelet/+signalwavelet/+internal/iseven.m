function tf = iseven(x)
%ISEVEN Test integers for divisibility by two.
%   ISEVEN(X) returns true when X is divisible by two.
%   it returns false otherwise.  X must be integer valued.
%
%   This function is for internal use only and may be removed in a future
%   release.

%   Copyright 2018 The MathWorks, Inc.
%#codegen

coder.internal.errorIf(~isnumeric(x) || ~isreal(x) || nnz(x-fix(x)), ...
    'shared_signalwavelet:util:integer:ArgumentMustBeIntegerValued');

tf = mod(x,2)==0;