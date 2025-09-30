function showFinalScore(window, points, imageSequence, subjectIDNumberConverted, white, black)
    % Count number of distractors (trials where trialType is "distractor")
    numDistractors = sum(imageSequence.isDistractor(:, subjectIDNumberConverted) == true);

    % Get screen size
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);

    % Create final score text
    finalScoreText = sprintf('You scored: %d / %d', points, numDistractors);

    % Fill screen with white
    Screen('FillRect', window, white);

    % Make text larger
    Screen('TextSize', window, 100);

    % Get text bounds to center it properly
    [textBounds, ~] = Screen('TextBounds', window, finalScoreText);
    textWidth = textBounds(3) - textBounds(1);
    textHeight = textBounds(4) - textBounds(2);

    % Calculate position to center text
    xPos = (screenXpixels - textWidth) / 2;
    yPos = (screenYpixels - textHeight) / 2;

    % Draw the text
    Screen('DrawText', window, finalScoreText, xPos, yPos, black);
    Screen('Flip', window);

    % Wait for 3 seconds before closing
    WaitSecs(3);
end
