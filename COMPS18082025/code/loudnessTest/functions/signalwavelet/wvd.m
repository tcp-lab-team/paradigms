function varargout = wvd(x,varargin)
% WVD Wigner-Ville distribution and smoothed pseudo Wigner-Ville distribution
%   D = WVD(X) returns the Wigner-Ville distribution of X. X can be a
%   vector or a timetable containing double or single precision data. The
%   length of X must be greater than two. If X is a timetable it must have
%   a single variable with a vector and must contain increasing, finite,
%   and uniformly sampled time values. D is a matrix containing a
%   time-frequency map with time along the column dimension and frequency
%   along the row dimension. By default, D is a  L-by-2L matrix where
%   L = 2*ceil(length(X)/2).
%
%   D = WVD(X,Fs) specifies Fs as a numeric scalar corresponding to the
%   sample rate of the input signal in units of hertz (Hz). This parameter
%   provides time information to the input and only applies when X is a
%   vector.
%
%   D = WVD(X,Ts) specifies Ts as a scalar duration corresponding to the
%   sample time of the input signal. This parameter provides time
%   information to the input and only applies when X is a vector.
%
%   [D,F] = WVD(...) returns frequency vector F. When the input contains
%   time information, F has units of Hz, otherwise it has units of
%   radians/sample. D has a number of rows equal to the length of F.
%
%   [D,F,T] = WVD(...) returns time vector T. When the input contains time
%   information, T contains time values. Otherwise, it contains sample
%   numbers. D has a number of columns equal to the length of T.
%
%   [...] = WVD(...,'smoothedPseudo') returns the smoothed pseudo Wigner-
%   Ville distribution of X. WVD uses the length of the signal to choose
%   the lengths of Kaiser windows that are used for smoothing in time and
%   frequency.
%
%   [...] = WVD(...,'smoothedPseudo',TWIN,FWIN) specifies the windows
%   TWIN and FWIN as the time and frequency windows, respectively. TWIN and
%   FWIN must be numeric vectors. TWIN or FWIN may be omitted by providing
%   the empty matrix [], which indicates that WVD will use the length of
%   the signal to choose the length of a Kaiser window that will be used
%   for smoothing in that dimension. The default length of TWIN is the
%   smallest odd integer that is greater than or equal to 2*L/10, where
%   L = 2*ceil(length(X)/2). The default length of FWIN is the smallest odd
%   integer that is greater than or equal to L/4.
%
%   [...] = WVD(...,'smoothedPseudo','NumFrequencyPoints',Nf) sets the
%   number of frequency points to Nf. This parameter controls the degree of
%   oversampling in frequency and may only be provided when the smoothed
%   pseudo Wigner-Ville distribution is calculated. The smoothed pseudo
%   Wigner-Ville matrix output D has size Nf in the frequency direction. Nf
%   must lie in the range ceil((length(FWIN)+1)/2) <= Nf < length(X).
%   The default value of Nf is length(X).
%
%   [...] = WVD(...,'smoothedPseudo','NumTimePoints',Nt) sets the number of
%   time points to Nt. This parameter controls the degree of oversampling
%   in time and may only be provided when the smoothed pseudo Wigner-Ville
%   distribution is calculated. The smoothed pseudo Wigner-Ville matrix
%   output D has size Nt in the time direction. Nt must be an even integer
%   and must lie in the range 2*length(TWIN) <= Nt < 2*length(X). The
%   default value of Nt is 2*length(X).
%
%   [...] = WVD(...,'MinThreshold',THRESH) sets the elements of D to zero
%   when their amplitudes are less than THRESH. Specify THRESH as a numeric
%   scalar. If 'MinThreshold' is not specified, it defaults to -Inf.
%
%   WVD(...) with no output arguments plots the Wigner-Ville distribution
%   in the current figure.
%
%   % Example 1:
%       % Compute the WVD of a linear chirp stored in a timetable. The WVD
%       % is well-suited for mono-component signals.
%       Fs = 1000;
%       t = (0:1/Fs:0.5)';
%       x = chirp(t,50,1,250);
%       xt = timetable(seconds(t), x);
%       wvd(xt)
%
%   % Example 2:
%       % Calculate the WVD of a signal formed by four Gaussian atoms.
%       % Interference terms, which can have negative values, appear
%       % half-way between each pair of auto-terms.
%       Fs = 1000;
%       t = (0:1/Fs:0.5)';
%       mu1 = 0.15;
%       mu2 = 0.35;
%       f1 = 100;
%       f2 = 400;
%       gaussFun = @(A,x,mu,f) exp(-(x-mu).^2/(2*0.01^2)).*sin(2*pi*f.*t)*A';
%       s = gaussFun([1 1 1 1],t,[mu1 mu1 mu2 mu2],[f1 f2 f1 f2]);
%       wvd(s,Fs)
%
%   % Example 3:
%       % Calculate the smoothed pseudo WVD of a signal formed by four
%       % Gaussian atoms. Smoothing in time and frequency attenuates the
%       % interference terms.
%       Fs = 1000;
%       t = (0:1/Fs:0.5)';
%       mu1 = 0.15;
%       mu2 = 0.35;
%       f1 = 100;
%       f2 = 400;
%       gaussFun = @(A,x,mu,f) exp(-(x-mu).^2/(2*0.01^2)).*sin(2*pi*f.*t)*A';
%       s = gaussFun([1 1 1 1],t,[mu1 mu1 mu2 mu2],[f1 f2 f1 f2]);
%       wvd(s,Fs,'smoothedPseudo')
%
%   See also PSPECTRUM, FSST.

