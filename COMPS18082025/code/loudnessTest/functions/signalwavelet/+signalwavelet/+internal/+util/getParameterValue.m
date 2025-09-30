function y = getParameterValue(k,default,varargin)
%   Retrieves parameter values from a varargin list using a lookup value K
%   computed by EML_PARSE_PARAMETER_INPUTS.  See the help for that function
%   for example usage.

%   Copyright 2009-2019 The MathWorks, Inc.
%#codegen

coder.inline('always');
coder.internal.prefer_const(k);
coder.internal.allowEnumInputs;

if k == zeros('uint32')
    y = default;
elseif k <= uint32(intmax('uint16'))
    y = varargin{k}; 
else    
    vidx = eml_rshift(k,int8(16));
    s = varargin{vidx};
    fidx = eml_bitand(k,uint32(intmax('uint16')));
    fname = eml_getfieldname(s,fidx);
    y = eml_getfield(s,fname);
end

end
