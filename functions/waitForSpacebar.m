function waitForSpacebar()
    % Wait until the spacebar is pressed
    while true
        % Check the keyboard state
        [keyIsPressed, ~, keyCode] = KbCheck;
        
        % If the right arrow key is pressed, exit the loop
        if keyIsPressed && keyCode(KbName('space'))
            KbReleaseWait % Wait for button to be released, otherwise button press will carry over to the next slide
            break; % Exit the loop when right arrow is pressed
        end
    end
end
