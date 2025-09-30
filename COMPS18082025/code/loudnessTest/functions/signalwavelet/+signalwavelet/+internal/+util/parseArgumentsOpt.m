function pstruct = parseArgumentsOpt(parms,options,varargin)
% parseArgumentsOpt Processes varargin for parameter name-value pairs and name-value triplets.
%   The first input, PARMS, must be a cell array of string scalars
%   or a struct with field names corresponding to all valid parameters. A
%   possible advantage to supplying a struct is that it may compile faster
%   (run-time performance will be the same), but if it is a struct, the
%   value stored in each field must be a scalar array of length 3 of type 'double'.
%   The return value PSTRUCT is such a structure. The 'double' values returned in it are
%   used to look up the corresponding parameter values in varargin{:}.
%   The return value PSTRUCT will have an array of length 3 associated with each fields.
%   Each values in the array is read as explained below using the example:
%   For example:
%   parms = struct(...
%                 'smoothedPseudo',double(zeros(1,3)),...
%                 'NumTimePoints',double(zeros(1,3)),...
%                 'NumFrequencyPoints',double(zeros(1,3)),...
%                 'MinThreshold',double(zeros(1,3)));
%   poptions = struct( ...
%                 'CaseSensitivity',false, ...
%                 'PartialMatching','unique', ...
%                 'StructExpand',false, ...
%                 'IgnoreNulls',true,...
%                 'RepValues',[2 1 1 1]);
%   pstruct returned will have the similar structure as params.

%   Copyright 2019 The MathWorks, Inc.

%   pstruct : struct(...
%                 'smoothedPseudo'      [3 2 3]
%                 'NumTimePoints'       [0 0 0]
%                 'NumFrequencyPoints'  [2 5 0]
%                 'MinThreshold'        [2 7 0])
%  RepValues should indicate the number of values followed by the respective
%  parameters. For example, the smoothedPseudo flag can be followed by 2
%  values (Name-value triplet). 'NumTimePoints' is followed by one
%  value(Name-value pair).
%
%  pstruct.smoothedPseudo : [3 2 3]
%  The first value 3 indicates that smoothedPseudo flag was present among
%  the varargin{:} inputs and (3-1) values follows the smoothedPseudo flag
%  and their indexes are at 2 and 3 in the varargin{:} list.
%
%  pstruct.NumTimePoints : [0 0 0]
%  The first value 0 indicates that NumTimePoints flag was not present
%  among the varargin{:} list.
%
%  pstruct.NumFrequencyPoints : [2 5 0]
%  Th first value 2 indicates that NumFrequencyPoints was present among the
%  varargin{:} list and (2-1) values follows the NumFrequencyPoints and its
%  index is 5 among the varargin{:} list.
%
%  Special case :
%  pstruct.smoothedPseudo : [1 0 0]
%  The first value 1 indicates that smoothedPseudo was present among the
%  varargin{:} list but it is followed by (1-1) values. here,
%  smoothedPseudo acts as a flag.
%
%   To retrieve a parameter value, use signalwavelet.internal.wvd.getParameterValue. For
%   example, to retrieve the parameter AbsTol, you might write
%
%       abstol = signalwavelet.internal.wvd.getParameterValue(pstruct.abstol,1e-5,varargin{:})
%
%   where 1e-5 is the default value for AbsTol in case it wasn't specified
%   by the user.
%
%   The options input must be [] or a structure with any of the fields
%       1. CaseSensitivity
%          true    --> case-sensitive name comparisons.
%          false   --> case-insensitive name comparisons (the default).
%       2. StructExpand
%          true    --> expand structs as sequences of parameter name-value
%                    pairs (the default).
%          false   --> structs not expanded and will generate an error.
%       3. PartialMatching
%          'none'  --> parameter names must match in full (the default).
%          'first' --> parameter names match if they match in all the
%                      characters supplied by the user. There is no
%                      validation of the parameter name set for
%                      suitability. If more than one match is possible, the
%                      first is used. If a preference should be given to an
%                      exact match, sort the fields of parms so that the
%                      shortest possible partial match will always be the
%                      first partial match.
%          'unique'--> Same as 'first' except that if there are no exact
%                      matches, any partial matches must be unique. An
%                      error will be thrown if there are no exact matches
%                      and there is more than one partial match.
%          true    --> Legacy input. Same as 'first'.
%          false   --> Legacy input. Same as 'none'.
%       4. IgnoreNulls
%          true    --> A fixed-size, constant value [] is treated as if the
%                      corresponding parameter were not supplied at all.
%          false   --> Values of [] are treated like any other value input
%                      (the default).
%       5. RepValues : array representing the number of values of each
%       parameter.
%         it should indicate the number of values followed by the respective
%         parameters. For example, the smoothedPseudo flag can be followed by 2
%         values (Name-value triplet). 'NumTimePoints' is followed by one
%         value(Name-value pair). For example, [2 1 1 1].
%
%   Note that any parameters may be specified more than once in the inputs.
%   The last instance silently overrides all previous instances.
%
%   The maximum number of parameter names is 65535.
%   The maximum length of VARARGIN{:} is also 65535.
%
%   Example:
%
%   Parse a varargin list for parameters 'tol', 'method', and 'maxits',
%   where 'method' is a required parameter. Struct input is not
%   permitted, and case-insensitive partial matching is done.
%
%       % Define the parameter names either using a struct
%   parms = struct(...
%                 'smoothedPseudo',double(zeros(1,3)),...
%                 'NumTimePoints',double(zeros(1,3)),...
%                 'NumFrequencyPoints',double(zeros(1,3)),...
%                 'MinThreshold',double(zeros(1,3)));
%   poptions = struct( ...
%                 'CaseSensitivity',false, ...
%                 'PartialMatching','unique', ...
%                 'StructExpand',false, ...
%                 'IgnoreNulls',true,...
%                 'RepValues',[2 1 1 1]);
%
%       % Parse the inputs.
%       pstruct = signalwavelet.internal.wvd.parseArgumentsOpt(parms,poptions,varargin{:});
%
%       % Check whether the parameter is present among the inputs.
%       isTol = coder.const(pstruct.tol(1));

