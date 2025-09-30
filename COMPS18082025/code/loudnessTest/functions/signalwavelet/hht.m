function [varargout] = hht(IMF, varargin)
%HHT Hilbert Spectrum of a signal using Hilbert-Huang Transform
%   P = HHT(IMF) returns the Hilbert spectrum of the signal specified by
%   intrinsic mode functions IMF. P is a sparse matrix. IMF can be a
%   vector, matrix, or timetable. If IMF is a matrix, the transform is
%   applied to each column. If IMF is a timetable, the timetable must be
%   with a single variable containing a matrix or with multiple variables,
%   each containing a column vector. If IMF is a timetable, the sampling
%   frequency is inferred from the timetable. Otherwise, normalized
%   frequency is used as the sampling frequency.
%
%   P = HHT(IMF, Fs) specifies the sampling frequency, Fs, in hertz, when
%   IMF is a matrix.
%
%   [P,F,T] = HHT(...) also returns frequency vector in Hz, F, and time
%   vector T.
%
%   [P,F,T,IMFINSF,IMFINSE] = HHT(...) also returns the instantaneous
%   frequencies IMFINSF and instantaneous energy IMFINSE of each IMF.
%   IMFINSF and IMFINSE have same number of columns as IMF. If IMF is a
%   timetable, IMFINSF and IMFINSE are also timetables.
%
%   [...] = HHT(..., 'Name1', Value1, 'Name2', Value2, ...) specifies
%   additional properties as name-value pairs. The supported Name-Value
%   pairs are:
%
%       'FrequencyLimits':      Specify the frequency limits for computing
%                               the Hilbert spectrum as a two-element
%                               vector with positive strictly increasing
%                               elements. If Fs is specified, frequency
%                               limits are in hertz and the upper frequency
%                               limit cannot exceed Fs/2. Otherwise they
%                               are in radians/sample and the upper
%                               frequency limit cannot exceed pi.
%
%       'FrequencyResolution':  Specify the frequency resolution to the
%                               discretize frequency range. If
%                               'FrequencyResolution' is not specified, the
%                               frequency range [f_low, f_high] is divided
%                               into 100 segments, giving a resolution of
%                               (f_high-f_low)/100.
%
%       'MinThreshold':         Set elements of P to 0 when the
%                               corresponding elements of 10*log10(P) are
%                               less than MinThreshold. The default value
%                               is -Inf.
%
%   HHT(...) with no output arguments plots the Hilbert spectrum in the
%   current figure.
%
%   HHT(...,FREQLOCATION) controls where MATLAB displays the frequency axis
%   on the plot. This string can be either 'xaxis' or 'yaxis'. The default
%   is 'yaxis', which displays the frequency on the y-axis.
%
%   % EXAMPLE 1:
%      Fs = 1000;
%      t = 0:1/Fs:4;
%      x1 = sin(2*pi*50*t) + sin(2*pi*200*t);
%      x2 = sin(2*pi*25*t) + sin(2*pi*100*t) + sin(2*pi*250*t);
%      x = [x1 x2] + 0.1*randn(1,length(t)*2);
%      IMF = vmd(x,'MaxIterations',600);
%      hht(IMF,Fs)
%
%   % EXAMPLE 2: 
%      Fs = 1000;
%      t = 0:1/Fs:4;
%      x1 = sin(2*pi*50*t) + sin(2*pi*200*t);
%      x2 = sin(2*pi*25*t) + sin(2*pi*100*t) + sin(2*pi*250*t);
%      x = [x1 x2] + 0.1*randn(1,length(t)*2);
%      IMF = emd(x);
%      hht(IMF,Fs)
%
%   See also EMD and VMD.
%

% Copyright 2017-2019 The MathWorks, Inc.
%#codegen

narginchk(1,9);
nargoutchk(0,5);
[IMFd,fs,T,TD,F,FRange,FResol,MinThres,Method,FreqLoc,isTT,isNF] = parseAndValidateInputs(IMF, varargin{:});
isInMATLAB = isempty(coder.target);

