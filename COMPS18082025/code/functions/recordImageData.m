function imageData = recordImageData(imageData, i, experimentStartTime, ...
                                     subjectIDNumberConverted, imageSequence)
% recordImageData Records timing and metadata for a presented image.
%
% Inputs:
%   imageData               - Struct storing image trial data
%   i                       - Current trial number
%   experimentStartTime     - Time when the experiment started (from GetSecs)
%   currentOrder            - Current randomized image order (1x4 vector)
%   quartetFilenames        - Cell array of filenames, size [nTrials x 4]
%   trialTypeNames          - Cell array of trial type labels
%   subjectIDNumberConverted- Numeric subject ID
%
% Output:
%   imageData               - Updated struct with new trial image info

    % Record timestamps
    imageData.onsetTime(i) = GetSecs - experimentStartTime;
    imageData.machineOnsetTime(i) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

    % Record file and trial metadata    
    imageData.fileName{i} = imageSequence.fileName(i, subjectIDNumberConverted);
    imageData.trialNumber(i) = imageSequence.trialNumber(i, subjectIDNumberConverted);
    imageData.imageNumber(i) = imageSequence.imageNumberWithinTrial(i, subjectIDNumberConverted);
    imageData.trialType{i} = imageSequence.trialType(i, subjectIDNumberConverted);
    imageData.trialSequenceNumeric{i} = imageSequence.numericSequence(i, subjectIDNumberConverted);
    imageData.trialSequenceAlphabetic{i} = imageSequence.alphabeticSequence(i, subjectIDNumberConverted);
end