%   References:
%   [1] O'Toole, John M., and Boualem Boashash. "Fast and memory-efficient
%   algorithms for computing quadratic time-frequency distributions."
%   Applied and Computational Harmonic Analysis. Vol. 35, No. 2, pp.
%   350-358.
%   [2] Cohen, Leon. Time-Frequency Analysis: Theory and Applications.
%   Englewood Cliffs, NJ: Prentice-Hall, 1995.
%   [3] Mallat, Stephane. A Wavelet Tour of Signal Processing. Second
%   Edition. San Diego, CA: Academic Press, 1999.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

narginchk(1,11);
nargoutchk(0,3);

isMATLAB = coder.target('MATLAB');
coder.extrinsic('signalwavelet.internal.wvd.displayWignerVille');

inputArgs = cell(size(varargin));
% Gather all extra arguments
if nargin > 1
    [inputArgs{:}] = gather(varargin{:});
else
    inputArgs = varargin;
end

% Parse and validate the inputs
[dataOpts,opts] = parseValidateInputs(x,inputArgs{:});

% Compute wvd
[D,F]  = computeWVD(dataOpts,opts);
T = cast(opts.TimeVector,'like',real(D([])));

if isMATLAB && ~isempty(dataOpts.InitialDate)
    % Set times to datetime format if time information is datetime.
    T = seconds(gather(T)) + dataOpts.InitialDate;
end

outputCell = cell(nargout,1);
for idx = 1:nargout
    if idx == 1
        outputCell{idx} = D;
    end
    if idx == 2
        outputCell{idx} = F;
    end
    if idx == 3
        if isMATLAB && isnumeric(T) && ~isempty(dataOpts.TimeUnits)
            % Set times to duration format if time information is duration.
            T = duration(0,0,gather(T),'Format',dataOpts.TimeUnits);
        end
        outputCell{idx} = T;
    end
end

[varargout{1:nargout}] = outputCell{:};

if nargout == 0
    isMEX = coder.target('MEX');
    coder.internal.errorIf(~(isMATLAB || isMEX),'shared_signalwavelet:wvd:wvd:PlottingNotSupported');    
    if (isMATLAB) && isnumeric(T) && ~isempty(dataOpts.TimeUnits)
            % Set times to duration format if time information is duration.
            T = duration(0,0,gather(T),'Format',dataOpts.TimeUnits);
    end
    funcName = 'wvd';
    signalwavelet.internal.wvd.displayWignerVille(gather(T),gather(F),gather(D),opts,dataOpts,funcName);
