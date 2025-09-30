function varargout = xwvd(x,y,varargin)
% XWVD Cross Wigner-Ville distribution and cross smoothed pseudo Wigner-Ville distribution
%   D = XWVD(X,Y) returns the cross Wigner-Ville distribution of X and Y. X
%   and Y can be vectors or timetables containing double or single
%   precision data. X and Y must both be timetables or both be vectors,
%   they must have the same length, and the length must be greater than
%   two. If inputs are timetables they must have a single variable with a
%   vector, must contain increasing, finite, and uniformly sampled time
%   values, and time values must be equal. D is a matrix containing a
%   time-frequency map with time along the column dimension and frequency
%   along the row dimension. By default, D is a L-by-2L matrix where
%   L = 2*ceil(length(X)/2).
%
%   D = XWVD(X,Y,Fs) specifies Fs as a numeric scalar corresponding to the
%   sample rate of the input signals in units of hertz (Hz). This parameter
%   provides time information to the inputs and only applies when these are
%   vectors.
%
%   D = XWVD(X,Y,Ts) specifies Ts as a scalar duration corresponding to
%   the sample time of the input signals. This parameter provides time
%   information to the inputs and only applies when these are vectors.
%
%   [D,F] = XWVD(...) returns frequency vector F. When the input contains
%   time information, F has units of Hz, otherwise it has units of
%   radians/sample. D has a number of rows equal to the length of F.
%
%   [D,F,T] = XWVD(...) returns time vector T. When the input contains time
%   information, T contains time values. Otherwise, it contains sample
%   numbers. D has a number of columns equal to the length of T.
%
%   [...] = XWVD(...,'smoothedPseudo') returns the cross smoothed pseudo
%   Wigner-Ville distribution of X. XWVD uses the length of the signal to
%   choose the lengths of Kaiser windows that are used for smoothing in
%   time and frequency.
%
%   [...] = XWVD(...,'smoothedPseudo',TWIN,FWIN) specifies the windows
%   TWIN and FWIN as the time and frequency windows, respectively. TWIN and
%   FWIN must be numeric vectors. TWIN or FWIN may be omitted by providing
%   the empty matrix [], which indicates that XWVD will use the length of
%   the signal to choose the length of a Kaiser window that will be used
%   for smoothing in that dimension. The default length of TWIN is the
%   smallest odd integer that is greater than or equal to 2*L/10, where
%   L = 2*ceil(length(X)/2). The default length of FWIN is the smallest odd
%   integer that is greater than or equal to L/4.
%
%   [...] = XWVD(...,'smoothedPseudo','NumFrequencyPoints',Nf) sets the
%   number of frequency points to Nf. This parameter controls the degree of
%   oversampling in time and may only be provided when the cross smoothed
%   pseudo Wigner-Ville distribution is calculated. The cross smoothed
%   pseudo Wigner-Ville matrix output D has size Nt in the time direction.
%   Nt must be an even integer and must lie in the range 2*length(TWIN) <=
%   Nt < 2*length(X). The default value of Nt is 2*length(X).
%
%   [...] = XWVD(...,'MinThreshold',THRESH) sets the elements of D to zero
%   when their amplitudes are less than THRESH. Specify THRESH as a numeric
%   scalar. If 'MinThreshold' is not specified, it defaults to -Inf.
%
%   XWVD(...) with no output arguments plots the real part of the cross
%   Wigner-Ville distribution in the current figure.
%
%   % Example:
%       % Create a signal that contains a Gaussian atom and a linear chirp.
%       % Display the WVD and SPWVD to visualize the signal content and the
%       % cross-terms. The XWVD of two signals x and y equals the
%       % cross-terms of the WVD of a signal s = x + y.
%       Fs = 1e3;
%       t = (0:1/Fs:1)';
%       gaussFun = @(x,mu,f) exp(-(x-mu).^2/(2*0.01^2)).*sin(2*pi*f.*x);
%       gaussAtom = gaussFun(t,0.064,100);
%       y = chirp(t(1:500),400,t(end)/2,100);
%       y = [zeros(401,1); y; zeros(100,1)]; % Zero-pad to separate signals.
%       s = gaussAtom + y;
%       figure
%       wvd(s,'smoothedPseudo')
%       % Display the Wigner-Ville. Note the cross-terms that appear
%       % between the chirp and the Gaussian atom.
%       figure
%       wvd(s)
%       % Calculate the cross-WVD.
%       figure
%       xwvd(gaussAtom,y)

