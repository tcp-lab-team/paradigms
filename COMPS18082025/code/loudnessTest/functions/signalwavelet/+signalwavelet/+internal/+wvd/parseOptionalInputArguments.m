function [dataOpts,opts] = parseOptionalInputArguments(dataOpts,funcName,varargin)
% parseOptionalInputArguments : Parser function for wvd & xwvd
%   For internal use only.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

% Initialization of local variables used
isTimeWinProvided = false;
isFreqWinProvided = false;
isMATLAB = coder.target('MATLAB');
isTimeTableFlag = isMATLAB && dataOpts.IsTimeTable;

% XWVD or WVD
isCrossWVD = coder.const(funcName == "xwvd");

validStrings = {'smoothedPseudo','NumTimePoints','NumFrequencyPoints','MinThreshold'};
% default values : NumTimePoints, NumFrequencyPoints, Minthreshold
numTimePoints = -1;
numFrequencyPoints = -1;
minThreshold = -1;
effectiveFs = 2;
isNormalizedFreq = false;
timeValue = 2*pi;
timeVector = 0;

if isCrossWVD
    timeWindow = zeros(dataOpts.DataLength,1,'like',dataOpts.XData);
    freqWindow = zeros(dataOpts.DataLength,1,'like',dataOpts.XData);
else
    timeWindow = zeros(dataOpts.DataLength,1,'like',dataOpts.Data);
    freqWindow = zeros(dataOpts.DataLength,1,'like',dataOpts.Data);
end

