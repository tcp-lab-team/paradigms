function [allResponses, points, keyPressed, escapeKeyPressed, youScored, numResponses] = ...
    checkKeyPress(keyIsDown, keyCode, keyPressed, escapeKeyPressed, allResponses, numResponses, points, ...
    window, photodiodeRect, dstRect, experimentStartTime, i, subjectIDNumberConverted, ...
    distractorOnsetTime, reactionTimeWindow, youScored, resizedImages, whichImage, imageSequence, black)

% checkKeyPress checks which keys have been pressed during the experiment trial.
%
% Inputs:
%   keyPressed           - Flag if key has already been processed (logical)
%   isPaused             - Flag if experiment is currently paused (logical)
%   repeatExercise       - Flag controlling outer loop continuation (logical)
%   numResponses         - Number of responses recorded so far (integer)
%   current_filename     - Filename of current image (string)
%   trialTypeNames       - Cell array of trial type names
%   subjectIDnumberConverted - Numeric subject ID
%   current_order        - Numeric vector representing trial sequence
%   points               - Current points scored (integer)
%   j                    - Current stimulus index in trial (integer)
%   canScore             - Vector indicating if current stimulus can be scored
%   window               - Psychtoolbox window pointer
%   photodiodeRect       - Rectangle for photodiode area
%   screenXpixels        - Screen width in pixels
%   screenYpixels        - Screen height in pixels
%   pausedScreen         - Texture for pause screen image
%   current_image        - Current image matrix
%   dstRect              - Destination rectangle for image on screen
%   imageData            - Struct with image onset times
%   experimentStartTime  - Experiment start timestamp (GetSecs)
%   i                    - Current trial number
%   pahandle             - PsychPortAudio handle
%   mode                 - Experiment mode string
%   io                   - IO64 object for triggers
%   port                 - Trigger port address
%   data                 - Data struct with auditoryTriggerList
%   triggerDuration      - Duration to hold trigger
%   current_script       - Filename of current script for restarting
%
% Outputs:
%   allResponseTimes     - Updated struct with response data
%   points               - Updated points total
%   keyPressed           - Updated key pressed flag
%   isPaused             - Updated pause flag
%   repeatExercise       - Updated repeat exercise flag (false if ESC pressed)

% % Assign default values
% numResponses = numResponses;
% points       = points;
% youScored    = youScored;
% allResponses = allResponses;

if keyIsDown && keyCode(KbName('1!')) % Check if "1" key pressed
    
    numResponses = numResponses + 1;
    
    % Record response data
    allResponses.imageFileName{numResponses} = imageSequence.fileName(i, subjectIDNumberConverted);;
    allResponses.trialType{numResponses} = imageSequence.trialType(i, subjectIDNumberConverted);
    allResponses.trialSequenceNumeric{numResponses} = imageSequence.numericSequence(i, subjectIDNumberConverted);
    allResponses.trialSequenceAlphabetic{numResponses} = imageSequence.alphabeticSequence(i, subjectIDNumberConverted);;
    allResponses.globalTime(numResponses) = GetSecs - experimentStartTime;
    allResponses.machineGlobalTime(numResponses) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    allResponses.trialNumber(numResponses) = imageSequence.trialNumber(i, subjectIDNumberConverted);
    allResponses.reactionTime(numResponses) = (GetSecs - experimentStartTime) -  distractorOnsetTime;
    allResponses.imageNumber(numResponses) = i;
    
    
    if (GetSecs - experimentStartTime) - distractorOnsetTime <= reactionTimeWindow && (GetSecs - experimentStartTime) - distractorOnsetTime >= 0 && youScored(i) == false % If subject responds within reaction time window and they haven't already scored this a point for this distractor
        
        points = points + 1;
        youScored(i) = true;
        allResponses.correct(numResponses) = 1;
        
    else
        points = max(points - 1, 0);
        allResponses.correct(numResponses) = 0;
        
    end
    keyPressed = true;
    
    % Draw updated points and current image
    drawPoints(window, points);
    imageToTexture = Screen('MakeTexture', window, resizedImages.image{whichImage});
    Screen('DrawTexture', window, imageToTexture, [], dstRect, 0, [], 1);
    Screen('FillRect', window, black, photodiodeRect);
    Screen('Flip', window); % Flip the screen to display the image
    
    %     elseif keyCode(KbName('CAPSLOCK')) % Pause/unpause toggle
    %         isPaused = ~isPaused;
    %         if isPaused
    %             Screen('FillRect', window, 1); % fill with white (1)
    %             Screen('DrawTexture', window, pausedScreen, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
    %             Screen('Flip', window);
    %             WaitSecs(0.5);
    %
    %             % Wait for unpause CAPSLOCK press
    %             while true
    %                 [kDown, ~, kCode] = KbCheck();
    %                 if kDown && kCode(KbName('CAPSLOCK'))
    %                     WaitSecs(0.5);
    %                     while KbCheck
    %                         WaitSecs(0.1);
    %                     end
    %                     sca;
    %                     PsychPortAudio('Stop', pahandle);
    %                     PsychPortAudio('Close', pahandle);
    %                     WaitSecs(0.1);
    %                     run(current_script);
    %                     return;
    %                 end
    %             end
    %         end
    %         keyPressed = true;
    
elseif keyIsDown && keyCode(KbName('ESCAPE'))
    escapeKeyPressed = true;
    keyPressed   = true;
    return;
    
else
    keyPressed = true;
    return;
end
[keyIsDown, ~, keyCode] = KbCheck(); % Update key state for loop condition
