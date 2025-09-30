function screens = preloadScreens(window, codeDir)
% loadInstructionScreens loads all instruction-related textures.
%
% Inputs:
%   window     - Psychtoolbox window pointer
%   currentDir - Path to the experiment's root directory
%
% Output:
%   screens    - Struct containing all loaded instruction screens as textures

    screensDir = fullfile(codeDir, 'screens');

    % Load each screen texture using your imageFileToTexture helper
    screens.fixationCross = imageFileToTexture(window, fullfile(screensDir, 'FixationCross.jpg'));
    screens.fixationCrossYouMissed = imageFileToTexture(window, fullfile(screensDir, 'FixationCrossYouMissed.jpg'));
    screens.fixationCrossYouGotIt = imageFileToTexture(window, fullfile(screensDir, 'FixationCrossYouGotIt.jpg'));
    screens.fixationCross25Percent = imageFileToTexture(window, fullfile(screensDir, 'FixationCross25PercentComplete.jpg'));
    screens.fixationCross50Percent = imageFileToTexture(window, fullfile(screensDir, 'FixationCross50PercentComplete.jpg'));
    screens.fixationCross75Percent = imageFileToTexture(window, fullfile(screensDir, 'FixationCross75PercentComplete.jpg'));
    screens.paused = imageFileToTexture(window, fullfile(screensDir, 'paused.jpg'));
    screens.canYouHear = imageFileToTexture(window, fullfile(screensDir, 'canYouHear.jpg'));
    screens.fixingAudio = imageFileToTexture(window, fullfile(screensDir, 'fixingAudio.jpg'));
    screens.stayStill = imageFileToTexture(window, fullfile(screensDir, 'stayStill.jpg'));
    screens.waitForAudio = imageFileToTexture(window, fullfile(screensDir, 'waitForAudio.jpg'));
    screens.congratulationsWhileEqualising = imageFileToTexture(window, fullfile(screensDir, 'congratulationsWhileEqualising.jpg'));
    
end
