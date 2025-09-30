%% CLEAR WORKSPACE

close all;
clearvars
dbstop error

%% PATHS

% Get the current script's directory and go up to the root project directory
current_dir = fileparts(mfilename('fullpath')); % Gets ASSR folder
parent_dir = fileparts(current_dir);            % Gets tasks folder
root_dir = fileparts(parent_dir);               % Gets root project folder

% Get the current script's filename for later on in case we have to restart
% the script because of a pause
current_script = mfilename('fullpath');

% Add paths
addpath(fullfile(current_dir, 'stimuli'));
addpath(fullfile(current_dir, 'design'));
addpath(fullfile(current_dir, 'lib'));
addpath(fullfile(current_dir, 'instructions'));

%% PARAMETERS

% Select paradigm
paradigm = 'practice'; % You can choose from ASSR, MMNpart1, MMNpart2, P50part1, P50part2, P50part3, CASpart1, CASpart2, CASpart3

% Load the design file for the specified paradigm
data = struct();
design_file = sprintf('%sDesign.mat', paradigm);
load(design_file); % All experimental design parameters are saved here

%% FIL & TRIGGER SET UP

% Work out which device we're on (i.e. are we on Daniel's
% laptop or in the FIL/testroom), so we can adjust settings accordingly

[~, hostname] = system('hostname'); 
hostname = strtrim(hostname); % Remove random trailing whitespace

% Change setup depending on device

if contains(hostname, 'meg', 'Ignorecase', true) % If we're in the actual MEG ROOM

    mode = 'meg'; % Turns the triggers on
    device_id = 5; % Switches audio device output to FIL audio output

elseif contains(hostname, 'stimulus', 'Ignorecase', true) % If we're in the FIL TEST ROOM

    mode = 'meg'; % Turns the triggers on
    device_id = 1; % Switches audio device output to test room audio output

else % If we're on a non-FIL device
    
    mode = 'debug'; % Switches off the triggers so code runs on non-FIL device
    device_id = []; % Switches audio device output to non-FIL audio output

end

if strcmp(mode,'meg')
    warning('Running in MEG mode! Triggers will be send.');
    port = hex2dec('3ff8');                         % !!! check the port address in device manager !!!
    onset = 99;                        % three trial types
    offset = 0;                                     % for resetting the port and marking the offset
    io   = io64;                                      % create parallel port object
    status = io64(io);                              % check status of parallel port
    assert(status==0,'Parallel port not opened.');
    io64(io, port, 0); % Send offset trigger to ensure all pins are zeroed
else
    warning('Running in test mode. No triggers will be send!!!');
end

%% TRIGGER INFO

% Visual task trigger values and what they mean
% Note: MEG trigger values must lie between 1 and 255 (inclusive)

% Visual triggers
 
% 1 = ?standardTrial6QuartetOnset?, when a standard 6-quartet trial starts  
% 2 = ?deviantTrial4QuartetOnset?, when a deviant 4-quartet trial starts  
% 3 = ?deviantTrial5QuartetOnset?, when a deviant 5-quartet trial starts  
% 4 = ?deviantTrial6QuartetOnset?, when a deviant 6-quartet trial starts  
% 5 = ?distractorTrialOnset?, when a distractor trial starts
 
% 8 = ?visualTrialEnd?, when a trial ends 
 
% 9 =  'distractorImageOnset', when the repeated image (distractor that participants have to respond to) appears
 
% 11 = ?firstImageOnset?, when the first image in a quartet of 4 images is shown
% 12 = ?secondImageOnset?, when the second image in a quartet of 4 images is shown
% 13 = ?thirdImageOnset?, when the third image in a quartet of 4 images is shown
% 14 = ?fourthImageOnset?, when the fourth image in a quartet of 4 images is shown
 
% 21 = ?firstQuartetOnsetInAStandardTrial?, when the first quartet of a standard trial begins  
% 22 = ?secondQuartetOnsetInAStandardTrial?, when the second quartet of a standard trial begins  
% 23 = ?thirdQuartetOnsetInAStandardTrial?, when the third quartet of a standard trial begins  
% 24 = ?fourthQuartetOnsetInAStandardTrial?, when the fourth quartet of a standard trial begins  
% 25 = ?fifthQuartetOnsetInAStandardTrial?, when the fifth quartet of a standard trial begins  
% 26 = ?sixthQuartetOnsetInAStandardTrial?, when the sixth quartet of a standard trial begins  
 
