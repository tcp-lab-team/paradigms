function [opts, timeValue] = extractNamelessParams(inputCell,opts)
% extractNamelessParams Parser function for wvd and xwvd
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.

timeValue = [];
if ~isempty(inputCell)   
    % Look for Ts (duration) or Fs (scalar).
    value = inputCell{1};
    if isduration(value)
        timeValue = value; 
        opts.TimeMode = 'ts';
        inputCell(1) = [];
    % else % Commented b/c if inputCell{1} is a window, tv is incorrectly identified as the window vector.
    elseif isscalar(inputCell{1})
        timeValue = value;
        opts.TimeMode = 'fs';
        inputCell(1) = [];
    end
end

% Look for smoothing windows.
timeWindow = [];
freqWindow = [];
isTimeWinProvided = false; % Used for signal length checking below.
isFreqWinProvided = false;

% Smoothing windows
if ~isempty(inputCell)
    % If SPWVD, expect zero, one or two inputs.
    if strcmpi(opts.Type,'spwvd')
        if numel(inputCell) > 2
            error(message('shared_signalwavelet:wvd:wvd:IncorrectNumValueOnlyInputs'));
        end
    else
        error(message('shared_signalwavelet:wvd:wvd:IncorrectNumValueOnlyInputs'));
    end
    timeWindow = inputCell{1};
    if numel(inputCell) > 1 % If only 1 window provided, it's the time win.
        freqWindow = inputCell{2};
    end
    
    if ~isempty(timeWindow)
        validateattributes(timeWindow,{'single','double'},...
            {'vector','real','finite'},'wvd','time window');
        if length(timeWindow) < 3 || rem(length(timeWindow),2) == 0
            error(message('shared_signalwavelet:wvd:wvd:WindowLengthMustBeOdd'));
        end
        if isrow(timeWindow)
            timeWindow = timeWindow(:);
        end
        isTimeWinProvided = true;
    end
    if ~isempty(freqWindow)
        validateattributes(freqWindow,{'single','double'},...
            {'vector','real','finite'},'wvd','frequency window');
        if length(freqWindow) < 3 || rem(length(freqWindow),2) == 0
            error(message('shared_signalwavelet:wvd:wvd:WindowLengthMustBeOdd'));
        end
        if isrow(freqWindow)
            freqWindow = freqWindow(:);
        end
        isFreqWinProvided = true;
    end
    
    if length(timeWindow) > opts.DataLength || ...
            length(freqWindow) > opts.NumFrequencyPoints
        error(message('shared_signalwavelet:wvd:wvd:WindowLengthTooLarge',num2str(opts.DataLength),num2str(opts.NumFrequencyPoints)));
    end
end

% The default windows are calculated by dividing the signal length by 10
% (for the time window) and 4 (frequency). Since the signal length has 
% been doubled, check for length < 2*10.
if strcmp(opts.Type,'spwvd') && ((~isTimeWinProvided && opts.DataLength < 2*10) || ...
        (~isFreqWinProvided && opts.NumFrequencyPoints < 4))
    error(message('shared_signalwavelet:wvd:wvd:InvalidSignalLengthWithDefaultWindows'));
end

opts.TimeWindow = timeWindow;
opts.FrequencyWindow = freqWindow;

end