%       % Retrieve parameter values.
%       % 1. SmoothedPseudo flag followed by twin and fwin
%       smoothedPseudo = coder.const(pstruct.smoothedPseudo(1));
%       tIdx = coder.const(pstruct.smoothedPseudo(2));
%       fIdx = coder.const(pstruct.smoothedPseudo(3));
%       if smoothedPseudo
%             twin = signalwavelet.internal.wvd.getParameterValue(tIdx,0,inputCell{:});
%             fwin = signalwavelet.internal.wvd.getParameterValue(fIdx,0,inputCell{:});
%       end
%       2. NumTimePoints
%       if pstruct.NumTimePoints(1)
%         numTimePoints = signalwavelet.internal.wvd.getParameterValue...
%             (pstruct.NumTimePoints(2),dataOpts.DataLength,inputCell{:});
%       end
%#codegen

coder.inline('always');
narginchk(2,inf);
coder.internal.prefer_const(parms,options);
coder.internal.assert((iscell(parms) || isstruct(parms)),'Coder:toolbox:eml_parse_parameter_inputs_2');

if iscell(parms)
    pstruct = parseArgumentsOpt(coder.const(makeStruct(parms)),options,varargin{:});
    return
end

% Process the options
[casesens,~,prtmatch,ignnulls,repValues] = process_options(options);

% number of varargin arguments
n = nargin - 2;

% These are technical limitations of this implementation, so we check them
% here, regardless of whether another limitation may make them impossible
% to violate.
coder.internal.assert(n <= 65535,'Coder:toolbox:eml_parse_parameter_inputs_3');
coder.internal.assert(numfields(parms) <= 65535,'Coder:toolbox:eml_parse_parameter_inputs_4');

% Create and initialize the output structure.
% Each field of structure have a array of 3 values associated with it.
% 1st value : represents whether the Name is present is among the
% varargins. 0 means not present. 1 means present.
% 2nd Value : index of the 1st value among the varargins.
% 3rd value : (optional) index of the 2nd value among the varargins.
pstruct = coder.nullcopy(parms);
ZERO = zeros(1,3);
coder.unroll();
for k = 1:numfields(parms)
    coder.internal.assert( ...
        isreal(getfield(parms,getfieldname(parms,k))) && ...
        isa(getfield(parms,getfieldname(parms,k)),'double'), ...
        'Coder:toolbox:eml_parse_parameter_inputs_5');
    pstruct.(getfieldname(parms,k)) = ZERO; %initialize to zero array of length 3.
end

% Parse varargin
[t,nParmsPresent] = coder.const(@input_types,varargin{:});