% 31 = ?firstQuartetOnsetInADeviantTrial?, when the first quartet of a deviant trial begins  
% 32 = ?secondQuartetOnsetInADeviantTrial?, when the second quartet of a deviant trial begins  
% 33 = ?thirdQuartetOnsetInADeviantTrial?, when the third quartet of a deviant trial begins  
% 34 = ?fourthQuartetOnsetInADeviantTrial?, when the fourth quartet of a deviant trial begins  
% 35 = ?fifthQuartetOnsetInADeviantTrial?, when the fifth quartet of a deviant trial begins  
% 36 = ?sixthQuartetOnsetInADeviantTrial?, when the sixth quartet of a deviant trial begins  
 
% 104 =  ?standardImageC4QuartetOnset?, onset of image C (3rd image) in 4th quartet of a standard trial
% 105 =  ?standardImageC5QuartetOnset?, onset of image C (3rd image) in 5th quartet of a standard trial
% 106 =  ?standardImageC6QuartetOnset?, onset of image C (3rd image) in 6th quartet of a standard trial
 
% 204 = ?deviantImage4QuartetOnset?, onset of deviant image in a 4-quartet deviant trial
% 205 = ?deviantImage5QuartetOnset?, onset of deviant image in a 5-quartet deviant trial
% 206 = ?deviantImage6QuartetOnset?, onset of deviant image in a 6-quartet deviant trial
 
% 40 = 'subjectRespondedCorrectly', when the subject presses the response button correctly within the time window
% 41 = 'subjectRespondedWrongly', when the subject presses the response button at wrong time (i.e. too slow or when there was no two-in-a-row image)
 
% 254 =  'experimentalBlockStart', when the experimental block starts (i.e. after subject confirms they are ready to start with button press)
% 255 =  'experimentalBlockEnd',  when the experimental block ends
 
% P50 triggers (only relevant to P50 version of script)
 
% 51 = ?firstClick?, when the first click plays
% 52 = ?secondClick?, when the second click plays
 
% ASSR triggers (only relevant to ASSR version of script)
 
% 60 = ?clicktrain?, when a clicktrain plays
 
% Oddball MMN (only relevant to MMN version of script) 
 
% 70 = ?standardTone?, when a standard tone plays
% 71 = ?deviantTone?, when a deviant tone plays
 
% CAS (only relevant to CAS version of script)

% 80 = ?tone?, when a tone is played

%% SETUP PSYCHTOOLBOX

PsychStartup;
PsychtoolboxVersion

%% Start data structure
data = struct();
data.recording_date = datetime;

% Some potentially useful information about the setup
data.matlab_version = version;
data.ptb_version    = PsychtoolboxVersion;
data.computer       = computer;
data.audiodevinfo   = audiodevinfo;

% Experimental parameters
data.n_trials = 25;

% Trigger values and what they mean
data.trial_list  = [100 200 300 400 111 999];
data.trial_label = {'predictable', 'mismatch', 'unpredictable', 'distractor', 'instructions', 'end_experiment'}';


%% Subject ID 

filePath = 'C:\Users\compi\Documents\COMPS\code\tasks\subjectIDNumber.mat'; % The GUI saves most recent subject's ID number here

% Load the .mat file
load(filePath);

subjectIDnumberConverted = str2double(subjectIDNumber);  % Convert ID to number, e.g. '0044' to 44

% Concatenate "COMPS_" with the subject ID number for full subject ID
subjectIDFull = ['COMPS_' sprintf('%04s', subjectIDNumber)]; % For final subject ID e.g. COMPS_0044


%% Setup screen
% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
% if strcmp(mode,'debug')
%     PsychDebugWindowConfiguration(0,0.5)
% end

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
screens = Screen('Screens');

% To draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen.
screenNumber = max(screens);

% Define black and white (white will be 1 and black 0). This is because
% in general luminace values are defined between 0 and 1 with 255 steps in
% between. With our setup, values defined between 0 and 1.
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white/2;
Screen('Preference', 'SkipSyncTests', 1);


