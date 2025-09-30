function equaliseTones(subjectIDNumber, codeDir, window, screenXpixels, screenYpixels, screens)
% equaliseTones - Displays a loading screen and equalises the CAS tones.
%
% Inputs:
%   subjectIDNumber        - Numeric subject ID used during tone equalisation
%   codeDir                - Path to the base code directory (contains 'loudnessTest' folder)
%   window                 - Psychtoolbox window pointer
%   screenXpixels          - Width of the screen in pixels
%   screenYpixels          - Height of the screen in pixels
%   congratulationsTexture - Preloaded Psychtoolbox texture to display during equalisation
%
% This function adds the loudnessTest directory to the path,
% shows a loading screen, and calls equaliseCASTones for the given subject.

    % Add loudness test code to the path
    loudnessTestDir = fullfile(codeDir, 'loudnessTest');
    addpath(genpath(loudnessTestDir));
    
    % Show loading screen
    Screen('DrawTexture', window, screens.congratulationsWhileEqualising, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
    Screen('Flip', window);
    
    % Equalise the tones
    equaliseCASTones(subjectIDNumber);
end
