function displayNotPressedScreen(window, screenXpixels, screenYpixels)
    % displayNotPressedScreen Displays the unpressed screen image on the specified window
    %
    %   Inputs:
    %       window         - Window handle for the Psychtoolbox window
    %       screenXpixels  - Screen width in pixels
    %       screenYpixels  - Screen height in pixels
    %
    % This function loads and displays the pressed screen image ('pressed.jpg').

    % Set the file path for the pressed image
    not_pressed_location = fullfile('hearing_test', 'not_pressed.jpg');
    
    % Check if the image file exists
    if ~isfile(not_pressed_location)
        error('The image file "not_pressed.jpg" does not exist at the specified location.');
    end
    
    % Read the image
    not_pressed_image = imread(not_pressed_location);
    
    % Create a texture from the image
    not_pressed_texture = Screen('MakeTexture', window, not_pressed_image);
    
    % Draw the texture to the screen, scaled to full screen size
    Screen('DrawTexture', window, not_pressed_texture, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
    
    % Flip the screen to display the texture
    Screen('Flip', window);
end
