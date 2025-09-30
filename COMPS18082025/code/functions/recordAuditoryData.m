function auditoryData = recordSoundData(t, experimentStartTime, auditoryData, subjectIDNumberConverted)
% recordSoundData Records the timing and trial info for auditory stimulus.
%
% Inputs:
%   t                   - Trial number/index
%   experimentStartTime  - Timestamp of experiment start (GetSecs)
%   auditoryData        - Struct to store onset times, etc.
%
% Output:
%   auditoryData        - Updated struct with recorded timings and trial number

    auditoryData.onsetTime(t) = GetSecs - experimentStartTime;
    auditoryData.machineOnsetTime(t) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    auditoryData.trialNumber(t) = t;
    auditoryData.trialType = auditorySequence.sound(t, subjectIDNumberConverted);

end
