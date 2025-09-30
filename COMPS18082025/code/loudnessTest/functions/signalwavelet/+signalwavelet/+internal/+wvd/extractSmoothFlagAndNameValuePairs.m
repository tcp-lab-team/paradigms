function [opts,inputCell] = extractSmoothFlagAndNameValuePairs(inputCell, opts)
%extractSmoothFlagAndNameValuePairs Parser function for wvd and xwvd
%   For internal use only. 
    
%   Copyright 2018 MathWorks, Inc.

% Use strings for string support
validStrings = ["smoothedPseudo","NumTimePoints","NumFrequencyPoints","MinThreshold"];
removeIdx = [];

if ~isempty(inputCell)
    for idx = 1:numel(inputCell)
        if (isstring(inputCell{idx}) && isscalar(inputCell{idx})) || ischar(inputCell{idx})
            try
                str = validatestring(inputCell{idx},validStrings);
            catch
                error(message('shared_signalwavelet:wvd:wvd:InvalidInputStringName'));
            end
            
            switch str
                case "smoothedPseudo"
                    removeIdx = [removeIdx idx]; %#ok<AGROW>
                    opts.Type = 'spwvd';
                case {"NumTimePoints","NumFrequencyPoints","MinThreshold"}
                    if numel(inputCell) > idx
                        if isempty(inputCell{idx+1})
                            error(message('shared_signalwavelet:wvd:wvd:PairNameValueInputsNonEmpty'));
                        end
                        opts.(str) = inputCell{idx+1};
                        removeIdx = [removeIdx,idx,idx+1]; %#ok<AGROW>
                    else
                        error(message('shared_signalwavelet:wvd:wvd:OversamplingWithWVD'));
                    end
            end            
        end
    end
end
inputCell(removeIdx) = [];

if (~isempty(opts.NumTimePoints) || ~isempty(opts.NumFrequencyPoints)) && ...
        strcmp(opts.Type,'wvd')
    error(message('shared_signalwavelet:wvd:wvd:OversamplingWithWVD'));
end

if isempty(opts.NumTimePoints) 
    opts.NumTimePoints = opts.DataLength;
else
    isCrossWVD = isfield(opts,'XData');
    if isCrossWVD
        error(message('shared_signalwavelet:wvd:wvd:OversamplingWithXWVD'));
    end
    validateattributes(opts.NumTimePoints,{'numeric'},{'integer','even','positive','scalar','nonempty','>',2},...
        'wvd','NumTimePoints');
    opts.NumTimePoints = double(opts.NumTimePoints);    
end

if isempty(opts.NumFrequencyPoints) 
    opts.NumFrequencyPoints = floor(opts.DataLength)/2;
else
    validateattributes(opts.NumFrequencyPoints,{'numeric'},{'integer','positive','scalar','nonempty','>',2},...
        'wvd','NumFrequencyPoints');
    opts.NumFrequencyPoints = double(opts.NumFrequencyPoints);    
end

if isempty(opts.MinThreshold)
    opts.MinThreshold = -Inf;
else
    validateattributes(opts.MinThreshold,{'numeric'},{'scalar','nonempty'},...
        'wvd','MinThreshold');
    opts.MinThreshold = double(opts.MinThreshold);        
end

end