% store instantaneous frequency and energy
freqIdx = zeros(size(IMFd,2), length(T));
insf = zeros(length(T), size(IMFd,2));
inse = zeros(length(T), size(IMFd,2));

for i = 1:size(IMFd,2)
    switch Method
        % for future extension
        case 'HT'
            sig = hilbert(IMFd(:,i));
            energy = abs(sig).^2;
            phaseAngle = angle(sig);
    end
    
    % compute instantaneous frequency using phase angle
    omega = gradient(unwrap(phaseAngle));
    
    % convert to Hz
    omega = fs/(2*pi)*omega;
    
    % find out index of the frequency
    omegaIdx = floor((omega-F(1))/FResol)+1;
    freqIdx(i,:) = omegaIdx(:,1)';
    
    % generate distribution
    insf(:,i) = omega;
    inse(:,i) = energy;
end

% filter out points not in the frequency range
idxKeep = (freqIdx>=1) & (freqIdx<=length(F));
timeIdx = repmat(1:length(T),size(IMFd,2),1);
% instantaneous energy is real-valued
inseFilt = inse';
% store energy in sparse matrix
if isvector(IMFd)
    P = sparse(freqIdx(idxKeep(1,:)),timeIdx(idxKeep(1,:)),inseFilt(idxKeep(1,:)),length(F),length(T));
else
    P = sparse(freqIdx(idxKeep),timeIdx(idxKeep),inseFilt(idxKeep),length(F),length(T));
end
if isInMATLAB
    P(10*log10(P) < MinThres) = 0;
else
    idx = find(10*log10(P(:)) < MinThres);
    P(idx) = 0; %#ok
end
if(isTT)
    T = TD;
end

if(nargout==0)
    coder.internal.errorIf(~isInMATLAB,'shared_signalwavelet:hht:plot:PlottingNotSupported');
    signalwavelet.internal.guis.plot.hhtPlot(insf, inse, T, FRange, MinThres, FreqLoc, isNF);
end

if(isTT && isInMATLAB)
    insf = array2timetable(insf,'RowTimes',T);
    inse = array2timetable(inse,'RowTimes',T);
end

if nargout > 0
    varargout{1} = P;
end

if nargout > 1
    varargout{2} = F;
end

if nargout > 2
    varargout{3} = T;
end

if nargout > 3
    varargout{4} = insf;
end

if nargout > 4
    varargout{5} = inse;
end

end

%--------------------------------------------------------------------------
function [IMFd,fs,T,TD,F,FRange,FResol,MinThres,Method,FreqLoc,isTT,isNF] = parseAndValidateInputs(IMF, varargin)
% input type checking
isInMATLAB = isempty(coder.target);
if isInMATLAB
    validateattributes(IMF,{'single','double','timetable'},{'2d','nonempty'},'hht','IMF');
    isTT = isa(IMF,'timetable');
else
    validateattributes(IMF,{'single','double'},{'2d','nonempty'},'hht','IMF');
    isTT = false;
end
% cast to double due to sparse matrix constraints
if isTT
    IMFd = IMF;
else
    if isvector(IMF)
        IMFd = double(IMF(:));
    else
        IMFd = double(IMF);
    end
end
coder.internal.errorIf(size(IMFd,1)<2,'shared_signalwavelet:hht:general:notEnoughRows','IMF',1);
% check if Fs/Frequency location exist or not
fs = 2*pi;
FreqLoc = 'yaxis';
isNF = true;    % if it is normalized frequency
initVarargin = 1;
finalVarargin = length(varargin);
if(~isempty(varargin))
    if(~ischar(varargin{1}) && ~isstring(varargin{1}))
        validateattributes(varargin{1},{'numeric'},{'nonnan','finite','positive','scalar'},'hht','fs');
        fs = double(varargin{1}(1));
        isNF = false;
        initVarargin = 2;
    end
    
    if((ischar(varargin{end}) || isstring(varargin{end}))...
            && mod(finalVarargin-initVarargin+1,2)==1)
        matchedStr = validatestring(varargin{end},{'yaxis','xaxis'},'hht','freqloc');
        FreqLoc = matchedStr;
        finalVarargin = length(varargin)-1;
    end