end

end
% wvd

%--------------------------------------------------------------------------
function [wvdMat,freqVec] = computeWVD(dataOpts,opts)
% Calculate the Wigner-Ville or smoothed pseudo-Wigner-Ville distribution.

[wvdMat,freqVec] = signalwavelet.internal.wvd.wvdImpl(dataOpts,opts);

if opts.MinThreshold > -Inf
    wvdMat(wvdMat<opts.MinThreshold) = 0;
end

if ~opts.IsNormalizedFreq
    freqVec = (opts.EffectiveFs/2)*freqVec;
end

end
% computeWVD

%--------------------------------------------------------------------------
function [dataOpts,opts] = parseValidateInputs(x,varargin)
% Parse and validate input parameters.

% Parse data signal X
dataOpts = parseInputX(x);

% Parse Optional Input arguments
funcName = 'wvd';
[dataOpts,opts] = signalwavelet.internal.wvd.parseOptionalInputArguments(dataOpts,funcName,varargin{:});

end
% parseAndValidateInputs

function dataOpts = parseInputX(x)
% Construct the data structure: dataOpts

isMATLAB = coder.target('MATLAB');

% Initialize the dataOpts structure arguments:
timeUnits     = '';
initialDate   = '';

% time mode
% 0 : "samples"
% 1 : "fs"
% 2 : "ts"
% 3 : "timetable"
timeMode = 0; % timemode "samples"
isTimetable = false;
rowTimes = -1;

if isMATLAB && istimetable(x)
    if size(x,2) > 1 % Ensure that there is only 1 timetable variable.
        coder.internal.error('shared_signalwavelet:wvd:wvd:InvalidTimeTableType');
    end
    data = x{:,:};
    validateattributes(data,{'single','double'},...
        {'nonsparse','finite','nonnan','vector'},'wvd','timetable data',1);
    % Get time values. Timetable row times may be duration or datetime.
    rowTimes = x.Properties.RowTimes;
    if isduration(rowTimes)
        timeUnits   = rowTimes.Format;
    else
        timeUnits   = rowTimes.Format;
        initialDate = rowTimes(1);
    end
    timeMode = 3; % time mode : "Time table"
    isTimetable = true;
else
    validateattributes(x,{'single','double'},...
        {'nonsparse','finite','nonnan','vector'},'wvd','X',1);
    if isrow(x)
        data = x(:);
    else
        data = x;
    end
end

dataLength = size(data,1);
coder.internal.errorIf(dataLength < 3,'shared_signalwavelet:wvd:wvd:InvalidInputLength');

% Append zero to odd-length signal.
if rem(dataLength,2) ~= 0
    data_append = [data; zeros(1,1,'like',data)];
else
    data_append = data;
end
dataLength = 2*length(data_append);

% Ensure that the signal is analytic.
if ~any(imag(data_append(:)))
    data_h = hilbert(data_append,2*length(data_append));
    data_h(length(data_h)/2 + 1 : end) = 0;
else
    data_h = [data_append; zeros(size(data_append),'like',data_append)];
end

dataOpts = struct(...
    'Data'          ,data_h,...
    'DataLength'    ,dataLength,...
    'TimeUnits'     ,timeUnits,...
    'InitialDate'   ,initialDate,...
    'TimeMode'      ,timeMode,...
    'Type'          ,"wvd",...
    'IsTimeTable'   ,isTimetable,...
    'RowTimes'      ,rowTimes...
    );
end

% LocalWords:  Fs FWIN Nt xt gauss PSPECTRUM FSST Boualem Boashash Englewood fs
% LocalWords:  Mallat Stephane datetime signalwavelet nonsparse nonnan ttab
% LocalWords:  xwvd SPWVD timemode
