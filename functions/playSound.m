function auditoryData = playSound(t, subjectIDNumberConverted, auditorySequence, pahandle, sounds, mode, io, port, triggerDuration, auditoryData, experimentStartTime)
% playSound Plays the auditory stimulus and sends MEG trigger if applicable.
%
% Inputs:
%   t                         - Trial number/index
%   subjectIDnumberConverted  - Numeric subject ID
%   auditorySequence          - Structure or object with .sound method/field
%   pahandle                  - PsychPortAudio handle
%   sounds                    - Cell array of sound waveforms
%   mode                      - String indicating mode ('meg' or other)
%   io                        - IO64 object for triggering (if mode == 'meg')
%   port                      - Port address for trigger
%   data                      - Data struct with auditoryTriggerList
%   triggerDuration           - Duration to hold the trigger

    % Get correct sound from sequence this trial
    whichSound = auditorySequence.sound(t, subjectIDNumberConverted);

    % Play sound file
    PsychPortAudio('FillBuffer', pahandle, sounds{whichSound});
    PsychPortAudio('Start', pahandle, 1, 0, 1);

    % Send MEG trigger if in meg mode
    if strcmp(mode, 'meg')
        io64(io, port, auditorySequence.trigger(t, subjectIDNumberConverted));
        WaitSecs(triggerDuration);
        io64(io, port, 0);
    end
    
    % Record auditory data
    auditoryData.onsetTime(t) = GetSecs - experimentStartTime;
    auditoryData.machineOnsetTime(t) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    auditoryData.trialNumber(t) = t;
    auditoryData.trialType(t) = auditorySequence.sound(t, subjectIDNumberConverted); % Ttype of auditory trial. For ASSR and CAS, there is only one type = "1". For P50, there's "1" and "2" for 1st and 2nd click. Then for MMN, there's "1" and "2" for standard and deviant tones.
    
end