% Traverse through the t array and find the index of the values among the
% varargins
nvCount = 0; % To keep track of values associated with a parameter name.
nv = false;
coder.unroll();
for k = 1:n
    if coder.const(t(k) == PARAMETER_NAME)
        % Find the index of the field varargin{k} in PARMS.
        coder.internal.assert(coder.internal.isConst(varargin{k}),'Coder:toolbox:eml_parse_parameter_inputs_15');
        pidx = coder.const(field_index(varargin{k},parms,casesens,prtmatch));
        nv = true;
        % Get the number of parameter values from repValues.
        reqValues = coder.const(repValues(pidx));
        repIdx = coder.const(zeros(1,3,'double'));
        nValusPresent = 1;
        nvCount = reqValues;
        coder.unroll();
        for val = 1:reqValues
            if coder.const((k+val) <= n && t(k+val) == PARAMETER_VALUE)
                if ~ignnulls || ~isnull(varargin{k+val})
                    repIdx(val+1) = coder.const(double(k + val));
                    nValusPresent = nValusPresent + 1;
                end
            else
                break
            end
        end
        % the first value of the v array can take 3 values
        % 1 - Name is present, but no values follows.
        % 2 - Name is present and one value follows.
        % 3 - Name is present and two values follows.
        % Name value pair and No values were present
        coder.internal.errorIf(coder.const(reqValues == 1 && nValusPresent == 1),'Coder:toolbox:eml_parse_parameter_inputs_6',getfieldname(parms,pidx));
        repIdx(1) = nValusPresent;
        pstruct.(getfieldname(parms,pidx)) = coder.const(repIdx);
        nParmsPresent = nParmsPresent - 1;
    else
        % check whether any additional values are present with the
        % parameter name associated
        if nv
            coder.internal.assert(coder.const(nvCount ~= 0 && t(k) == PARAMETER_VALUE),'Coder:toolbox:eml_parse_parameter_inputs_7');
            nvCount = nvCount - 1;
            continue;
        end
        nv = false;
    end
end

if ~coder.const(nParmsPresent == 0)
    coder.internal.assert(false,'Coder:toolbox:eml_parse_parameter_inputs_7');
end

end

%--------------------------------------------------------------------------
function n = field_index(fname,ostruct,casesens,prtmatch)
% Return the index of field FNAME in structure OSTRUCT. Asserts if FNAME
% is not a member of OSTRUCT.
coder.inline('always');
coder.internal.prefer_const(fname,ostruct,casesens,prtmatch);
[n,ncandidates] = field_index_kernel(fname,ostruct,casesens,prtmatch);
coder.internal.assert(ncandidates ~= 0,'Coder:toolbox:eml_parse_parameter_inputs_16',fname);
coder.internal.assert(ncandidates == 1, ...
    'Coder:toolbox:AmbiguousPartialMatch',fname, ...
    coder.const(feval('coder.internal.partialParameterMatchString', ...
    coder.internal.toCharIfString(fname),ostruct,casesens)));
end
%--------------------------------------------------------------------------
function [n,ncandidates] = field_index_kernel(fname,ostruct,casesens,prtmatch)
% Return the index of field FNAME in structure OSTRUCT. Asserts if FNAME
% is not a member of OSTRUCT.
coder.inline('always');
coder.internal.prefer_const(fname,ostruct,casesens,prtmatch);
n = 0;
ncandidates = 0;
coder.unroll();
for j = 1:numfields(ostruct)
    if parameter_names_match(getfieldname(ostruct,j),fname, ...
            casesens,prtmatch)
        n = j;
        if prtmatch ~= PM_UNIQUE || ...
                parameter_names_match(getfieldname(ostruct,j), ...
                fname,casesens,PM_NONE)
            % An exact match rules out all other candidates.
            ncandidates = 1;
            break
        else
            ncandidates = ncandidates + 1;
        end
    end
end
end

%--------------------------------------------------------------------------
function p = parameter_names_match(mstrparm,userparm,casesens,prtmatch)
% Compare parameter names, like strcmp, except modified optionally for case
% insensitivity and/or partial matching.
coder.inline('always');
coder.internal.prefer_const(mstrparm,userparm,casesens,prtmatch);
partial = coder.const(prtmatch ~= PM_NONE);
if coder.const(isempty(userparm))
    p = false;
elseif coder.const(casesens)
    if partial
        p = coder.const(coder.internal.partialStrcmp(mstrparm,userparm));
    else
        p = coder.const(strcmp(mstrparm,userparm));
    end
else
    if partial
        p = coder.const(strncmpi(mstrparm,userparm,strlength(userparm)));
    else
        p = coder.const(strcmpi(mstrparm,userparm));
    end
end
end
%--------------------------------------------------------------------------
function [t,nParmsPresent] = input_types(varargin)
% Returns an array, t, indicating the classification of each argument as a
% parameter name, parameter value, or unrecognized. The
% return value must be constant folded.
% nParmsPresent represents number of Parameters present among the
% varargins.
coder.internal.allowEnumInputs;
t = zeros(nargin,1,'int8');
nParmsPresent = 0;
coder.unroll();
for k = 1:nargin
    if coder.const(coder.internal.isCharOrScalarString(varargin{k}))
        if coder.internal.isConst(varargin{k})
            t(k) = PARAMETER_NAME;     
            nParmsPresent = nParmsPresent + 1;
        else
            t(k) = PARAMETER_VALUE;
        end
    elseif isnumeric(varargin{k})
        t(k) = PARAMETER_VALUE;
    else
        t(k) = UNRECOGNIZED_INPUT;
    end