%% Start up screen
%Screen('Preference', 'SkipSyncTests', 1)
% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Setup the text type for the window
Screen('TextFont', window, 'Ariel');
Screen('TextSize', window, 36);

HideCursor(window);
Screen('Flip', window);

%% Parameters
start_volume = 40; % dB
volume_increment1 = 10; % dB
volume_increment2 = 5; % More precise volume incremement dB 
max_volume = 100; % dB
volume_decrement = 10; % dB
isi_range = [1 3]; % seconds !! change back to 1 3 later
stimulus_duration_range = [1 3]; % seconds !! change back to 1 3 later 
reaction_window = 1.5; % Time allowed for button press response to sound (seconds) 

% Create sequence of volumes to test, initially increasing by 10 dB, then after 80 dB threshold only increasing by 5 dB until max_volume 
volume_vector = start_volume:volume_increment1:80;  % From start to 80 dB
volume_vector = [volume_vector, 80+volume_increment2:volume_increment2:max_volume]; % Add from 80 dB to max_volume

% Load the tone .wav file
[wavData, fsFile] = audioread('hearing_test_tone.wav'); 

%% PART 1 

%% Instructions 1 
slide_location = fullfile('hearing_test', 'hearing_test_intro.jpg');
% Read the image
slide_image = imread(slide_location);

% Create a texture from the image
slide_texture = Screen('MakeTexture', window, slide_image);

% Draw the texture to the screen, scaled to full screen size
Screen('DrawTexture', window, slide_texture, [], [0 0 screenXpixels screenYpixels], 0, [], 1);

% Flip the screen to display the texture
Screen('Flip', window);

% Wait for the right arrow key to be pressed
waitForRightArrow()

%% Initial Hearing Test, purpose to familiarise with the clicking system on off etc. 

% Possible problem: only verifies one correct response, vs 2 or 3 ? 
% Problem: need an error screen in case that the dude doesn't get one
% correct haha

% Display the Not Pressed Screen
displayNotPressedScreen(window, screenXpixels, screenYpixels)

WaitSecs(2); % Brief pause before tones start playing 

keepLooping = true;
while keepLooping
    
    numPositiveResponses = 0; % To keep track of stopping condition: 2 positive responses 
    
    % Play sound and increase volume
    for volume = volume_vector
        
        % Initialise flag 
        canRespondPositively = true;
        
        % Play tone
        stimulus_duration = stimulus_duration_range(1) + diff(stimulus_duration_range)*rand; % Random duration
        scaleFactor = 0.01;
        playSound('hearing_test_tone.wav', volume, stimulus_duration, scaleFactor)
        
        % Create reference timepoint for the sound onset
        startTime = GetSecs; % Sound onset time
        isi_duration = isi_range(1) + diff(isi_range)*rand; % ISI range
        SOA_duration = isi_duration + stimulus_duration; % Total duration for this sound (stimulus + ISI)
        
        % Initialise timekeeping variables 
        key_pressed_time = NaN; % Initialize time for when key is pressed
        release_time = NaN; % Initialise time for when key is released 
        
        while GetSecs - startTime < SOA_duration % I.e. before the the next sound plays 
            
            % Check for key presses
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown
                % Check if the right arrow key was pressed 
                if  keyCode(KbName('RightArrow'))
                    
                    displayPressedScreen(window, screenXpixels, screenYpixels) % Display the pressed screen 
                    first_test_volume = volume; % Save this volume for next part of test 
                    
                    if isnan(key_pressed_time)
                    key_pressed_time = GetSecs; % Record the time when the key is pressed
                    end
                end
            end
                    
            % Check for key release (without blocking further execution)
            if ~keyIsDown && ~isnan(key_pressed_time)
                displayNotPressedScreen(window, screenXpixels, screenYpixels); % Display the not pressed screen
                if isnan(release_time)
                release_time = GetSecs; % Time when the key was released
                end
            end
            
            positiveResponse = (release_time - startTime) > stimulus_duration && (release_time - startTime) < (stimulus_duration + reaction_window) && (key_pressed_time - startTime) < reaction_window;
            
            % Now check if the key is released after the stimulus duration but before the end of the reaction window
            if positiveResponse && canRespondPositively
                % If the key was released in the correct time frame, add
                % 1 to numPositiveResponses
                numPositiveResponses = numPositiveResponses + 1;
                canRespondPositively = false; % So can't record multiple positive responses within one for loop 
            end
        end
        
        % If subject has responded correctly twice, break the loop, move
        % onto next section 
        if numPositiveResponses >= 2 
            keepLooping = false; % Break loop 
            break % Break for loop to reach outer loop
        end
        
    end
