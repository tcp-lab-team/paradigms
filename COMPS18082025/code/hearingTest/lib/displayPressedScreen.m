function displayPressedScreen(window, screenXpixels, screenYpixels)
    % displayPressedScreen Displays the pressed screen image on the specified window
    %
    %   Inputs:
    %       window         - Window handle for the Psychtoolbox window
    %       screenXpixels  - Screen width in pixels
    %       screenYpixels  - Screen height in pixels
    %
    % This function loads and displays the pressed screen image ('pressed.jpg').

    % Set the file path for the pressed image
    pressed_location = fullfile('hearing_test', 'pressed.jpg');
    
    % Check if the image file exists
    if ~isfile(pressed_location)
        error('The image file "pressed.jpg" does not exist at the specified location.');
    end
    
    % Read the image
    pressed_image = imread(pressed_location);
    
    % Create a texture from the image
    pressed_texture = Screen('MakeTexture', window, pressed_image);
    
    % Draw the texture to the screen, scaled to full screen size
    Screen('DrawTexture', window, pressed_texture, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
    
    % Flip the screen to display the texture
    Screen('Flip', window);
end
