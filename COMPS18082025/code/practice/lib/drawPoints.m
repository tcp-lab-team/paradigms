function drawPoints(window, points)
    % Define the position for the text
    xPos = 10; % X position
    yPos = 10; % Y position

    % Create the text string
    pointsText = sprintf('Points: %d', points);
    
    % Draw the text on the screen
    Screen('DrawText', window, pointsText, xPos, yPos, BlackIndex(window));
end