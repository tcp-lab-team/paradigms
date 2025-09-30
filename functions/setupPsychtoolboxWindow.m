function [window, windowRect, screenXpixels, screenYpixels, ifi, white, black, photodiodeRect] = setupPsychtoolboxWindow(mode)
    % Set up Psychtoolbox defaults and open screen window
    
    PsychDefaultSetup(2);

    if strcmp(mode, 'debug')
        PsychDebugWindowConfiguration(0, 0.5);
    end

    % Get available screens and use the external one if present
    screens = Screen('Screens');
    screenNumber = max(screens);

    % Define white and black based on luminance range
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);

    % Optionally skip sync tests (for development use only)
    Screen('Preference', 'SkipSyncTests', 1);

    % Open the window
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

    % Get screen dimensions
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);

    % Get frame duration
    ifi = Screen('GetFlipInterval', window);

    % Enable alpha blending for smooth rendering
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Set default text properties
    Screen('TextFont', window, 'Ariel');
    Screen('TextSize', window, 36);

    % Hide cursor and flip blank screen
    HideCursor(window);
    Screen('Flip', window);

    % Photodiode rectangle in bottom-left corner
    [~, wHeight] = Screen('WindowSize', window);
    photodiodeW = 50;
    photodiodeRect = [0, wHeight - photodiodeW, photodiodeW, wHeight];
end
