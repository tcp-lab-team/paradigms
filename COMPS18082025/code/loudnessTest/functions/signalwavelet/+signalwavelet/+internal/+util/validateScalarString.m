function [flag, stringValue] = validateScalarString(input)
%validateScalarString Validate that input is a char or scalar string
%
%  This function is for internal use only and may be removed in a future
%  release of MATLAB

%   Copyright 2018 The MathWorks, Inc.

flag = ischar(input) || (isstring(input) && isscalar(input));

stringValue = "";
if flag
    stringValue = string(input);
end

end