%
%   See also WVD, PSPECTRUM, FSST.

%   References:
%   [1] Cohen, Leon. Time-Frequency Analysis: Theory and Applications.
%   Englewood Cliffs, NJ: Prentice-Hall, 1995.
%   [2] Mallat, Stephane. A Wavelet Tour of Signal Processing. Second
%   Edition. San Diego, CA: Academic Press, 1999.
%   [3] Malnar, Damir, Victor Sucic, and Boualem Boashash. "A cross-terms
%   geometry based method for components instantaneous frequency estimation
%   using the cross Wigner-Ville distribution." In 11th International
%   Conference on Information Sciences, Signal Processing and their
%   Applications (ISSPA), pp. 1217-1222. Montreal: IEEE, 2012.

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

narginchk(2,10);
nargoutchk(0,3);

isMATLAB = coder.target('MATLAB');
coder.extrinsic('signalwavelet.internal.wvd.displayWignerVille');

% Parse and Validate inputs
[dataOpts,opts] = parseValidateInputs(x,y,varargin{:});

% Compute XWVD
[D,F] = computeXWVD(dataOpts,opts);

T = opts.TimeVector;

if isMATLAB && ~isempty(dataOpts.InitialDate)
    % Set times to datetime format if time information is datetime.
    T = seconds(T) + dataOpts.InitialDate;
end

outputCell = cell(nargout,1);
for idx = 1:nargout
    if idx == 1
        outputCell{idx} = D;
    end
    if idx == 2
        if isa(dataOpts.XData,'single') || isa(dataOpts.YData,'single')
            outputCell{idx} = single(F);
        else
            outputCell{idx} = F;
        end
    end
    if idx == 3
        if isMATLAB && isnumeric(T) && ~isempty(dataOpts.TimeUnits)
            % Set times to duration format if time information is duration.
            T = duration(0,0,T,'Format',dataOpts.TimeUnits);
        end
        if isnumeric(T) && (isa(dataOpts.XData,'single') || isa(dataOpts.YData,'single'))
            outputCell{idx} = single(T);
        else
            outputCell{idx} = T;
        end
    end
end

[varargout{1:nargout}] = outputCell{:};

if nargout == 0
    isMEX = coder.target('MEX');
    coder.internal.errorIf(~(isMATLAB || isMEX),'shared_signalwavelet:wvd:wvd:PlottingNotSupported');
    if isMATLAB && isnumeric(T) &&  ~isempty(dataOpts.TimeUnits)
        % Set times to duration format if time information is duration.
        T = duration(0,0,T,'Format',dataOpts.TimeUnits);
    end
    % Plot the real part of the XWVD.
    funcName = 'xwvd';
    signalwavelet.internal.wvd.displayWignerVille(T,F,real(D),opts,dataOpts,funcName)
end

end % xwvd

%--------------------------------------------------------------------------
function [wvdMat,freqVec] = computeXWVD(dataOpts,opts)
% Calculate the Wigner-Ville or smoothed pseudo-Wigner-Ville distribution.

[wvdMat,freqVec] = signalwavelet.internal.wvd.xwvdImpl(dataOpts,opts);

if opts.MinThreshold > -Inf
    wvdMat(abs(wvdMat)<opts.MinThreshold) = 0;
end

if ~opts.IsNormalizedFreq
    freqVec = (opts.EffectiveFs/2)*freqVec;
end

end % computeXWVD

%--------------------------------------------------------------------------
function [dataOpts,opts] = parseValidateInputs(x,y,varargin)
% Parse and validate input parameters.

% Parse Data Signals : X & Y
dataOpts = parseInputXY(x,y);

% Parse optional input arguments
funcName = 'xwvd';
[dataOpts,opts] = signalwavelet.internal.wvd.parseOptionalInputArguments(dataOpts,funcName,varargin{:});

end

function dataOpts = parseInputXY(x,y)

isMATLAB = coder.target('MATLAB');