% Parse Input arguments
if ~isempty(varargin)
    strtIdx = 1;
    % Extract Ts(Duration) or Fs (Scalar)
    if ~(isStringScalar(varargin{1}) || ischar(varargin{1}))
        strtIdx = strtIdx + 1;
        if isMATLAB && isduration(varargin{1})
            timeValue = varargin{1};
            dataOpts.TimeMode = 2; % time mode : ts
        else
            validateattributes(varargin{1},{'numeric'},...
                {'scalar','real','finite','positive'},funcName,'sample rate');
            timeValue = double(varargin{1});
            timeValue = timeValue(1);
            dataOpts.TimeMode = 1; % time mode : fs
        end
    end
    
    % copy the varargin from 'strtIdx to end' to another cell array
    inputCell = cell(1,numel(varargin)-(strtIdx-1));
    [inputCell{:}] = varargin{strtIdx:end};
    
    coder.internal.errorIf(~isempty(inputCell) && (~(ischar(inputCell{1}) || isStringScalar(inputCell{1}))),...
        'shared_signalwavelet:wvd:wvd:WindowsSpecifiedWithoutSmoothed');
    
    if ~isempty(inputCell)
        if isMATLAB  % MATLAB Version
            % Parse smoothedPseudo flag and time window and frequency window
            str = validatestring(inputCell{1},validStrings,funcName);
            if strcmp(str,'smoothedPseudo')
                dataOpts.Type = "spw"; %Type : SPWVD
                if numel(inputCell) > 1 &&  (isnumeric(inputCell{2})) % check for twin
                    if numel(inputCell) > 2 && (isnumeric(inputCell{3})) % check for fwin
                        % Both Twin and fwin present. Parse fwin
                        validateattributes(inputCell{3},{'single','double'},{'vector','real','finite'},funcName,'frequency window');
                        if isCrossWVD
                            freqWindow = cast(inputCell{3}(:),'like',dataOpts.XData);
                        else
                            freqWindow = cast(inputCell{3}(:),'like',dataOpts.Data);
                        end
                        coder.internal.errorIf(length(freqWindow) < 3 || rem(length(freqWindow),2) == 0,...
                            'shared_signalwavelet:wvd:wvd:WindowLengthMustBeOdd');
                        isFreqWinProvided = true;
                        nvPairIndx = 4; % index to keep track of starting position of Name value pairs
                    else
                        % Only twin present
                        nvPairIndx = 3; % index to keep track of starting position of Name value pairs
                    end
                    % Parse twin
                    validateattributes(inputCell{2},{'single','double'},{'vector','real','finite'},funcName,'time window');
                    if isCrossWVD
                        timeWindow = cast(inputCell{2}(:),'like',dataOpts.XData);
                    else
                        timeWindow = cast(inputCell{2}(:),'like',dataOpts.Data);
                    end
                    coder.internal.errorIf(length(timeWindow) < 3 || rem(length(timeWindow),2) == 0,...
                        'shared_signalwavelet:wvd:wvd:WindowLengthMustBeOdd');
                    isTimeWinProvided = true;
                else
                    % No twin and fwin present
                    nvPairIndx = 2; % index to keep track of starting position of Name value pairs
                end
            else
                % only name value pairs other than "smoothedPseudo"
                nvPairIndx = 1; % index to keep track of starting position of Name value pairs
            end
            
            if ~isempty(inputCell(nvPairIndx:end))
                % Parse all the name value pairs : 'NumTimePoints','NumFrequencyPoints','MinThreshold'
                p = inputParser;
                addParameter(p,'NumTimePoints',[]);
                addParameter(p,'NumFrequencyPoints',[]);
                addParameter(p,'MinThreshold',[]);
                
                if ~(ischar(inputCell{nvPairIndx}) || isStringScalar(inputCell{nvPairIndx}))
                    coder.internal.error('shared_signalwavelet:wvd:wvd:IncorrectNumValueOnlyInputs');
                end
                
                % Parse
                parse(p,inputCell{nvPairIndx:end});
                
                % Validation of values and assigning
                if ~isempty(p.Results.NumTimePoints)
                    if isCrossWVD
                        coder.internal.error('shared_signalwavelet:wvd:wvd:OversamplingWithXWVD');
                    end
                    validateattributes(p.Results.NumTimePoints,{'numeric'},{'real','scalar','integer','even','positive','>',2},...
                        funcName,'NumTimePoints');
                    numTimePoints = double(p.Results.NumTimePoints(1));
                end
                
                if ~isempty(p.Results.NumFrequencyPoints)
                    validateattributes(p.Results.NumFrequencyPoints,{'numeric'},{'real','scalar','integer','positive','>',2},...
                        funcName,'NumFrequencyPoints');
                    numFrequencyPoints = double(p.Results.NumFrequencyPoints(1));
                end
                
                if ~isempty(p.Results.MinThreshold)
                    validateattributes(p.Results.MinThreshold,{'numeric'},{'real','scalar','nonempty'},...
                        'wvd','MinThreshold');
                    minThreshold = double(p.Results.MinThreshold(1));
                end
                
            end
            
        else
            % Codegen Version
            parms = struct(...
                'smoothedPseudo',zeros(1,3),...
                'NumTimePoints',zeros(1,3),...
                'NumFrequencyPoints',zeros(1,3),...
                'MinThreshold',zeros(1,3));
            poptions = struct( ...
                'CaseSensitivity',false, ...
                'PartialMatching','unique', ...
                'StructExpand',false, ...
                'IgnoreNulls',true,...
                'RepValues',[2 1 1 1]);
            % 'RepValues' : Represents number of values present for each parameter names.
            % Smoothed pseudo is followed by max 2 values. All others are name value pairs.
            
            % parse the inputs
            pstruct = signalwavelet.internal.util.parseArgumentsOpt(parms,poptions,inputCell{:});
            
            % Retrieve parameter values
            % 1. SmoothedPseudo flag, twin, fwin
            smoothedPseudo = coder.const(pstruct.smoothedPseudo(1));
            tIdx = coder.const(pstruct.smoothedPseudo(2));
            fIdx = coder.const(pstruct.smoothedPseudo(3));
            
            if smoothedPseudo
                twin = signalwavelet.internal.util.getParameterValue(tIdx,0,inputCell{:});
                fwin = signalwavelet.internal.util.getParameterValue(fIdx,0,inputCell{:});
                
                dataOpts.Type = "spw"; % Type : SPWVD
                
                if twin ~= 0
                    % Time window
                    validateattributes(twin,{'single','double'},{'vector','real','finite'},funcName,'time window');
                    if isCrossWVD
                        timeWindow = cast(twin(:),'like',dataOpts.XData);
                    else
                        timeWindow = cast(twin(:),'like',dataOpts.Data);
                    end
                    coder.internal.errorIf(length(timeWindow) < 3 || rem(length(timeWindow),2) == 0,...
                        'shared_signalwavelet:wvd:wvd:WindowLengthMustBeOdd');
                    isTimeWinProvided = true;
                end
                
                if fwin ~= 0
                    % frequency window
                    validateattributes(fwin,{'single','double'},{'vector','real','finite'},funcName,'frequency window');
                    if isCrossWVD
                        freqWindow = cast(fwin(:),'like',dataOpts.XData);
                    else
                        freqWindow = cast(fwin(:),'like',dataOpts.Data);
                    end
                    coder.internal.errorIf(length(freqWindow) < 3 || rem(length(freqWindow),2) == 0,...
                        'shared_signalwavelet:wvd:wvd:WindowLengthMustBeOdd');
                    isFreqWinProvided = true;
                end
            end
            
            % 2. Numtimepoints
            if ~isCrossWVD
                if coder.const(pstruct.NumTimePoints(1))
                    numTimePoints = double(signalwavelet.internal.util.getParameterValue...
                        (pstruct.NumTimePoints(2),dataOpts.DataLength,inputCell{:}));
                    validateattributes(numTimePoints,{'numeric'},{'scalar','integer','even','positive','>',2},funcName,'NumTimePoints');                    
                    numTimePoints = numTimePoints(1);
                else
                    numTimePoints = -1;
                end
                coder.internal.errorIf(isempty(numTimePoints),'shared_signalwavelet:wvd:wvd:PairNameValueInputsNonEmpty');                
            else
                coder.internal.errorIf(coder.const(pstruct.NumTimePoints(1) == 1),'shared_signalwavelet:wvd:wvd:OversamplingWithXWVD');
            end
            
            % 3. NumFrequencyPoints
            if coder.const(pstruct.NumFrequencyPoints(1))
                numFrequencyPoints = double(signalwavelet.internal.util.getParameterValue...
                    (pstruct.NumFrequencyPoints(2),floor(dataOpts.DataLength)/2,inputCell{:}));
                validateattributes(numFrequencyPoints,{'numeric'},{'scalar','integer','positive','>',2},...
                funcName,'NumFrequencyPoints');                
                numFrequencyPoints = numFrequencyPoints(1);
            else
                numFrequencyPoints = -1;
            end
            coder.internal.errorIf(isempty(numFrequencyPoints),'shared_signalwavelet:wvd:wvd:PairNameValueInputsNonEmpty');
            
            % 4. minThreshold
            if coder.const(pstruct.MinThreshold(1))
                minThreshold = double(signalwavelet.internal.util.getParameterValue...
                    (pstruct.MinThreshold(2),-Inf,inputCell{:}));
            else
                minThreshold = -1;
            end
            coder.internal.errorIf(isempty(minThreshold),'shared_signalwavelet:wvd:wvd:PairNameValueInputsNonEmpty');
            validateattributes(minThreshold,{'numeric'},{'real','scalar','nonempty'},funcName,'MinThreshold');
            minThreshold = minThreshold(1);
        end
    end