end
end
%--------------------------------------------------------------------------
function [casesens,expstrct,prtmatch,ignnulls,repValues] = process_options(options)
% Extract parse options from options input structure, supplying default
% values if needed.
coder.internal.allowEnumInputs;
coder.internal.prefer_const(options);
coder.internal.assert(coder.internal.isConst(options),'Coder:toolbox:eml_parse_parameter_inputs_9');
% Set defaults.
casesens = false;
expstrct = true;
prtmatch = PM_NONE;
ignnulls = false;
% Read options.
if ~isempty(options)
    coder.internal.assert(isstruct(options),'Coder:toolbox:eml_parse_parameter_inputs_10');
    coder.unroll();
    for k = 1:numfields(options)
        if coder.const(strcmp(getfieldname(options,k),'CaseSensitivity'))
            coder.internal.assert(isscalar(options.CaseSensitivity) && islogical(options.CaseSensitivity), ...
                'Coder:toolbox:eml_parse_parameter_inputs_11');
            casesens = options.CaseSensitivity;
        elseif coder.const(strcmp(getfieldname(options,k),'StructExpand'))
            coder.internal.assert(isscalar(options.StructExpand) && islogical(options.StructExpand), ...
                'Coder:toolbox:eml_parse_parameter_inputs_12');
            expstrct = options.StructExpand;
        elseif coder.const(strcmp(getfieldname(options,k),'PartialMatching'))
            isfirst = strcmp(options.PartialMatching,'first') || ( ...
                isscalar(options.PartialMatching) && ...
                options.PartialMatching ~= false);
            isnone = strcmp(options.PartialMatching,'none') || ( ...
                isscalar(options.PartialMatching) && ...
                options.PartialMatching == false);
            isunique = strcmp(options.PartialMatching,'unique');
            coder.internal.assert(isfirst || isnone || isunique, ...
                'Coder:toolbox:eml_parse_parameter_inputs_13');
            if isunique
                prtmatch = PM_UNIQUE;
            elseif isfirst
                prtmatch = PM_FIRST;
            else
                prtmatch = PM_NONE;
            end
        elseif coder.const(strcmp(getfieldname(options,k),'IgnoreNulls'))
            coder.internal.assert(isscalar(options.IgnoreNulls) && ...
                islogical(options.IgnoreNulls), ...
                'Coder:toolbox:BadIgnoreNulls');
            ignnulls = coder.const(options.IgnoreNulls);
        elseif coder.const(strcmp(getfieldname(options,k),'RepValues'))
            validateattributes(options.RepValues,{'numeric'},{'vector','nonempty','integer','positive','real'});
            repValues = coder.const(options.RepValues);
        else
            coder.internal.assert(false, ...
                'Coder:toolbox:eml_parse_parameter_inputs_14');
        end
    end
end
end
%--------------------------------------------------------------------------
function pstruct = makeStruct(parmsCell)
% Convert a cell array of string scalars or char arrays to a parms
% structure.
coder.internal.prefer_const(parmsCell);
coder.internal.assert(coder.internal.isConst(parmsCell), ...
    'Coder:toolbox:InputMustBeConstant','parms');
for k = coder.unroll(1:length(parmsCell))
    coder.internal.assert(coder.internal.isTextRow(parmsCell{k}), ...
        'MATLAB:mustBeFieldName');
    pstruct.(parmsCell{k}) = double([0 0 0]);
end

end

%--------------------------------------------------------------------------
% Input types

function n = PARAMETER_VALUE
coder.inline('always')
n = int8(0);
end

function n = PARAMETER_NAME
coder.inline('always')
n = int8(1);
end

function n = UNRECOGNIZED_INPUT
coder.inline('always')
n = int8(-1);
end

%--------------------------------------------------------------------------

function n = PM_NONE
% No partial matching.
coder.inline('always');
n = int8(0);
end

function n = PM_FIRST
% Use first partial match.
coder.inline('always');
n = int8(1);
end

function n = PM_UNIQUE
% Use an exact match, if any, otherwise require a unique partial match.
coder.inline('always');
n = int8(2);
end

%--------------------------------------------------------------------------

function p = isnull(x)
% Returns true if x is [] and fixed-size.
coder.inline('always');
p = isa(x,'double') && coder.internal.isConst(size(x)) && isequal(size(x),[0,0]);
end


function n = numfields(s)
n = length(fieldnames(s));
end

function fname = getfieldname(s,k)
names = fieldnames(s);
fname = names{k};
end

function y = getfield(s,fname)
y = s.(fname);
end

% LocalWords:  PARMS PSTRUCT parms poptions pstruct signalwavelet wvd abstol
% LocalWords:  maxits fwin varargins nd FNAME OSTRUCT
