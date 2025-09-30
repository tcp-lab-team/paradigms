function showStayStillScreen(window, screenXpixels, screenYpixels, black, photodiodeRect, screens)
    % showStayStillScreen Displays a "stay still" screen and waits for spacebar press.
    %
    % Inputs:
    %   currentDir    - base directory containing instructions folder
    %   window         - Psychtoolbox window pointer
    %   screenXpixels  - screen width in pixels
    %   screenYpixels  - screen height in pixels
    %   black          - black color index for the screen
    %   photodiodeRect - rect for photodiode area

    Screen('DrawTexture', window, screens.stayStill, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
    Screen('FillRect', window, black, photodiodeRect); % Add black photodiode rectangle
    Screen('Flip', window);

    waitForSpacebar();
end