end

coder.internal.errorIf((numTimePoints ~= -1 || numFrequencyPoints ~= -1) && dataOpts.Type == "wvd",...
    'shared_signalwavelet:wvd:wvd:OversamplingWithWVD');

% Default values Assignment : NumTimePoints, NumFrequencyPoints, MinThreshold
if numTimePoints == -1
    numTimePoints = dataOpts.DataLength;
end

if numFrequencyPoints == -1
    numFrequencyPoints = floor(dataOpts.DataLength)/2;
end

if  minThreshold == -1
    minThreshold = -Inf;
end

if ~isTimeWinProvided
    nTimeWin = round(dataOpts.DataLength / 10);
    if rem(nTimeWin,2) ~= 1 % check for even
        nTimeWin = nTimeWin + 1;
    end
    if isCrossWVD
        timeWindow = cast(kaiserwin(nTimeWin,20),'like',dataOpts.XData);
    else
        timeWindow = cast(kaiserwin(nTimeWin,20),'like',dataOpts.Data);
    end
end

if ~isFreqWinProvided
    % Nf may be < signal size, so DataLength/4 may be larger than the size
    % of the TFR matrix in the freq. dimension if Nf is provided. In this
    % case, use the user-provided Nf value as the frequency window length.
    nFreqWin = min(numFrequencyPoints,round(dataOpts.DataLength/4));
    if rem(nFreqWin,2) ~= 1 % check for even
        nFreqWin = nFreqWin + 1;
    end
    if isCrossWVD
        freqWindow = cast(kaiserwin(nFreqWin,20),'like',dataOpts.XData);
    else
        freqWindow = cast(kaiserwin(nFreqWin,20),'like',dataOpts.Data);
    end
end

coder.internal.errorIf((isTimeWinProvided && length(timeWindow) > dataOpts.DataLength)|| ...
    (isFreqWinProvided && length(freqWindow) > numFrequencyPoints),...
    'shared_signalwavelet:wvd:wvd:WindowLengthTooLarge',(dataOpts.DataLength),(numFrequencyPoints));

coder.internal.errorIf(dataOpts.Type == "spw" && ((~isTimeWinProvided && dataOpts.DataLength < 2*10) || ...
    (~isFreqWinProvided && numFrequencyPoints < 4)),'shared_signalwavelet:wvd:wvd:InvalidSignalLengthWithDefaultWindows');