end


% handle timetable
if(isTT)
    signalwavelet.internal.util.utilValidateattributesTimetable(IMF, {'regular','sorted','multichannel'});
    [IMFd, T, TD] = signalwavelet.internal.util.utilParseTimetable(IMF);
    validateattributes(T, {'single','double'},{'nonnan','finite','real'},'hht','T');
    validateattributes(IMFd,{'single','double'},{'real','finite','nonnan','nonsparse'},'hht','IMF');
    % cast to double due to sparse matrix constraints
    IMFd = double(IMFd);
    T = double(T);
    % validate input frequency coincides with timetable
    if(~isNF)
        if(abs((T(2)-T(1))-1/fs)>eps)
            error(message('shared_signalwavelet:hht:general:notMatchedFreqTimetable','IMF'));
        end
    else
        fs = 1/(T(2)-T(1));
        isNF = false;
    end
else
    TD = [];
    T = (0:(size(IMFd,1)-1))'/fs;
end
% data integrity checking
validateattributes(IMFd,{'double'},{'real','finite','nonnan','nonsparse'},'hht','IMF');

% parse and validate name-value pairs
args = {varargin{initVarargin:finalVarargin}};
if ~isempty(args) % atleast one name value pair is present, so parse the inputs
    if(isInMATLAB)
        p = inputParser;
        addParameter(p,'FrequencyLimits',[]);
        addParameter(p,'FrequencyResolution',[]);
        addParameter(p,'MinThreshold',-inf);
        addParameter(p,'Method','HT');
        parse(p,args{:});
        FRangeOut   =  p.Results.FrequencyLimits;
        FResolOut   =  p.Results.FrequencyResolution;
        MinThresOut =  p.Results.MinThreshold;
        Method      =  p.Results.Method;
    else
        parms = struct( 'FrequencyLimits',        uint32(0), ...
            'FrequencyResolution',    uint32(0), ...
            'MinThreshold',           uint32(0), ...
            'Method',                 uint32(0));
        pstruct      =  coder.internal.parseParameterInputs(parms,[],args{:});
        FRangeOut    =  coder.internal.getParameterValue(pstruct.FrequencyLimits,[],args{:});
        FResolOut    =  coder.internal.getParameterValue(pstruct.FrequencyResolution,[],args{:});
        MinThresOut  =  coder.internal.getParameterValue(pstruct.MinThreshold,-inf,args{:});
        Method       =  coder.internal.getParameterValue(pstruct.Method,'HT',args{:});
    end
    validateattributes(MinThresOut,{'numeric'},{'nonnan','scalar'},'hht','MinThreshold');
    MinThres =  MinThresOut(1);
    validatestring(Method,{'HT','DQ'},'hht','Method');
    % compute frequency range and resolution when they are not specified
    if ~isempty(FRangeOut)
        validateattributes(FRangeOut,{'numeric'},{'nonnan','finite','numel',2,'>=',0,'<=',fs/2},'hht','FrequencyLimits');
        if(FRangeOut(1)>=FRangeOut(2))
            coder.internal.error('shared_signalwavelet:hht:general:invalidFreqRange', 'FrequencyLimits');
        end
        FRange = [FRangeOut(1); FRangeOut(2)];
    else
        FRange = cast([0;fs/2],'like',FRangeOut);
    end
    
    if ~isempty(FResolOut)
        validateattributes(FResolOut,{'numeric'},{'nonnan','finite','scalar','>',0},'hht','FrequencyResolution');
        FResol = FResolOut(1);
    else
        FResol = cast((FRange(2)-FRange(1))/100,'like',FResolOut);
    end
else
    % no name value pairs present. Assign default values to the outputs
    FRange = [0;fs/2];
    FResol = (FRange(2)-FRange(1))/100;
    MinThres = -inf;
    Method   = 'HT';
end

% set up frequency vector
F = (FRange(1):FResol:FRange(2))';
end

% LocalWords:  Fs fs IMFINSF IMFINSE discretize FREQLOCATION xaxis yaxis EMD
% LocalWords:  emd signalwavelet freqloc nonsparse atleast DQ
