function opts = validateTimeParams(opts,istimetableFlag,timeValue,ttTimeVector)
%validateTimeParams  Parser function for wvd and xwvd
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.

% Validate time inputs.
switch opts.TimeMode
    case 'fs'
        if istimetableFlag
            error(message('shared_signalwavelet:wvd:wvd:SampleRateAndTimetableInput'));
        end
        validateattributes(timeValue,{'numeric'}, ...
            {'scalar','real','finite','positive'},'wvd','sample rate');
        opts.EffectiveFs = double(timeValue);
        % Multiply time vector by 1/2 to account for doubled signal length.
        opts.TimeVector = 0.5*(0:opts.NumTimePoints-1).'/opts.EffectiveFs;
    case 'ts'
        if istimetableFlag
            error(message('shared_signalwavelet:wvd:wvd:SampleRateAndTimetableInput'));
        end
        validateattributes(timeValue,{'duration'},{'scalar'},...
            'wvd','sample time');
        opts.EffectiveFs = 1/seconds(timeValue);
        % Multiply time vector by 1/2 to account for doubled signal length.
        opts.TimeVector = 0.5*(0:opts.NumTimePoints-1).'/opts.EffectiveFs;
        opts.TimeUnits = timeValue.Format;
    case 'samples'
        opts.EffectiveFs = 2;
        % Multiply time vector by 1/2 to account for doubled signal length.
        opts.TimeVector = 0.5*(0:opts.NumTimePoints-1).';
        opts.IsNormalizedFreq = true;
end

if istimetableFlag
    timeVector = ttTimeVector(:);
    validateattributes(timeVector,{'numeric'},{'column','nonnan','finite'},...
        'wvd','time values');
    if length(timeVector) ~= length(unique(timeVector))
        error(message('shared_signalwavelet:wvd:wvd:TimeValuesUnique'));
    end
    if ~issorted(timeVector)
        error(message('shared_signalwavelet:wvd:wvd:TimeValuesIncreasing'));
    end
    err = max(abs(timeVector(:).'-linspace(timeVector(1),timeVector(end),numel(timeVector)))./max(abs(timeVector)));
    needsResampling = err > 3*eps(class(timeVector));
    if needsResampling
        error(message('shared_signalwavelet:wvd:wvd:NonuniformlySampledTimeValues'));
    end
    opts.EffectiveFs = 1 / median(diff(timeVector));
    opts.TimeVector = 0.5*(0:opts.NumTimePoints-1).'/opts.EffectiveFs;
end

end