if isMATLAB && (istimetable(x) ~= istimetable(y))
    coder.internal.error('shared_signalwavelet:wvd:wvd:TimetableAndVectorInput');
end

% initialize the dataOpts structure arguments
timeUnits = '';
initialDate = '';

% time mode 
% 0 : "samples"
% 1 : "fs"
% 2 : "ts"
% 3 : "timetable"
timeMode = 0; % time mode : "samples"

isTimetable = false;
xRowTimes = -1;

if isMATLAB && istimetable(x)
    if (size(x,2)>1 || size(y,2)>1) % Ensure that there is only 1 timetable variable.
        coder.internal.error('shared_signalwavelet:wvd:wvd:InvalidTimeTableType');
    end
    xData = x{:,:};
    yData = y{:,:};
    validateattributes(xData,{'single','double'},...
        {'nonsparse','finite','nonnan','vector'},'xwvd','X timetable data');
    validateattributes(yData,{'single','double'},...
        {'nonsparse','finite','nonnan','vector'},'xwvd','Y timetable data');
    % Get time values. Timetable row times may be duration or datetime.
    xRowTimes = x.Properties.RowTimes;
    yRowTimes = y.Properties.RowTimes;
    if ~isequal(xRowTimes,yRowTimes)
        coder.internal.error('shared_signalwavelet:wvd:wvd:TimetableRowTimesNotEqual');
    end
    if isduration(xRowTimes)
        timeUnits = xRowTimes.Format;
    else
        timeUnits = xRowTimes.Format;
        initialDate = xRowTimes(1);
    end
    timeMode = 3; % Time Mode : "Time Table"
    isTimetable = true;
    
else
    validateattributes(x,{'single','double'},...
        {'nonsparse','finite','nonnan','vector'},'xwvd','X',1);
    validateattributes(y,{'single','double'},...
        {'nonsparse','finite','nonnan','vector'},'xwvd','Y',2);
    xData = x(:);
    yData = y(:); 
end

coder.internal.errorIf(length(xData) ~= length(yData),...
    'shared_signalwavelet:wvd:wvd:SignalLengthsNotEqual');

dataLength = size(xData,1);

coder.internal.errorIf(dataLength < 3,...
    'shared_signalwavelet:wvd:wvd:InvalidInputLength');

% Append zero too odd-length signal.
if rem(dataLength,2) ~= 0
    xData_append = [xData; zeros(1,1,'like',xData)];
    yData_append = [yData; zeros(1,1,'like',yData)];
else
    xData_append = xData;
    yData_append = yData;
end

% Ensure that the signal is analytic.
if ~any(imag(xData(:)))
    xh = hilbert(xData_append);
    xh_interpolated = [interp1(1:numel(xh),xh,1:0.5:numel(xh))'; ...
        zeros(1,1,'like',xData_append)];    
else
    xh_interpolated = [interp1(1:numel(xData_append),xData_append, ...
        1:0.5:numel(xData_append))'; zeros(1,1,'like',xData_append)];
end
if ~any(imag(yData(:)))
    yh = hilbert(yData_append);
    yh_interpolated = [interp1(1:numel(yh),yh,1:0.5:numel(yh))'; ...
        zeros(1,1,'like',yData)];    
else
    yh_interpolated = [interp1(1:numel(yData_append),yData_append, ...
        1:0.5:numel(yData_append))'; zeros(1,1,'like',yData_append)];
end
dataLength = length(xh_interpolated);

dataOpts = struct(...
                'XData'         ,xh_interpolated,...
                'YData'         ,yh_interpolated,...
                'DataLength'    ,dataLength,...
                'TimeUnits'     ,timeUnits,...
                'InitialDate'   ,initialDate,...
                'TimeMode'      ,timeMode,...
                'Type'          ,"wvd",...
                'IsTimeTable'   ,isTimetable,...
                'RowTimes'      ,xRowTimes...                
                );
            
end

% LocalWords:  Fs FWIN Nt WVD SPWVD gauss wvd PSPECTRUM FSST Englewood Mallat
% LocalWords:  Stephane Malnar Damir Sucic Boualem Boashash th ISSPA datetime
% LocalWords:  signalwavelet nonsparse nonnan XSPWVD fs