end

%% Instructions 1 
slide_location = fullfile('hearing_test', 'hearing_test_intro.jpg');
% Read the image
slide_image = imread(slide_location);

% Create a texture from the image
slide_texture = Screen('MakeTexture', window, slide_image);

% Draw the texture to the screen, scaled to full screen size
Screen('DrawTexture', window, slide_texture, [], [0 0 screenXpixels screenYpixels], 0, [], 1);

% Flip the screen to display the texture
Screen('Flip', window);

% Wait for the right arrow key to be pressed
waitForRightArrow()

%% PART 2

%% Decrease till no response, work out where to start the staircase 

% Decrease the tone by 10dB
% if response then decrease again 
% if no response then stop > save volume dB > 

% Create vector of descending volumes to loop through 
current_volume = first_test_volume - volume_decrement; % Decrease by volume decrement to start the next hearing test 10dB below their previous answer
volume_vector2 = current_volume:-(volume_decrement):-100; % New volume vector to loop through now descending in dB

% Display the Not Pressed Screen
displayNotPressedScreen(window, screenXpixels, screenYpixels)

keepLooping = true;
while keepLooping
    % Play sound and increase volume
    for volume = volume_vector2
        
        % Play tone
        stimulus_duration = stimulus_duration_range(1) + diff(stimulus_duration_range)*rand; % Random duration
        scaleFactor = 0.01;
        playSound('hearing_test_tone.wav', volume, stimulus_duration, scaleFactor)
        
        % Create reference timepoint for the sound onset
        startTime = GetSecs; % Sound onset time
        isi_duration = isi_range(1) + diff(isi_range)*rand; % ISI range
        SOA_duration = isi_duration + stimulus_duration; % Total duration for this sound (stimulus + ISI)
        
        % Initialise timekeeping variables 
        key_pressed_time = NaN; % Initialize time for when key is pressed
        release_time = NaN; % Initialise time for when key is released 
        
        while GetSecs - startTime < SOA_duration % I.e. before the the next sound plays 
            
            % Check for key presses
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown
                % Check if the right arrow key was pressed 
                if  keyCode(KbName('RightArrow'))
                    
                    displayPressedScreen(window, screenXpixels, screenYpixels) % Display the pressed screen 
                    
                    if isnan(key_pressed_time)
                    key_pressed_time = GetSecs; % Record the time when the key is pressed
                    end
                end
            end
                    
            % Check for key release (without blocking further execution)
            if ~keyIsDown && ~isnan(key_pressed_time)
                displayNotPressedScreen(window, screenXpixels, screenYpixels); % Display the not pressed screen
                if isnan(release_time)
                release_time = GetSecs; % Time when the key was released
                end
            end
            
        end
        
        positiveResponse = (release_time - startTime) > stimulus_duration && (release_time - startTime) < (stimulus_duration + reaction_window) && (key_pressed_time - startTime) < reaction_window;
            
        % Now check if the key is released after the stimulus duration but before the end of the reaction window
        if positiveResponse
            % If the key was released in the correct time frame, break the loop
            keepLooping = true; % Continue the loop until subject does not respond
        else
            second_test_volume = volume; % Save this volume for the third test 
            keepLooping = false; % Break the loop; subject has not responded so we assume cannot hear the sound
            break
        end
        
    end
end

%% PART 3

%% FINAL PRECISE HEARING TEST, actually find their specific hearing threshold

% Set starting volume for third and final hearing test 
volume = second_test_volume; % Starting from the second test volume (i.e. the loudest volume at which the participant did not respond)

% Initialize hearing_threshold_estimates vector
hearing_threshold_estimates = [];

% Display the not pressed screen
displayNotPressedScreen(window, screenXpixels, screenYpixels)

