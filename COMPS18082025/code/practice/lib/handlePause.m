function [isPaused, keyPressed, shouldRestart] = handlePause(isPaused, pausedScreen, window, ...
    white, screenXpixels, screenYpixels, pahandle, current_script)

keyPressed = true;
shouldRestart = false;

isPaused = ~isPaused; % Toggle pause state
if isPaused
    % Show pause message
    Screen('FillRect', window, white);
    Screen('DrawTexture', window, pausedScreen, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
    Screen('Flip', window);
    WaitSecs(0.5); % Prevent auto-advancing
    
    % Wait for unpause
    while true
        [keyIsDown, ~, keyCode] = KbCheck();
        if keyIsDown && keyCode(KbName('p'))
            WaitSecs(0.5); % Prevent multiple toggles
            
            % Wait for key to be released
            while KbCheck
                WaitSecs(0.1);
            end
            
            % Clean up before restarting
            sca;
            PsychPortAudio('Stop', pahandle);
            PsychPortAudio('Close', pahandle);
            
            % Simple pause to clear any key presses
            WaitSecs(0.1);
            
            % Restart the script using its own filename
            run(current_script);
            shouldRestart = true;
            return;
        end
    end
end

end