% Validate Time Parameter Inputs
switch dataOpts.TimeMode
    case 1
        % time mode : "fs"
        if isTimeTableFlag
            coder.internal.error('shared_signalwavelet:wvd:wvd:SampleRateAndTimetableInput');
        end
        effectiveFs = double(timeValue);
        % Multiply by 1/2 to account for doubled signal length.
        totalDuration = 0.5/effectiveFs*dataOpts.DataLength;
        timeVector = (0:numTimePoints-1).'*totalDuration/numTimePoints;
        
    case 2
        % time mode : "ts"
        if isTimeTableFlag
            coder.internal.error('shared_signalwavelet:wvd:wvd:SampleRateAndTimetableInput');
        end
        if isMATLAB
            validateattributes(timeValue,{'duration'},{'scalar'},funcName,'sample time');
            effectiveFs = 1/seconds(timeValue);
            % Multiply by 1/2 to account for doubled signal length.
            totalDuration = 0.5/effectiveFs*dataOpts.DataLength;
            timeVector = (0:numTimePoints-1).'*totalDuration/numTimePoints;
            dataOpts.TimeUnits = timeValue.Format;
        end
        
    case 0
        % time mode : samples
        effectiveFs = 2;
        % Multiply by 1/2 to account for doubled signal length.
        timeVector = 0.5*(0:numTimePoints-1).'*dataOpts.DataLength/numTimePoints;
        isNormalizedFreq = true;
end

if isMATLAB && isTimeTableFlag
    rowTimes = dataOpts.RowTimes;
    if isduration(rowTimes)
        ttTimeVector = seconds(rowTimes);
    else
        d = rowTimes - rowTimes(1);
        ttTimeVector = seconds(d);
    end
    timeVector = ttTimeVector(:);
    validateattributes(timeVector,{'numeric'},{'column','nonnan','finite'},...
        funcName,'time values');
    if length(timeVector) ~= length(unique(timeVector))
        coder.internal.error('shared_signalwavelet:wvd:wvd:TimeValuesUnique');
    end
    if ~issorted(timeVector)
        coder.internal.error('shared_signalwavelet:wvd:wvd:TimeValuesIncreasing');
    end
    err = max(abs(timeVector(:).'-linspace(timeVector(1),timeVector(end),numel(timeVector)))./max(abs(timeVector)));
    needsResampling = err > 3*eps(class(timeVector));
    if needsResampling
        coder.internal.error('shared_signalwavelet:wvd:wvd:NonuniformlySampledTimeValues');
    end
    effectiveFs = 1 / median(diff(timeVector));
    totalDuration = 0.5/effectiveFs*dataOpts.DataLength;
    timeVector = (0:numTimePoints-1).'*totalDuration/numTimePoints;
end

opts = struct(...
    'EffectiveFs'       ,effectiveFs,...
    'IsNormalizedFreq'  ,isNormalizedFreq,...
    'NumTimePoints'     ,numTimePoints,...
    'NumFrequencyPoints',numFrequencyPoints,...
    'TimeVector'        ,timeVector,...
    'TimeWindow'        ,timeWindow,...
    'FrequencyWindow'   ,freqWindow,...
    'MinThreshold'      ,minThreshold...
    );

function w = kaiserwin(N,bta)


narginchk(1,2);
coder.internal.prefer_const(N);
nw = coder.internal.indexInt(N);
if nargin < 2 || (coder.internal.isConst(isempty(bta)) && isempty(bta)) 
    bta = 0.500; % default value for bta parameter.
else
    coder.internal.prefer_const(bta);
    
end

if coder.internal.isConst(bta)
    bestmp = coder.const(feval('besseli',0,bta));
    bes = coder.const(abs(bestmp));
else
    bes = abs(besseli(0,bta));
end
ONE = coder.internal.indexInt(1);
% Allocate w.
w = coder.nullcopy(zeros(nw,1));
if nw <= 1
    w(:) = 1;
    return
end
% Fill the second half of w.
iseven = ONE - bitand(nw,ONE);
mid = bitshift(nw,-double(ONE));
maxxi = double(nw) - 1;
midp1 = mid + 1;
for k = midp1:nw
    xi = iseven + 2*(k - midp1);
    r = double(xi)/maxxi;
    z = bta*sqrt((1 - r)*(1 + r));
    w(k) = abs(besseli(0,z)/bes);
end
% Flip the second half into the first half.
for k = 1:mid
    w(k) = w(nw - k + 1);
end

end



end

% LocalWords:  wvd Minthreshold Fs fs signalwavelet SPWVD Frequencywindow Func
% LocalWords:  nonnan Nonuniformly XWVD strt fwin Numtimepoints TFR xwvd
