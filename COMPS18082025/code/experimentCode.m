%% CLEAR WORKSPACE

close all;
clearvars
dbstop error

%% PATHS

addpath('functions');
[codeDir, COMPSDir] = setupPaths();

%% FIL & TRIGGER SET UP

% Work out which device we're on (i.e. are we on Daniel's
% laptop or in the FIL/testroom), so we can adjust settings accordingly

[~, hostname] = system('hostname');
hostname = strtrim(hostname); % Remove random trailing whitespace

% Change setup depending on device

if contains(hostname, 'meg', 'Ignorecase', true) % If we're in the actual MEG ROOM
    mode = 'meg'; % Turns the triggers on
    device_id = []; % Switches audio device output to FIL audio output
elseif contains(hostname, 'stimulus', 'Ignorecase', true) % If we're in the FIL TEST ROOM
    mode = 'meg'; % Turns the triggers on
    device_id = []; % Switches audio device output to test room audio output
else % If we're on a non-FIL device
    mode = 'debug'; % Switches off the triggers so code runs on non-FIL device
    device_id = []; % Switches audio device output to non-FIL audio output
end

if strcmp(mode,'meg') % Turn on triggers for meg mode
    warning('Running in MEG mode! Triggers will be send.');
    port = hex2dec('3ff8');                         % !!! check the port address in device manager !!!
    onset = 99;                        % three trial types
    offset = 0;                                     % for resetting the port and marking the offset
    io   = io64;                                      % create parallel port object
    status = io64(io);                              % check status of parallel port
    assert(status==0,'Parallel port not opened.');
    io64(io, port, 0); % Send offset trigger to ensure all pins are zeroed
else % If not in the meg mode, don't send triggers
    warning('Running in test mode. No triggers will be send!!!');
    io = []; 
    port = [];
end

%% TRIGGER INFO

% Start,end & pause triggers
% 254 = when the experimental block starts
% 255 = when the experimental block ends
% 100 = when experiment is paused
% 200 = when experiment is unpaused

% P50 triggers 
% 51 = when the first click plays
% 52 = when the second click plays

% ASSR triggers 
% 60 = when a clicktrain plays

% Oddball MMN 
% 70 = when a standard tone plays
% 71 = when a deviant tone plays

% CAS
% 80 = when a CAS tone is played

%% PARAMETERS

% Add paradigm pass from GUI
load('paradigm.mat')

% Get subject ID
[subjectIDNumberConverted, subjectIDNumber] = convertSubjectID('subjectIDNumber.mat');

% Create save file & folder
subjectDataFileName = paradigm + "SavedData" + subjectIDNumber; % E.g. ASSRSavedData0031-T1
subjectDataFolderName = "COMPS" + subjectIDNumber; % E.g. COMPS0031-T1
subjectDataDir = fullfile(pwd, '..', 'subjectData', subjectDataFolderName);
if ~exist(subjectDataDir, 'dir') % Create folder if doesn't exist
    mkdir(subjectDataDir);
end

% Load the design file for the specified paradigm
designFile = fullfile(paradigm, sprintf('%sdesign.mat', paradigm));
load(designFile); % All experimental design parameters are saved here

%% INITIALISE DATA STRUCTURES, ETC.

[t, points, numResponses, scoringData, imageData, allResponses, auditoryData, data, youScored, distractorOnsetTime, percentComplete, escapeKeyPressed] = initialiseDataStructures(paradigm, numImagesInSequence, auditoryNumTrials);

%% PSYCHTOOLBOX & PHOTODIODE SETUP SETUP

PsychStartup;
PsychtoolboxVersion
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', device_id, [], 1, samplingFrequency, 2);

% Set up Psychtoolbox window and add photodiode
[window, windowRect, screenXpixels, screenYpixels, ifi, white, black, photodiodeRect] = setupPsychtoolboxWindow(mode);
Screen('FillRect', window, white); % Fill screen with white background color

%% PRELOAD SOUNDS

sounds = cell(1, length(soundFiles));  % Preallocate cell array to store waveforms of all sound files

for s = 1:length(soundFiles)
    [waveform, samplingFrequency] = audioread(soundFiles{s}); % Reads waveform from each sound file
    if size(waveform, 2) < 2
        sounds{s} = [waveform waveform]'; % Duplicate audio files because we are using stereo channels and store in sounds
    else
        sounds{s} = waveform'; 
    end
end

%% PRELOAD SCREENS

screens = preloadScreens(window, codeDir);

%% HEARING TEST

