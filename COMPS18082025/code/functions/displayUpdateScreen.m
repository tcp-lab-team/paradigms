function percentComplete = displayUpdateScreen(window, screens, points, screenXpixels, screenYpixels, ...
    i, numImagesInSequence, percentComplete, imageSequence, subjectIDNumberConverted, youScored)
    % displayUpdateScreen shows an update screen if subject is 25%, 50%, or
    % 75% of the way through the experiment; or if the subject scored/missed a
    % point as feedback.
    
    % Check if there was a distractor in last quartet 
    thereWasADistractorInQuartet = sum(imageSequence.isDistractor(i-3:i, subjectIDNumberConverted)) > 0; % Checks last 4 images for distractor

    % Check if you scored in last quartet 
    didYouScore = sum(youScored(i-3:i)) > 0; % Checks last 4 youScored values for whether you scored
    
    % Check if we're at end of trial (we only show percentage progress
    % updates at end of trial)
    if i < numImagesInSequence
        isEndOfTrial = ~strcmp(imageSequence.trialType(i, subjectIDNumberConverted), imageSequence.trialType(i+1, subjectIDNumberConverted));
    else
        isEndOfTrial = true;
    end
    
    % Show feedback if the current image is a distractor and score has been updated
    if thereWasADistractorInQuartet && didYouScore == true
        displayScreenWithPoints(window, screens.fixationCrossYouGotIt, points, screenXpixels, screenYpixels);
    
    elseif thereWasADistractorInQuartet && didYouScore == false
        displayScreenWithPoints(window, screens.fixationCrossYouMissed, points, screenXpixels, screenYpixels);
        
    % Check if we are 25% of the way through the experiment
    elseif i >= numImagesInSequence * 0.25 && percentComplete.twentyFive == false && isEndOfTrial
        displayScreenWithPoints(window, screens.fixationCross25Percent, points, screenXpixels, screenYpixels);
        percentComplete.twentyFive = true; % Update the 25% completion flag
        
    % Check if we are 50% of the way through the experiment
    elseif i >= numImagesInSequence * 0.5 && percentComplete.fifty == false && isEndOfTrial
        displayScreenWithPoints(window, screens.fixationCross50Percent, points, screenXpixels, screenYpixels);
        percentComplete.fifty = true; % Update the 50% completion flag
        
    % Check if we are 75% of the way through the experiment
    elseif i >= numImagesInSequence * 0.75 && percentComplete.seventyFive == false && isEndOfTrial
        displayScreenWithPoints(window, screens.fixationCross75Percent, points, screenXpixels, screenYpixels);
        percentComplete.seventyFive = true; % Update the 75% completion flag
    end