keepLooping = true;
while keepLooping
        
    % Check for stopping condition: 2 out of the last 4 recorded estimates must be equal
    if length(hearing_threshold_estimates) >= 2

        % Get the last four values, or all values if fewer than four
        recent_values = hearing_threshold_estimates(max(1, length(hearing_threshold_estimates) - 3):end);
        % Count unique values in the recent values
        unique_values = unique(recent_values);

        % Check if the count of unique values is less than 4
        if numel(unique_values) < numel(recent_values) % This implies at least one of the values out of the most recent values must be a duplicate
            disp('Stopping condition met: 2 out of the last 4 estimates are equal.');
            keepLooping = false; % Exit the loop
            break
        end
    end
 
    % Play tone
    stimulus_duration = stimulus_duration_range(1) + diff(stimulus_duration_range)*rand; % Random duration
    scaleFactor = 0.01;
    playSound('hearing_test_tone.wav', volume, stimulus_duration, scaleFactor)

    % Create reference timepoint for the sound onset
    startTime = GetSecs; % Sound onset time
    isi_duration = isi_range(1) + diff(isi_range)*rand; % ISI range
    SOA_duration = isi_duration + stimulus_duration; % Total duration for this sound (stimulus + ISI)

    % Initialise timekeeping variables 
    key_pressed_time = NaN; % Initialize time for when key is pressed
    release_time = NaN; % Initialise time for when key is released
    
    % Initialise flag 
    volumeAdjusted = false; 

    while GetSecs - startTime < SOA_duration % I.e. before the the next sound plays 

        % Check for key presses
        [keyIsDown, ~, keyCode] = KbCheck();
        if keyIsDown
            % Check if the right arrow key was pressed 
            if  keyCode(KbName('RightArrow'))

                displayPressedScreen(window, screenXpixels, screenYpixels) % Display the pressed screen 
                first_test_volume = volume; % Save this volume for next part of test 

                if isnan(key_pressed_time)
                key_pressed_time = GetSecs; % Record the time when the key is pressed
                end
                
            elseif keyCode(KbName('ESCAPE'))  
                keepLooping = false; 
                break
            end
        end

        % Check for key release (without blocking further execution)
        if ~keyIsDown && ~isnan(key_pressed_time)
            displayNotPressedScreen(window, screenXpixels, screenYpixels); % Display the not pressed screen
            if isnan(release_time)
            release_time = GetSecs; % Time when the key was released
            end
        end
                
    end
    
    positiveResponse3 = (release_time - startTime) > stimulus_duration && (release_time - startTime) < (stimulus_duration + reaction_window) && (key_pressed_time - startTime) < reaction_window;
    
    % Now check if the key is released after the stimulus duration but before the end of the reaction window
    if volumeAdjusted == false
        if positiveResponse3
            % If the key was released in the correct time frame, break the loop
            hearing_threshold_estimates(end+1) = volume; 
            volume = volume - 10; 
            disp('Positively splendiferous, old chap!')
            volumeAdjusted = true;
        else 
            volume = volume + 5; 
            disp('Negatorial')
            volumeAdjusted = true; 
        end
    end
        
end


%% End Screen

slide_location = fullfile('hearing_test', 'hearing_test_end.jpg');
% Read the image
slide_image = imread(slide_location);

% Create a texture from the image
slide_texture = Screen('MakeTexture', window, slide_image);

% Draw the texture to the screen, scaled to full screen size
Screen('DrawTexture', window, slide_texture, [], [0 0 screenXpixels screenYpixels], 0, [], 1);

% Flip the screen to display the texture
Screen('Flip', window);

% Wait for the any key to be pressed
KbWait; 

% Cleanupg
Screen('CloseAll');
 
%% SAVE ALL THE VARIABLES

hearingThreshold = hearing_threshold_estimates(end); % Get final hearing threshold estimate 

% Get Subject ID Number
subjectIDFilePath = fullfile(pwd, '..', 'subjectIDNumber.mat');
load(subjectIDFilePath) 

hearingTresholdSaveFileName = ['hearingTreshold' subjectIDNumber '.mat']; % Append subject ID
subjectSavedDataFolderName = ['COMPS' subjectIDNumber];
subjectSavedDataFolderPath = fullfile(pwd, '..', '..', 'subjectData', subjectSavedDataFolderName);
savePath = fullfile(subjectSavedDataFolderPath, hearingTresholdSaveFileName);
save(savePath, 'hearingThreshold');