runHearingTest(hearingTestToneFilePath, window, screenXpixels, screenYpixels, pahandle, screens)

%% STAY STILL SCREEN

showStayStillScreen(window, screenXpixels, screenYpixels, black, photodiodeRect, screens); % Screen to tell subjects to stay still while we calibrate the MEG

%% START EXPERIMENTAL BLOCK

% Reference time for start of the experiment
experimentStartTime = GetSecs;
globalExperimentStartTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

% Send MEG trigger to say experiment started!
if strcmp(mode,'meg')
    
    io64(io,port,254);
    WaitSecs(triggerDuration);
    io64(io, port, 0);
end

% Baseline fixation cross for 1.7s
displayScreenWithPoints(window, screens.fixationCross, points, screenXpixels, screenYpixels);
WaitSecs(1.7);

for i = 1:numImagesInSequence
    
    %% DISPLAY IMAGE
    
    whichImage = find(strcmp(resizedImages.fileName, imageSequence.fileName(i, subjectIDNumberConverted))); % Find index relevant image file 
    dstRect = displayImageWithPoints(window, resizedImages.image{whichImage}, points, photodiodeRect, black, screenXpixels, screenYpixels); % Displays image & points
    
    imageStartTime = GetSecs; % When image is first displayed
    keyPressed = false; % Flag to track key presses
    imageData = recordImageData(imageData, i, experimentStartTime, subjectIDNumberConverted, imageSequence); % Record image data 
    
    if imageSequence.isDistractor(i, subjectIDNumberConverted) == true % If it's a distractor image
        distractorOnsetTime = GetSecs - experimentStartTime; % Used to calculate whether subjects have responded within reactionTimeWindow or not
        youScored(i) = false; % Resets youScored so subjects can score points again in response to new distractor image
    end
    
    while GetSecs - imageStartTime < imageSequence.displayTime(i) % While loop to keep showing image for intended imageDisplayTime
        
        %% PLAY TONES
        
        if (t <= auditoryNumTrials) && ... % If current tone t is within total number of tones designed to play
                ((t == 1 && GetSecs - experimentStartTime >= auditoryOffset) || ... % 1st tone plays after auditoryOffset has elapsed
                (t > 1 && GetSecs - experimentStartTime - auditoryData.onsetTime(t-1) >= auditorySequence.SOA(t-1, subjectIDNumberConverted))) % From 2nd tone onwards, the next tone plays after auditory SOA has elapsed
            auditoryData = playSound(t, subjectIDNumberConverted, auditorySequence, pahandle, sounds, mode, io, port, triggerDuration, auditoryData, experimentStartTime); % Play sound t from auditory sequence, send trigger & record auditory data
            t = t + 1; % Update tone tracker 
        end
        
        %% CHECK KEY PRESSES
        
        [keyIsDown, ~, keyCode] = KbCheck(); % Has a key been pressed down? And what key code?
        while keyIsDown && ~keyPressed
            [allResponses, points, keyPressed, escapeKeyPressed, youScored, numResponses] = ...
                checkKeyPress(keyIsDown, keyCode, keyPressed, escapeKeyPressed, allResponses, numResponses, points, ...
                window, photodiodeRect, dstRect, experimentStartTime, i, subjectIDNumberConverted, ...
                distractorOnsetTime, reactionTimeWindow, youScored, resizedImages, whichImage, imageSequence, black);            
        end
        
    end
        
    if escapeKeyPressed % If ESC key was pressed, exit for loop to end experiment
        break;
    end

    %% DISPLAY BASELINE FIXATION CROSS
    
    fixationCrossStartTime = GetSecs; % When image is first displayed
    keyPressed = false; % Flag to track key presses
    
    displayScreenWithPoints(window, screens.fixationCross, points, screenXpixels, screenYpixels); % Displays image & points
    
    while GetSecs - fixationCrossStartTime <= imageSequence.isi(i, subjectIDNumberConverted)
        
        if mod(i,4) == 0 && GetSecs > reactionTimeWindow + imageStartTime % After every quartet (4 images), and after reactionTimeWindow has lapsed so subject cannot score any further points
            percentComplete = displayUpdateScreen(window, screens, points, screenXpixels, screenYpixels, i, numImagesInSequence, percentComplete, imageSequence, subjectIDNumberConverted, youScored); % Show progress / scoring updates 
        end
        
        %% PLAY TONES
        
        if (t <= auditoryNumTrials) && ... % If current tone t is within total number of tones designed to play
                ((t == 1 && GetSecs - experimentStartTime >= auditoryOffset) || ... % 1st tone plays after auditoryOffset has elapsed
                (t > 1 && GetSecs - experimentStartTime - auditoryData.onsetTime(t-1) >= auditorySequence.SOA(t-1, subjectIDNumberConverted))) % From 2nd tone onwards, the next tone plays after auditory SOA has elapsed
            auditoryData = playSound(t, subjectIDNumberConverted, auditorySequence, pahandle, sounds, mode, io, port, triggerDuration, auditoryData, experimentStartTime); % Play sound t from auditory sequence, send trigger & record auditory data
            t = t + 1; % Update tone tracker
        end
        
        %% CHECK KEY PRESSES
        
        [keyIsDown, ~, keyCode] = KbCheck(); % Has a key been pressed down? And what key code?
        while keyIsDown && ~keyPressed
            [allResponses, points, keyPressed, escapeKeyPressed, youScored, numResponses] = ...
                checkKeyPress(keyIsDown, keyCode, keyPressed, escapeKeyPressed, allResponses, numResponses, points, ...
                window, photodiodeRect, dstRect, experimentStartTime, i, subjectIDNumberConverted, ...
                distractorOnsetTime, reactionTimeWindow, youScored, resizedImages, whichImage, imageSequence, black);
        end
        
    end
    
    if escapeKeyPressed % If ESC key was pressed, exit for loop to end experiment
        break;
    end
    
    %% SAVE AT END OF TRIAL
    
    if i == numImagesInSequence || ~strcmp(imageSequence.trialType(i, subjectIDNumberConverted), imageSequence.trialType(i+1, subjectIDNumberConverted)) % If at end of trial or end of image sequence
        save(fullfile(subjectDataDir, subjectDataFileName), 'imageData', 'scoringData', 'allResponses', 'auditoryData', 'globalExperimentStartTime', '-v7');
    end
    
end

%% WAIT FOR AUDIO SCREEN 

if i == numImagesInSequence && t <= auditoryNumTrials % If at end of image sequence but not all auditory tones have played yet (e.g. owing to MATLAB lag)
    
    % Display waiting screen for audio (after visual part ends)
    displayScreenWithPoints(window, screens.waitForAudio, points, screenXpixels, screenYpixels);
    
    while t <= auditoryNumTrials % Play any remaining auditory tones
        if (t <= auditoryNumTrials) && ...
                ((t == 1 && GetSecs - experimentStartTime >= auditoryOffset) || ... 
                (t > 1 && GetSecs - experimentStartTime - auditoryData.onsetTime(t-1) >= auditorySequence.SOA(t-1, subjectIDNumberConverted))) % Subsequent tones play after SOA
            auditoryData = playSound(t, subjectIDNumberConverted, auditorySequence, pahandle, sounds, mode, io, port, triggerDuration, auditoryData, experimentStartTime);
            t = t + 1; % Move to the next tone
        end
        
        % Check for ESC key press to exit the loop
        [keyIsDown, ~, keyCode] = KbCheck(); % Check key press status and key code
        if keyIsDown && keyCode(KbName('ESCAPE'))
            break; % Exit the loop if ESC is pressed
        end
    end
end

%% END OF EXPERIMENTAL BLOCK

% Send MEG trigger to say experiment ended!
if strcmp(mode,'meg')
    io64(io,port,255);
    WaitSecs(triggerDuration);
    io64(io, port, 0);
end

scoringData.points = points; % Save points scored
scoringData.blockCompleted = true; % Update that we've completed the experimental block

%% SAVE AGAIN AT END OF EXPERIMENT

if i == numImagesInSequence && t > auditoryNumTrials % Check we're actually at end of experiment ( we can also arrive here after hitting ESC mid-experiment)
    save(fullfile(subjectDataDir, subjectDataFileName), 'imageData', 'scoringData', 'allResponses', 'auditoryData', 'globalExperimentStartTime', '-v7');
end

%% SHOW FINAL SCORE

showFinalScore(window, points, imageSequence, subjectIDNumberConverted, white, black); 

%% EQUALISATION OF CAS TONES

if paradigm == "ASSR" && i == numImagesInSequence % Only run at end of ASSR block
    equaliseTones(subjectIDNumber, codeDir, window, screenXpixels, screenYpixels, screens)
end

%% CLOSE EVERYTHING

Screen('CloseAll') % Close all off-screen images
sca; % Close the screen
PsychPortAudio('Stop', pahandle); % Stop the audio
PsychPortAudio('Close', pahandle); % Close the audio