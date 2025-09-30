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

% Set trigger duration (i.e. how long a trigger needs to be activated for)
triggerDuration = 0.002; % (seconds)

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

%% GET SUBJECT ID

subjectIDNumber = '0200-T0'; % No data is being saved so create random subject ID 

% Concatenate "COMPS_" with the subject ID number for full subject ID
subjectIDFull = ['COMPS_' sprintf('%04s', subjectIDNumber)]; % For final subject ID e.g. COMPS_0044

% Convert ID to number, e.g. '0044' to 44
subjectIDnumberConverted = str2double(subjectIDNumber(1:4));  

    
%% INITIALISE DATA STRUCTURES, ETC.

repeatExercise = true;
while repeatExercise % Will loop until participant choose "continue"

start_trial = 1; % Initialise start_trial from start
t = 1; % Initialise tone tracker from start, keeps track of which tone to play and when from the auditory tone sequence
points = 0; % Tracks how many two-in-a-row images subject correctly spots; starts at 0 if no previous experimental session was run
skipHearingTest = false; % Subject has no saved data, therefore has not previously completed the hearing test
numResponses = 0; % Keep track of how many times subject has responded

last_saved_time_from_saved_file = 0;

loadingPreviousData = false; 

% IQI tracker
whichIQI = 1; % Keeps track of which inter-quartet interval (IQI) time to use from a pre-randomised sequence of IQIs created in the design file

scoringData = table( ...
    {paradigm}, ...  % 'whichParadigm' - Which paradigm was run (e.g. ASSR, MMN, etc.)
    0, ...     % 'points' - Number of points scored
    false, ... % 'blockCompleted' - Whether the block was completed
    'VariableNames', {'whichParadigm', 'points', 'blockCompleted'});

imageData = table( ...
    NaN(visualNumTrials*24, 1), ...  % 'onsetTime' - What time the image is displayed, relative to the start of the experiment
    cell(visualNumTrials*24, 1), ...  % 'fileName' - The file name of the displayed image
    NaN(visualNumTrials*24, 1), ...  % 'trialNumber' - Trial number. Each trial = 2 quartets of 4 images = 8 images displayed
    NaN(visualNumTrials*24, 1), ...  % 'imageNumber' - Image number within a given trial, i.e. 1 to 8, 1 = 1st image displayed in sequence, 8 = 8th image displayed. 1st trial displays 8 images, 2nd trial displays the next 8, etc.
    cell(visualNumTrials*24, 1), ...  % 'trialType' - Is this trial's sequence "predictable", "unpredictable", "mismatch" or "distractor"
    cell(visualNumTrials*24, 1), ...  % 'trialSequenceNumeric' - The specific order that images are shown for this trial, e.g. predictable would be 1 2 3 4 1 2 3 4, unpredictable could be 1 2 3 4 3 4 1 2, mismatch would be 1 2 3 4 1 2 4 3, distractor could be 1 2 2 3 1 2 3 4
    cell(visualNumTrials*24, 1), ...  % 'trialSequenceAlphabetic' - The specific order that images are shown for this trial but using letters rather than image number as per Garrido et al., 2015 (https://doi.org/10.1016/j.neuroimage.2015.07.016) , e.g. predictable would be A B C D A B C D, unpredictable could be A B C D C D A B, mismatch would be A B C D A B D C, distractor could be A B B C A B C D
    NaT(visualNumTrials*24, 1, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'), ...  % 'machineOnsetTime' - What time the image is displayed, using the timer of computer itself
    'VariableNames', {'onsetTime', 'fileName', 'trialNumber', 'imageNumber', ...
    'trialType', 'trialSequenceNumeric', 'trialSequenceAlphabetic', 'machineOnsetTime'});

% Upper bound of number of responses so we can pre-allocate size of the response times table
maxResponses = visualNumTrials * 24 * 10; % Assumes subjects won't respond more than 10x per image displayed!

% To record data when subject responds
allResponseTimes = table( ...
    NaN(maxResponses, 1), ...  % 'reactionTime' - Time taken for subject to respond since stimulus onset i.e. time now - stimulus onset time (seconds)
    NaN(maxResponses, 1), ...  % 'globalTime' - The global time when subject responds, relative to experimentStartTime (seconds)
    NaN(maxResponses, 1), ...  % 'trialNumber' - Trial number. Each trial = 2 quartets of 4 images = 8 images displayed. 1st trial displays 8 images, 2nd trial displays the next 8, etc.
    NaN(maxResponses, 1), ...  % 'imageNumber' - Image number within a given trial that the subject has responded to, i.e. 1 to 8, 1 = 1st image displayed in sequence, 8 = 8th image displayed. NOTE: this is not necessarily the same as the image displaying when subject responds, because the reaction window allows for a delayed reaction. E.g. subject might spot that the 6th image is a two-in-a-row, but only respond while 7th image is showing
    NaN(maxResponses, 1), ...  % 'correct' - Did subject respond correctly to win a point? 1 = yes, 0 = false
    NaN(maxResponses, 1), ...  % 'late' - Did subject respond late? 1 = yes/late, NaN = false. Late means the subject responded to a two-in-a-row image when the next image is showing because the reaction window spans more than 1 image display time. E.g. subject might spot that the 6th image is a two-in-a-row, but only respond while 7th image is showing
    cell(maxResponses, 1), ...  % 'imageFileName' - The file name of the displayed image
    cell(maxResponses, 1), ...  % 'trialType' - Is this trial's sequence predictable, unpredictable, mismatch or distractor
    cell(maxResponses, 1), ...  % 'trialSequenceNumeric' - The specific order that images are shown for this trial, e.g. predictable would be 1 2 3 4 1 2 3 4, unpredictable could be 1 2 3 4 3 4 1 2, mismatch would be 1 2 3 4 1 2 4 3, distractor could be 1 2 2 3 1 2 3 4
    cell(maxResponses, 1), ...  % 'trialSequenceAlphabetic' - The specific order that images are shown for this trial but using letters rather than image number as per Garrido et al., 2015 (https://doi.org/10.1016/j.neuroimage.2015.07.016), e.g. predictable would be A B C D A B C D, unpredictable could be A B C D C D A B, mismatch would be A B C D A B D C, distractor could be A B B C A B C D
    NaT(maxResponses, 1, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'), ...  % 'machineGlobalTime' - The global time when subject responds, using the computer's time settings
    'VariableNames', {'reactionTime', 'globalTime', 'trialNumber', 'imageNumber', ...
    'correct', 'late', 'imageFileName', 'trialType', 'trialSequenceNumeric', 'trialSequenceAlphabetic', 'machineGlobalTime'});

clicktrainDataASSR = table( ...
    NaN(auditoryNumTrials, 1), ...  % 'onsetTime' - What time the clicktrain starts, relative to the start of the experiment
    NaN(auditoryNumTrials, 1), ...  % 'trialNumber' - Trial number tells us which clicktrain we're on, e.g. 1st, 2nd...300th
    NaT(auditoryNumTrials, 1, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'), ...  % 'machineOnsetTime' - What time the clicktrain starts, using the computer's time settings
    'VariableNames', {'onsetTime', 'trialNumber', 'machineOnsetTime'});

% Initialise percent complete trackers as false. These keep track of a
% subject's progress in the experiment.
twentyFivePercentComplete = false;
fiftyPercentComplete = false;
seventyFivePercentComplete = false;

%% SAVE SETUP DATA
data.id = "COMPS";
data.recording_date = datetime;

% Some potentially useful information about the setup
data.matlab_version = version;
data.ptb_version    = PsychtoolboxVersion;
data.computer       = computer;
data.audiodevinfo   = audiodevinfo;

%% IMAGE SETUP

% Get list of all the images
image_files = dir(fullfile(current_dir, 'stimuli', '*.jpg')); % get images from the stimuli folder

% Pre-allocate cell arrays to hold the actual images and their filenames
images = cell(1, length(image_files));
image_filenames = cell(1, length(image_files));  % Cell array to hold the filenames

% Read each image and store it and its filename
for i = 1:length(image_files)
    image_path = fullfile(current_dir, 'stimuli', image_files(i).name);
    images{i} = imread(image_path); % store each image in the cell array for later on
    image_filenames{i} = image_files(i).name; % store the filename
end

resized_images = cell(1, length(image_files)); % Pre-allocate matrix to hold images after they've all been resized to fit more centrally on screen to avoid excessive eye movement in subjects

% Define maximum image dimensions
maxWidth = 400; % maximum width for the image
maxHeight = 400; % maximum height for the image

for i = 1:length(image_files)
    
    current_image = images{i};
    
    % Get original image dimensions
    [originalHeight, originalWidth, ~] = size(current_image);
    
    % Calculate scaling factors
    scaleFactor = min(maxWidth / originalWidth, maxHeight / originalHeight);
    
    % Calculate new dimensions while maintaining aspect ratio
    newWidth = round(originalWidth * scaleFactor);
    newHeight = round(originalHeight * scaleFactor);
    
    % Resize the image
    current_image = imresize(current_image, [newHeight, newWidth]);
    
    resized_images{i} = current_image;
    
end

% Randomly allocate images into quartets and keep the filenames alongside
% Randomly shuffle the images and filenames together
random_indices = randomIndicesMatrix(subjectIDnumberConverted, :);  % Get a subject-unique series of random indices from the pregenerated random index series
shuffled_images = resized_images(random_indices);   % Shuffle images
shuffled_filenames = image_filenames(random_indices); % Shuffle filenames

% Reshape into quartets (i.e., create a matrix of [num_trials x 4] for images)
quartet_images = reshape(shuffled_images, [visualNumTrials, 4]);
quartet_filenames = reshape(shuffled_filenames, [visualNumTrials, 4]); % Reshape filenames to match image quartet


%% SCREEN SETUP

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

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
Screen('Preference', 'SkipSyncTests', 1);

%% WINDOW SETUP

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

%% SET UP SCREENS FOR VISUAL PARADIGMS

% Preload all the screens we're gonna use in the visual
% paradigm so we don't waste time loading them up when we start the actual experiment 

% Set up fixation cross
FixationCrossWhite_location = fullfile(current_dir, 'instructions', 'instructions', 'FixationCrossWhite.jpg');
matrix_FixationCrossWhite = imread(FixationCrossWhite_location);
texture_FixationCrossWhite = Screen('MakeTexture', window, matrix_FixationCrossWhite);

% Set up fixation crossed + "You missed!" for when a subject misses a
% repeat image 
FixationCrossWhiteYouMissed_location = fullfile(current_dir, 'instructions', 'instructions', 'FixationCrossWhiteYouMissed.jpg');
matrix_FixationCrossWhiteYouMissed = imread(FixationCrossWhiteYouMissed_location);
texture_FixationCrossWhiteYouMissed = Screen('MakeTexture', window, matrix_FixationCrossWhiteYouMissed);

% Set up fixation crossed + "You got it!" for when a subject correctly spots a
% repeat image within time
FixationCrossWhiteYouGotIt_location = fullfile(current_dir, 'instructions', 'instructions', 'FixationCrossWhiteYouGotIt.jpg');
matrix_FixationCrossWhiteYouGotIt = imread(FixationCrossWhiteYouGotIt_location);
texture_FixationCrossWhiteYouGotIt = Screen('MakeTexture', window, matrix_FixationCrossWhiteYouGotIt);

% Set up fixation crossed + "25% Complete!" for when a subject is 25% of the way through the experiment
FixationCrossWhite25PercentComplete_location = fullfile(current_dir, 'instructions', 'instructions', 'FixationCrossWhite25PercentComplete.jpg');
matrix_FixationCrossWhite25PercentComplete = imread(FixationCrossWhite25PercentComplete_location);
texture_FixationCross25PercentComplete = Screen('MakeTexture', window, matrix_FixationCrossWhite25PercentComplete);

% Set up fixation crossed + "50% Complete!" for when a subject is 50% of the way through the experiment
FixationCrossWhite50PercentComplete_location = fullfile(current_dir, 'instructions', 'instructions', 'FixationCrossWhite50PercentComplete.jpg');
matrix_FixationCrossWhite50PercentComplete = imread(FixationCrossWhite50PercentComplete_location);
texture_FixationCross50PercentComplete = Screen('MakeTexture', window, matrix_FixationCrossWhite50PercentComplete);

% Set up fixation crossed + "75% Complete!" for when a subject is 75% of the way through the experiment
FixationCrossWhite75PercentComplete_location = fullfile(current_dir, 'instructions', 'instructions', 'FixationCrossWhite75PercentComplete.jpg');
matrix_FixationCrossWhite75PercentComplete = imread(FixationCrossWhite75PercentComplete_location);
texture_FixationCross75PercentComplete = Screen('MakeTexture', window, matrix_FixationCrossWhite75PercentComplete);

% Set up paused screen for when the experiment is paused 
pausedScreen = fullfile(current_dir, 'instructions', 'instructions', 'pausedScreen.jpg');
pausedScreenAsTexture = imread(pausedScreen);
pausedScreen = Screen('MakeTexture', window, pausedScreenAsTexture);

% Fill the screen with the background color
Screen('FillRect', window, white);

%% SET UP TRACKERS

% Initialize pause state
isPaused = false;

% Flags created to update the percent complete trackers. (If the percent
% complete trackers are updated directly it breaks if/while loops, so these
% flags are created)
twentyFivePercentCompleteFlag = false; 
fiftyPercentCompleteFlag = false; 
seventyFivePercentCompleteFlag = false; 

%% Instructions

% Display instruction slide 1
slide_location = fullfile('instructions','instructions','Slide1.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);
Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);

% !! Check with Daniel

t_inst = Screen('Flip', window);
t_inst_getsecs = GetSecs;
% if strcmp(mode,'meg')
%     io64(io,port,data.trial_list(5));
% end

% Wait until right arrow button is pressed
waitForRightArrow()

% Display instruction slide 2
slide_location = fullfile('instructions','instructions','Slide2.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);
Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
waitForRightArrow()

% Display instruction slide 3
slide_location = fullfile('instructions','instructions','Slide3.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);
Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
waitForRightArrow()

% Display instruction slide 4
slide_location = fullfile('instructions','instructions','Slide4.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);
Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
waitForRightArrow()

% Display explanation of fixation cross
slide_location = fullfile('instructions','instructions','FixationCrossExplanation.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);
Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
waitForRightArrow()

% You got it explanation
slide_location = fullfile('instructions','instructions','YouGotItExplanation.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);
Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
waitForRightArrow()

% You missed it explanation
slide_location = fullfile('instructions','instructions','YouMissedItExplanation.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);
Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
waitForRightArrow()


% Display instruction slide 5
slide_location = fullfile('instructions','instructions','Slide5.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);
Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
waitForRightArrow()

% Display instruction slide 6
slide_location = fullfile('instructions','instructions','Slide6.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);
Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
waitForRightArrow()


%% Set up fixation crosses, image dimensions and background colour

FixationCrossWhite_location = fullfile('instructions', 'instructions', 'FixationCrossWhite.jpg');
matrix_FixationCrossWhite = imread(FixationCrossWhite_location);
texture_FixationCrossWhite = Screen('MakeTexture', window, matrix_FixationCrossWhite);

FixationCrossWhiteYouMissed_location = fullfile('instructions', 'instructions', 'FixationCrossWhiteYouMissed.jpg');
matrix_FixationCrossWhiteYouMissed = imread(FixationCrossWhiteYouMissed_location);
texture_FixationCrossWhiteYouMissed = Screen('MakeTexture', window, matrix_FixationCrossWhiteYouMissed);

% Define maximum image dimensions
maxWidth = 400; % maximum width for the image
maxHeight = 400; % maximum height for the image

% Fill the screen with the background color
Screen('FillRect', window, white); 

%% START EXPERIMENTAL BLOCK

% Reference time for start of the experiment
experimentStartTime = GetSecs;

% Show fixation cross to serve as baseline for the very first trial 
Screen('DrawTexture', window, texture_FixationCrossWhite, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
drawPoints(window, points); % Re-add the points in black text to show on the white screen
Screen('Flip', window);
WaitSecs(1.7); % Wait for IQI period 
    
for i = start_trial:visualNumTrials 
    
    %% GET IMAGE ORDER & IMAGES FOR TRIAL i 
    
    current_order = imageOrdersForEachTrial(i, :, subjectIDnumberConverted); % Get the order of this specific trial
    current_order = current_order(current_order ~= 0); % Remove the trailing zeros
    current_quartet = quartet_images(i, :); % Get the quartet for this specific trial
        
    %% SCORING
    
    canScore = ones(1, length(current_order)); % Flag to check they whether they can score or not; more specifically, because the reaction window spans more than one image, we need this row vector to keep track of whether subject correctly responded last loop; if so, they can't score a point during this loop for a late response to the same two-in-a-row image otherwise they would be double-scoring!
    youScored = false; % Flag to track whether they scored or not
        
    %% SHOW IMAGES
    
    % Display the quartet images in the order specified by current_order
    for j = 1:length(current_order) % Loop through all images in a current trial
        
        % Get the current image from the current quartet in the current order
        current_image = current_quartet{current_order(j)};
        
        %% RESIZE & DISPLAY IMAGE
        
        [imageHeight, imageWidth, ~] = size(current_image);
        
        % Calculate the destination rectangle to center the image
        dstRect = CenterRectOnPointd([0 0 imageWidth imageHeight], screenXpixels / 2, screenYpixels / 2);
        
        % Display the image
        image_to_texture = Screen('MakeTexture', window, current_image);
        Screen('DrawTexture', window, image_to_texture, [], dstRect, 0, [], 1);
        drawPoints(window, points); % Add points to the screen before flipping
        Screen('Flip', window); % Flip the screen to display the image
        
        %% RECORD IMAGE DATA & SEND TRIGGERS
                
        % Send triggers for image onset
        
        % We want to convert image number j, which goes from 1 up to 24 (depending on trial length), into
        % its image order within a quartet. 
        % E.g. if j = 23, we're on the 3rd image of the 6th quartet 
        % But we just want the 3 for 3rd, as we record which quartet we're in
        % separately
        
        orderOfImageInQuartet = 1 + mod(j-1,4); % This converts j = 23 into orderOfImageInQuartet = 3, so we now know we're on the 3rd of image of the quartet
                
        if strcmp(mode,'meg')
            
            % Trigger for onset of nth image in a quartet
            io64(io,port,10 + orderOfImageInQuartet); % Send trigger for nth image onset within a quartet; first image onset corresponds to trigger value 11, hence the 10 + j
            WaitSecs(triggerDuration);
            io64(io, port, 0);

            % Trigger for distractor image 
            if j > 1 && current_order(j) == current_order(j-1) % Check if the image is repeated
                io64(io,port,9); % Trigger for onset of the repeated distractor image
                WaitSecs(triggerDuration);
                io64(io, port, 0);
            end
            
            % Triggers for quartet onset 
            
            if orderOfImageInQuartet == 1
                
                whichQuartet = floor(j/4) + 1; % Calculates which quartet we're in based on image number j. E.g. if j = 17, whichQuartet = 5, because we're in the 5th quartet
                
                % Triggers for quartet onsets in standard trials 
                
                if trialTypeNames{i, subjectIDnumberConverted} == "standardSequenceSixQuartets"
                                    
                    io64(io,port,20+whichQuartet); % Trigger for onset of 1st/2nd/3rd/4th/5th/6th standard quartet. Trigger 21 = 1st quartet onset, 22 = 2nd quartet onset, etc.
                    WaitSecs(triggerDuration);
                    io64(io, port, 0);
                    
                % Triggers for quartet onsets in deviant trials 

                elseif trialTypeNames{i, subjectIDnumberConverted} ~= "distractor" % This checks we're in a deviant trial. (If not a standard and if not a distractor, then must be a deviant.)
                    
                    io64(io,port,30+whichQuartet); % Trigger for onset of 1st/2nd/3rd/4th/5th/6th deviant quartet. Trigger 31 = 1st quartet onset, 32 = 2nd quartet onset, etc.
                    WaitSecs(triggerDuration);
                    io64(io, port, 0);

                end

            end
            
            % Triggers for 3rd image in standard and deviant trials in the
            % 4th, 5th and 6th quartets. Very important because it's at the
            % 3rd image in these quartets where image order deviates (i.e.
            % from ABCD in the standard to ABDC in the deviant!) 
                                    
            if orderOfImageInQuartet == 3
                
                % Triggers for 3rd image of standard trials 
                
                if trialTypeNames{i, subjectIDnumberConverted} == "standardSequenceSixQuartets" ...
                   
                    if j == 15 % 15th image in a trial = 3rd image in the 4th quartet
                    
                    io64(io,port,104); % Trigger for 3rd image in 4th quartet of a standard trial
                    WaitSecs(triggerDuration);
                    io64(io, port, 0);
                    
                    elseif j == 19 % 19th image in a trial = 3rd image in the 5th quartet
                    
                    io64(io,port,105); % Trigger for 3rd image in 5th quartet of a standard trial
                    WaitSecs(triggerDuration);
                    io64(io, port, 0);
                    
                    elseif j == 23 % 23rd image in a trial = 3rd image in the 6th quartet
                    
                    io64(io,port,106); % Trigger for 3rd image in 6th quartet of a standard trial          
                    WaitSecs(triggerDuration);
                    io64(io, port, 0);
               
                    end
                
                end
                
                % Triggers for deviant 3rd image in the deviant trials
                if trialTypeNames{i, subjectIDnumberConverted} == "deviantSequenceFourQuartets" ...
                  && j == 15 % 15th image in a trial = 3rd image in the 4th quartet which is when the deviant will appear for a 4-quartet deviant trial
              
                    io64(io,port,204); % Trigger for deviant image in 4th quartet of a 4-quartet deviant trial   
                    WaitSecs(triggerDuration);
                    io64(io, port, 0);
                    
                elseif trialTypeNames{i, subjectIDnumberConverted} == "deviantSequenceFiveQuartets" ...
                  && j == 19 % 19th image in a trial = 3rd image in the 5th quartet which is when the deviant will appear for a 5-quartet deviant trial
              
                    io64(io,port,205); % Trigger for deviant image in 5th quartet of a 5-quartet deviant trial  
                    WaitSecs(triggerDuration);
                    io64(io, port, 0);
                    
                elseif trialTypeNames{i, subjectIDnumberConverted} == "deviantSequenceFiveQuartets" ...
                  && j == 23 % 23rd image in a trial = 3rd image in the 6th quartet which is when the deviant will appear for a 6-quartet deviant trial
              
                    io64(io,port,206); % Trigger for deviant image in 5th quartet of a 5-quartet deviant trial      
                    WaitSecs(triggerDuration);
                    io64(io, port, 0);
                    
                end
                
            end
            
        end     
                    
        % Record image data
        imageData.onsetTime((i-1)*24 + j) = GetSecs - experimentStartTime;
        imageData.machineOnsetTime((i-1)*24 + j) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        
        current_quartet_filenames = quartet_filenames(i, :); % Get current quartet of filenames
        current_filename = current_quartet_filenames{current_order(j)}; % Get current filename, based on the current order
        imageData.fileName{(i-1)*24 + j} = current_filename;
        
        imageData.trialNumber((i-1)*24 + j) = i;
        imageData.imageNumber((i-1)*24 + j) = j;
        imageData.trialType{(i-1)*24 + j} = trialTypeNames{i, subjectIDnumberConverted};
        imageData.trialSequenceNumeric{(i-1)*24 + j} = current_order;
        imageData.trialSequenceAlphabetic{(i-1)*24 + j} = char(64 + current_order);
        
        %% IMAGE DISPLAY WHILE LOOP
        
        startTime = GetSecs; % Initialize timing
        keyPressed = false; % To track if the key was pressed
        
        while (GetSecs - startTime < visualDisplayTime) % During image display time
            if (t <= auditoryNumTrials) && ... % If current auditory tone t is within total number of auditory tones designed to play
            ((t == 1 && GetSecs - experimentStartTime >= auditorySequence.time(t, subjectIDnumberConverted)) || ... % If it's time to play the tone, i.e. current time >= time we've designed the tone to be played at 
            (t > 1 && ~loadingPreviousData && GetSecs - experimentStartTime - clicktrainDataASSR.onsetTime(t-1) >= auditoryISIMatrixMilliseconds(subjectIDnumberConverted, t)/1000 + clicktrainLengthSeconds ) || ... % If the auditory ISI has passed, play next tone       
            (loadingPreviousData && t == last_saved_tone_from_saved_file + 1 && GetSecs - experimentStartTime - clicktrainDataASSR.onsetTime(t-1) + last_saved_time_from_saved_file >=auditoryISIMatrixMilliseconds(subjectIDnumberConverted, t)/1000 + clicktrainLengthSeconds ) || ... % Additional logic for when we're reloading a previous saved file
            (loadingPreviousData && t > last_saved_tone_from_saved_file + 1 && GetSecs - experimentStartTime - clicktrainDataASSR.onsetTime(t-1) >= auditoryISIMatrixMilliseconds(subjectIDnumberConverted, t)/1000 + clicktrainLengthSeconds )) % Additional logic for when we're reloading a previous save file

                whichSound = auditorySequence.sound(t, subjectIDnumberConverted); % Gets index of correct sound to play given current t value and unique subject ID
                
                % Play the relevant sound file
                
                % Send MEG trigger
                if strcmp(mode,'meg')
                    io64(io,port,data.auditoryTriggerList(whichSound));
                    WaitSecs(triggerDuration);
                    io64(io, port, 0);
                    fprintf('Auditory Trigger: %d\n',data.auditoryTriggerList(whichSound))
                end
                
                % Record clicktrain data
                clicktrainDataASSR.onsetTime(t) = GetSecs - experimentStartTime;
                clicktrainDataASSR.machineOnsetTime(t) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                clicktrainDataASSR.trialNumber(t) = t;
                t = t + 1; % Update auditory trial index
                
            end
            
            [keyIsDown, ~, keyCode] = KbCheck(); % Check if any key is pressed
            while keyIsDown && ~keyPressed % Check if the key is pressed and hasn't been processed yet
                if keyCode(KbName('RightArrow')) % Check if the "RightArrow" key is pressed
                    
                    % Subject has responded, so response number tracker
                    numResponses = numResponses + 1;
                    
                    % Record the response data that does not depend on
                    % whether correct, false, or late reaction
                    allResponseTimes.imageFileName{numResponses} = current_filename;
                    allResponseTimes.trialType{numResponses} = trialTypeNames{i, subjectIDnumberConverted};
                    allResponseTimes.trialSequenceNumeric{numResponses} = current_order;
                    allResponseTimes.trialSequenceAlphabetic{numResponses} = char(64 + current_order);
                    allResponseTimes.globalTime(numResponses) = GetSecs - experimentStartTime;
                    allResponseTimes.machineGlobalTime(numResponses) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                    allResponseTimes.trialNumber(numResponses) = i;
                    
                    if canScore(j) == true
                        % Check if current image is a repeat
                        if j > 1 && current_order(j) == current_order(j-1) % Check if the image is repeated
                            points = points + 1; % Gain a point
                            youScored = true; % To track whether they scored or not
                            
                            % Send MEG trigger to say subject responded correctly!
                            if strcmp(mode,'meg')
                                io64(io,port,40);
                                WaitSecs(triggerDuration);
                                io64(io, port, 0);
                            end
                            
                            % Subject has responded correctly to current
                            % stimuli so update response times
                            allResponseTimes.reactionTime(numResponses) = (GetSecs - experimentStartTime) - imageData.onsetTime((i-1)*24 + j);
                            allResponseTimes.imageNumber(numResponses) = j;
                            allResponseTimes.correct(numResponses) = 1; % Record that subject responded correctly
                            
                            % Check if previous image was a repeat and if this is a
                            % late response, but still within the reaction time
                            % window
                        elseif j > 2 && canScore(j-1) == 1 && j ~= 5 && current_order(j-1) == current_order(j-2) && GetSecs - startTime < reactionTimeWindow - visualDisplayTime - isi % Check if the image is repeated
                            points = points + 1; % Gain a point
                            youScored = true; % To track whether they scored or not
                            
                            % Send MEG trigger to say subject responded correctly!
                            if strcmp(mode,'meg')
                                io64(io,port,40);
                                WaitSecs(triggerDuration);
                                io64(io, port, 0);
                            end
                            
                            % Subject has responded correctly to previous stimuli so update response times
                            
                            allResponseTimes.reactionTime(numResponses) = (GetSecs - experimentStartTime) - imageData.onsetTime((i-1)*24 + j-1);
                            allResponseTimes.imageNumber(numResponses) = j-1;
                            allResponseTimes.correct(numResponses) = 1; % Record that subject responded correctly
                            allResponseTimes.late(numResponses) = 1; % Record that subject responded late
                            
                        else
                            points = max(points - 1, 0); % Lose a point but not below 0
                            
                            % Send MEG trigger to say subject responded incorrectly!
                            if strcmp(mode,'meg')
                                io64(io,port,41);
                                WaitSecs(triggerDuration);
                                io64(io, port, 0);
                            end
                            
                            % Subject has responded incorrectly to current
                            % stimuli so update response times
                            allResponseTimes.reactionTime(numResponses) = (GetSecs - experimentStartTime) - imageData.onsetTime((i-1)*24 + j);
                            allResponseTimes.imageNumber(numResponses) = j;
                            allResponseTimes.correct(numResponses) = 0; % Record that subject responded incorrectly
                            
                        end
                        keyPressed = true; % Set the key pressed flag
                        canScore(j) = 0; % Set canScore to false
                        
                        % Immediately draw the updated points
                        Screen('FillRect', window, white); % Clear the window
                        drawPoints(window, points); % Draw updated points
                        image_to_texture = Screen('MakeTexture', window, current_image); % Prepare the current image
                        Screen('DrawTexture', window, image_to_texture, [], dstRect, 0, [], 1); % Draw the current image
                        Screen('Flip', window); % Update the display with the new points and image
                    end
                    
                elseif keyCode(KbName('CAPSLOCK')) % Check for 'CAPSLOCK' key
                    isPaused = ~isPaused; % Toggle pause state
                    if isPaused
                        % Show pause message
                        Screen('FillRect', window, white);
                        Screen('DrawTexture', window, pausedScreen, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
                        Screen('Flip', window);
                        WaitSecs(0.5); % Prevent auto-advancing
                        
                        % Wait for unpause
                        while true
                            [keyIsDown, ~, keyCode] = KbCheck();
                            if keyIsDown && keyCode(KbName('CAPSLOCK'))
                                WaitSecs(0.5); % Prevent multiple toggles
                                
                                % Wait for key to be released
                                while KbCheck
                                    WaitSecs(0.1);
                                end
                                
                                % Clean up before restarting
                                sca;
                                
                                % Simple pause to clear any key presses
                                WaitSecs(0.1);
                                
                                % Restart the script using its own filename
                                run(current_script);
                                return;
                            end
                        end
                    end
                    keyPressed = true; % Set the key pressed flag
                    
                elseif keyCode(KbName('ESCAPE')) % Check if the "ESCAPE" key is pressed
                    repeatExercise = false; % To break out of the inner while loop
                    break
                
                else
                    keyPressed = true; % Set the key pressed flag
                end
                %             elseif ~keyIsDown
                %                 keyPressed = false; % Reset the flag if the key is released
            end
        end
        
        % To break out of the j for loop
        if repeatExercise == false
            break
        end
        
        %% IQI WHILE LOOP
        
        % IQI = inter-quartet interval, occurs after every quartet (i.e. 4
        % images) 
        
        % Reset tracking variables for next while loop
        startTime = GetSecs; % Initialize timing
        keyPressed = false; % To track if the key was pressed
        
        % Show a white screen with centre fixation cross after every
        % quartet (every 4th image) for inter quartet interval
        if mod(j, 4) == 0 % If we're at the end of a quartet
            
            Screen('DrawTexture', window, texture_FixationCrossWhite, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
            drawPoints(window, points); % Re-add the points in black text to show on the white screen
            Screen('Flip', window);
            
            iqi = visualIQImatrixSeconds(whichIQI, subjectIDnumberConverted); % isi_matrix_seconds is an visualNumTrials by 8 (for the 8 images in each trial) by 80 matrix (80 for each of the 80 study subjects); subjectID_number specifies which unique sequence of ISIs to use given the subject's unique ID
            whichIQI = whichIQI + 1; 
            
            while (GetSecs - startTime < iqi) % During the inter-quartet interval
                if (t <= auditoryNumTrials) && ... % Same logic as for the visual display while loop
                ((t == 1 && GetSecs - experimentStartTime >= auditorySequence.time(t, subjectIDnumberConverted)) || ...
                (t > 1 && ~loadingPreviousData && GetSecs - experimentStartTime - clicktrainDataASSR.onsetTime(t-1) >= auditoryISIMatrixMilliseconds(subjectIDnumberConverted, t)/1000 + clicktrainLengthSeconds ) || ...        
                (loadingPreviousData && t == last_saved_tone_from_saved_file + 1 && GetSecs - experimentStartTime - clicktrainDataASSR.onsetTime(t-1) + last_saved_time_from_saved_file >=auditoryISIMatrixMilliseconds(subjectIDnumberConverted, t)/1000 + clicktrainLengthSeconds ) || ...
                (loadingPreviousData && t > last_saved_tone_from_saved_file + 1 && GetSecs - experimentStartTime - clicktrainDataASSR.onsetTime(t-1) >= auditoryISIMatrixMilliseconds(subjectIDnumberConverted, t)/1000 + clicktrainLengthSeconds ))
                    whichSound = auditorySequence.sound(t, subjectIDnumberConverted); % Gets index of correct sound to play given current t value and unique subject ID
                    
                    % Play the relevant sound file
                    
                    % Send MEG trigger
                    if strcmp(mode,'meg')
                        io64(io,port,data.auditoryTriggerList(whichSound));
                        WaitSecs(triggerDuration);
                        io64(io, port, 0);
                    end
                    
                    clicktrainDataASSR.onsetTime(t) = GetSecs - experimentStartTime;
                    clicktrainDataASSR.machineOnsetTime(t) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                    clicktrainDataASSR.trialNumber(t) = t;
                    if t>1 && clicktrainDataASSR.onsetTime(t)-clicktrainDataASSR.onsetTime(t-1)<.9
                        warning('ITI: %.4f for trial %d\n', clicktrainDataASSR.onsetTime(t)-clicktrainDataASSR.onsetTime(t-1),j);
                    elseif t>1
                        fprintf('ITI: %.4f for trial %d\n', clicktrainDataASSR.onsetTime(t)-clicktrainDataASSR.onsetTime(t-1),j);
                    end
                    t = t + 1; % Update auditory trial index
                end
                
                [keyIsDown, ~, keyCode] = KbCheck(); % Check if any key is pressed
                while keyIsDown && ~keyPressed % Check if the key is pressed and hasn't been processed yet
                    if keyCode(KbName('RightArrow')) % Check if the "1" key is pressed
                        % Subject has responded, so response number tracker
                        numResponses = numResponses + 1;
                        
                        % Record the response data that does not depend on
                        % whether correct, false, or late reaction
                        allResponseTimes.imageFileName{numResponses} = current_filename;
                        allResponseTimes.trialType{numResponses} = trialTypeNames{i, subjectIDnumberConverted};
                        allResponseTimes.trialSequenceNumeric{numResponses} = current_order;
                        allResponseTimes.trialSequenceAlphabetic{numResponses} = char(64 + current_order);
                        allResponseTimes.globalTime(numResponses) = GetSecs - experimentStartTime;
                        allResponseTimes.machineGlobalTime(numResponses) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                        allResponseTimes.trialNumber(numResponses) = i;
                        
                        if canScore(j) == true
                            if j > 1 && current_order(j) == current_order(j-1)... % Check if the image is repeated
                                    && GetSecs - startTime < reactionTimeWindow - visualDisplayTime % And we are still within the remaining reaction time window
                                
                                points = points + 1; % Gain a point
                                canScore(j) = 0;
                                youScored = true; % To track that they scored
                                
                                % Send MEG trigger to say subject responded correctly!
                                if strcmp(mode,'meg')
                                    io64(io,port,40);
                                    WaitSecs(triggerDuration);
                                    io64(io, port, 0);
                                end
                                
                                
                                % Subject has responded correctly to current
                                % stimuli so update response times
                                allResponseTimes.reactionTime(numResponses) = (GetSecs - experimentStartTime) - imageData.onsetTime((i-1)*24 + j);
                                allResponseTimes.imageNumber(numResponses) = j;
                                allResponseTimes.correct(numResponses) = 1; % Record that subject responded correctly
                                
                            else
                                points = max(points - 1, 0); % Lose a point but not below 0
                                
                                % Send MEG trigger to say subject responded incorrectly!
                                if strcmp(mode,'meg')
                                    io64(io,port,41);
                                    WaitSecs(triggerDuration);
                                    io64(io, port, 0);
                                end
                                
                                
                                % Subject has responded incorrectly to current
                                % stimuli so update response times
                                allResponseTimes.reactionTime(numResponses) = (GetSecs - experimentStartTime) - imageData.onsetTime((i-1)*24 + j);
                                allResponseTimes.imageNumber(numResponses) = j;
                                allResponseTimes.correct(numResponses) = 0; % Record that subject responded incorrectly
                                
                            end
                        end
                        keyPressed = true; % Set the key pressed flag
                        
                        % Immediately draw the updated points
                        Screen('DrawTexture', window, texture_FixationCrossWhite, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
                        drawPoints(window, points); % Re-add the points so it doesn't jarringly disappear during white screen
                        Screen('Flip', window); % Flip to show the white screen with points added
                        
                    elseif keyCode(KbName('CAPSLOCK')) % Check for 'CAPSLOCK' key

                    isPaused = ~isPaused; % Toggle pause state
                    if isPaused
                        % Show pause message
                        Screen('FillRect', window, white);
                        Screen('DrawTexture', window, pausedScreen, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
                        Screen('Flip', window);
                        WaitSecs(0.5); % Prevent auto-advancing
                        
                        % Wait for unpause
                        while true
                            [keyIsDown, ~, keyCode] = KbCheck();
                            if keyIsDown && keyCode(KbName('CAPSLOCK'))
                                WaitSecs(0.5); % Prevent multiple toggles
                                
                                % Wait for key to be released
                                while KbCheck
                                    WaitSecs(0.1);
                                end
                                
                                % Clean up before restarting
                                sca;
                                
                                % Simple pause to clear any key presses
                                WaitSecs(0.1);
                                
                                % Restart the script using its own filename
                                run(current_script);
                                return;
                            end
                        end
                    end
                    keyPressed = true; % Set the key pressed flag
                    
                    elseif keyCode(KbName('ESCAPE')) % Check if the "ESCAPE" key is pressed
                        repeatExercise = false; % To break out of the inner while loop
                        break
                        
                    else
                        keyPressed = true; % Set the key pressed flag

                    end
                    
                end
                
                if GetSecs - startTime > reactionTimeWindow - visualDisplayTime % Reaction time window has expired, so now we can display update screens
                
                    %% YOU MISSED / YOU GOT IT SCREEN

                    % Show "You Missed" if subject responded incorrectly to
                    % the repeat image
                    if any(diff(current_order(j-3:j)) == 0) ... % If current quartet contains the same image number twice in a row (i.e. there's a repeat image)
                            && youScored == false % And if subject did not score

                        % Show "You Missed" screen
                        Screen('DrawTexture', window, texture_FixationCrossWhiteYouMissed, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
                        drawPoints(window, points); % Re-add the points in black text to show on the white screen
                        Screen('Flip', window);

                    % Show "You Got It!" if subject responded correctly to
                    % the repeat image
                    elseif any(diff(current_order(j-3:j)) == 0) ... % If current quartet contains the same image number twice in a row (i.e. there's a repeat image)
                            && youScored == true % And if subject did score

                        % Show "You Got It!" screen
                        Screen('DrawTexture', window, texture_FixationCrossWhiteYouGotIt, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
                        drawPoints(window, points); % Re-add the points in black text to show on the white screen
                        Screen('Flip', window);

                    %% PERCENTAGE COMPLETE SCREEN

                    elseif i >= visualNumTrials * 0.25 && ~twentyFivePercentComplete && j < 5
                        
                        twentyFivePercentCompleteFlag = true; % Set the 25% complete tracker to true so we don't show the screen again

                        % Show "25% Complete!" screen
                        Screen('DrawTexture', window, texture_FixationCross25PercentComplete, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
                        drawPoints(window, points); % Re-add the points in black text to show on the white screen
                        Screen('Flip', window);

                    elseif i >= visualNumTrials * 0.5 && ~fiftyPercentComplete && j < 5
                        
                        fiftyPercentCompleteFlag = true; % Set the 50% complete tracker to true so we don't show the screen again

                        % Show "50% Complete!" screen
                        Screen('DrawTexture', window, texture_FixationCross50PercentComplete, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
                        drawPoints(window, points); % Re-add the points in black text to show on the white screen
                        Screen('Flip', window); 

                    elseif i >= visualNumTrials * 0.75 && ~seventyFivePercentComplete && j < 5
                        
                        seventyFivePercentCompleteFlag = true; % Set the 75% complete tracker to true so we don't show the screen again

                        % Show "75% Complete!" screen
                        Screen('DrawTexture', window, texture_FixationCross75PercentComplete, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
                        drawPoints(window, points); % Re-add the points in black text to show on the white screen
                        Screen('Flip', window);

                    else
                        Screen('DrawTexture', window, texture_FixationCrossWhite, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
                        drawPoints(window, points); % Re-add the points in black text to show on the white screen
                        Screen('Flip', window);

                    end
                                        
                end
                
            end
                        
        %% ISI WHILE LOOP
            
        else
            Screen('DrawTexture', window, texture_FixationCrossWhite, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
            drawPoints(window, points); % Re-add the points so it doesn't jarringly disappear during white screen
            Screen('Flip', window); % Flip to show the fixation cross screen
                        
            % Calculate the jittered isi
            isi = visualISIMatrixSeconds(i, j, subjectIDnumberConverted); % isi_matrix_seconds is an visualNumTrials by 8 (for the 8 images in each trial) by 80 matrix (80 for each of the 80 study subjects); subjectID_number specifies which unique sequence of ISIs to use given the subject's unique ID
            while (GetSecs - startTime < isi) % During the visual inter stimulus interval
                if (t <= auditoryNumTrials) && ... % Same logic as for the visual display while loop and iqi while loop
                ((t == 1 && GetSecs - experimentStartTime >= auditorySequence.time(t, subjectIDnumberConverted)) || ...
                (t > 1 && ~loadingPreviousData && GetSecs - experimentStartTime - clicktrainDataASSR.onsetTime(t-1) >= auditoryISIMatrixMilliseconds(subjectIDnumberConverted, t)/1000 + clicktrainLengthSeconds ) || ...        
                (loadingPreviousData && t == last_saved_tone_from_saved_file + 1 && GetSecs - experimentStartTime - clicktrainDataASSR.onsetTime(t-1) + last_saved_time_from_saved_file >=auditoryISIMatrixMilliseconds(subjectIDnumberConverted, t)/1000 + clicktrainLengthSeconds ) || ...
                (loadingPreviousData && t > last_saved_tone_from_saved_file + 1 && GetSecs - experimentStartTime - clicktrainDataASSR.onsetTime(t-1) >= auditoryISIMatrixMilliseconds(subjectIDnumberConverted, t)/1000 + clicktrainLengthSeconds ))
                    whichSound = auditorySequence.sound(t, subjectIDnumberConverted); % Gets index of correct sound to play given current t value and unique subject ID
                    
                    % Play the relevant sound file
                    
                    % Send MEG trigger
                    if strcmp(mode,'meg')
                        io64(io,port,data.auditoryTriggerList(whichSound));
                        WaitSecs(triggerDuration);
                        io64(io, port, 0);
                    end
                    
                    clicktrainDataASSR.onsetTime(t) = GetSecs - experimentStartTime;
                    clicktrainDataASSR.machineOnsetTime(t) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                    clicktrainDataASSR.trialNumber(t) = t;
                    if t>1 && clicktrainDataASSR.onsetTime(t)-clicktrainDataASSR.onsetTime(t-1)<.9
                        warning('ITI: %.4f for trial %d\n', clicktrainDataASSR.onsetTime(t)-clicktrainDataASSR.onsetTime(t-1),j);
                    elseif t>1
                        fprintf('ITI: %.4f for trial %d\n', clicktrainDataASSR.onsetTime(t)-clicktrainDataASSR.onsetTime(t-1),j);
                    end
                    t = t + 1; % Update auditory trial index
                end
                
                [keyIsDown, ~, keyCode] = KbCheck(); % Check if any key is pressed
                while keyIsDown && ~keyPressed % Check if the key is pressed and hasn't been processed yet
                    if keyCode(KbName('RightArrow')) % Check if the "1" key is pressed
                        % Subject has responded, so response number tracker
                        numResponses = numResponses + 1;
                        
                        % Record the response data that does not depend on
                        % whether correct, false, or late reaction
                        allResponseTimes.imageFileName{numResponses} = current_filename;
                        allResponseTimes.trialType{numResponses} = trialTypeNames{i, subjectIDnumberConverted};
                        allResponseTimes.trialSequenceNumeric{numResponses} = current_order;
                        allResponseTimes.trialSequenceAlphabetic{numResponses} = char(64 + current_order);
                        allResponseTimes.globalTime(numResponses) = GetSecs - experimentStartTime;
                        allResponseTimes.machineGlobalTime(numResponses) = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
                        allResponseTimes.trialNumber(numResponses) = i;
                        
                        if canScore(j) == true
                            if j > 1 && current_order(j) == current_order(j-1) % Check if the image is repeated
                                points = points + 1; % Gain a point
                                canScore(j) = 0;
                                
                                % Send MEG trigger to say subject responded correctly!
                                if strcmp(mode,'meg')
                                    io64(io,port,40);
                                    WaitSecs(triggerDuration);
                                    io64(io, port, 0);
                                end
                                
                                % Subject has responded correctly to current
                                % stimuli so update response times
                                allResponseTimes.reactionTime(numResponses) = (GetSecs - experimentStartTime) - imageData.onsetTime((i-1)*24 + j);
                                allResponseTimes.imageNumber(numResponses) = j;
                                allResponseTimes.correct(numResponses) = 1; % Record that subject responded correctly
                                
                            else
                                points = max(points - 1, 0); % Lose a point but not below 0
                                
                                % Send MEG trigger to say subject responded incorrectly!
                                if strcmp(mode,'meg')
                                    io64(io,port,41);
                                    WaitSecs(triggerDuration);
                                    io64(io, port, 0);
                                end
                                
                                % Subject has responded incorrectly to current
                                % stimuli so update response times
                                allResponseTimes.reactionTime(numResponses) = (GetSecs - experimentStartTime) - imageData.onsetTime((i-1)*24 + j);
                                allResponseTimes.imageNumber(numResponses) = j;
                                allResponseTimes.correct(numResponses) = 0; % Record that subject responded incorrectly
                                
                            end
                        end
                        keyPressed = true; % Set the key pressed flag
                        
                        % Immediately draw the updated points
                        Screen('DrawTexture', window, texture_FixationCrossWhite, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
                        drawPoints(window, points); % Re-add the points so it doesn't jarringly disappear during white screen
                        Screen('Flip', window); % Flip to show the black screen
                        
                    elseif keyCode(KbName('CAPSLOCK')) % Check for 'CAPSLOCK' key

                    isPaused = ~isPaused; % Toggle pause state
                    if isPaused
                        % Show pause message
                        Screen('FillRect', window, white);
                        Screen('DrawTexture', window, pausedScreen, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
                        Screen('Flip', window);
                        WaitSecs(0.5); % Prevent auto-advancing
                        
                        % Wait for unpause
                        while true
                            [keyIsDown, ~, keyCode] = KbCheck();
                            if keyIsDown && keyCode(KbName('CAPSLOCK'))
                                WaitSecs(0.5); % Prevent multiple toggles
                                
                                % Wait for key to be released
                                while KbCheck
                                    WaitSecs(0.1);
                                end
                                
                                % Clean up before restarting
                                sca;
                                
                                % Simple pause to clear any key presses
                                WaitSecs(0.1);
                                
                                % Restart the script using its own filename
                                run(current_script);
                                return;
                            end
                        end
                    end
                    keyPressed = true; % Set the key pressed flag

                    elseif keyCode(KbName('ESCAPE')) % Check if the "ESCAPE" key is pressed
                        repeatExercise = false; % To break out of the inner while loop
                        break
                        
                    else
                        keyPressed = true;

                    end
                    %                 elseif ~keyIsDown
                    %                     keyPressed = false; % Reset the flag if the key is released
                end
                
            end
            
        end
        
        % To break out of the j for loop
        if repeatExercise == false
            break
        end
        
    end
    
    %% END OF TRIAL
    
    % Send MEG trigger to say trial ended!
    if strcmp(mode,'meg')
        io64(io,port,8);
        WaitSecs(triggerDuration);
        io64(io, port, 0);
    end
    
    %% UPDATE PERCENT COMPLETE FLAGS

    % Gotta update these outside the loop otherwise it
    % messes up the whole logic condition annoyingly 

    if twentyFivePercentCompleteFlag && twentyFivePercentComplete == false
        twentyFivePercentComplete = true;
    end

    if fiftyPercentCompleteFlag && fiftyPercentComplete == false
        fiftyPercentComplete = true;
    end

    if seventyFivePercentCompleteFlag && seventyFivePercentComplete == false
        seventyFivePercentComplete = true;
    end
    
    %% SAVE TRIAL DATA
    
    last_saved_trial = i;
    last_saved_points = points;
    last_saved_numResponses = numResponses; % Save numResponses in case of reboot / pause
    
    if t <= 1
        last_saved_tone = 0;
        last_saved_time = 0;
    else
        last_saved_tone = t-1;
        if exist('last_saved_time', 'var')
            last_saved_time = last_saved_time_from_saved_file + clicktrainDataASSR.onsetTime(t-1);
        else
            last_saved_time = clicktrainDataASSR.onsetTime(t-1);
        end
    end
    
    scoringData.points = points; % Save points scored 
    
    filename = sprintf('savedASSRData%04d.mat', subjectIDnumberConverted);
    save(fullfile(current_dir, 'subjectDataSaved', filename), 'imageData', 'scoringData', 'allResponseTimes', 'clicktrainDataASSR', ...
        'last_saved_trial', 'last_saved_tone', 'last_saved_time', 'last_saved_points', 'last_saved_numResponses', 'data', 'whichIQI', 'twentyFivePercentComplete', 'fiftyPercentComplete', 'seventyFivePercentComplete', '-v7');
        
    % To break out of the i for loop
    if repeatExercise == false
        break
    end
    
end

%% END OF EXPERIMENTAL BLOCK

% Send MEG trigger to say experiment ended!
if strcmp(mode,'meg')
    io64(io,port,255);
    WaitSecs(triggerDuration);
    io64(io, port, 0);
end

scoringData.blockCompleted = true; % Update that we've completed the experimental block

%% WAIT SCREEN 
    
% Set up final waiting screen with fixation cross and "please relax and focus on the cross" message

finalWaitingScreen_location = fullfile(current_dir, 'instructions', 'instructions', 'finalWaitingScreen.jpg');
matrix_finalWaitingScreen = imread(finalWaitingScreen_location);
texture_finalWaitingScreen = Screen('MakeTexture', window, matrix_finalWaitingScreen);

% Show screen

Screen('DrawTexture', window, texture_finalWaitingScreen, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window); % Flip to show the fixation cross screen

WaitSecs(5); % Wait 5 seconds
   
%% SAVE AGAIN

% Save in ASSR folder

save(fullfile(current_dir, 'subjectDataSaved', filename), 'imageData', 'scoringData', 'allResponseTimes', 'clicktrainDataASSR', ...
    'last_saved_trial', 'last_saved_tone', 'last_saved_time', 'last_saved_points', 'last_saved_numResponses', 'data', 'whichIQI', 'twentyFivePercentComplete', 'fiftyPercentComplete', 'seventyFivePercentComplete', '-v7');

% Save again in subjectData folder (where subject's data will be saved for all paradigms in one place)
subjectDataDir = fullfile(root_dir, '..', 'subjectData', ['COMPS' sprintf('%04d', subjectIDnumberConverted)]);

if ~exist(subjectDataDir, 'dir')
    mkdir(subjectDataDir);
end
save(fullfile(subjectDataDir, filename), 'imageData', 'scoringData', 'allResponseTimes', 'clicktrainDataASSR', ...
    'last_saved_trial', 'last_saved_tone', 'last_saved_time', 'last_saved_points', 'last_saved_numResponses', 'data', 'whichIQI', 'twentyFivePercentComplete', 'fiftyPercentComplete', 'seventyFivePercentComplete', '-v7');

disp('Subject data saved!');

%% SHOW FINAL SCORE

% Count number of distractors (trials where trialType is "distractor")
numDistractors = 3; % As programmed in the design file

% Create final score screen
Screen('FillRect', window, white);
finalScoreText = sprintf('You scored: %d / %d', points, numDistractors);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

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

%% Repeat or Continue?

% Draw instructions screen 5
start_img5_location = fullfile('instructions','instructions','repeat_or_continue.jpg');
start_img2 = imread(start_img5_location);
start_texture2 = Screen('MakeTexture', window, start_img2);
Screen('DrawTexture', window, start_texture2, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);

    keyPressed = false; % Reset the key pressed flag
    while true
        [keyIsDown, ~, keyCode] = KbCheck(); % Check for key press
        if keyIsDown
            if keyCode(KbName('LeftArrow')) % Check if "1" is pressed
                KbReleaseWait % Wait for button to be released, otherwise button press will carry over to the repeat exercise 
                repeatExercise = true; % Set flag to repeat the exercise
                sca;
                break; % Exit the loop
            elseif keyCode(KbName('RightArrow')) % Check if "2" is pressed
                KbReleaseWait % Wait for button to be released, otherwise button press will carry over to next slide
                repeatExercise = false; % Set flag to continue
                break; % Exit the loop
            end
        end
    end
end

%% End Screen

% Display instruction slide 7 
slide_location = fullfile('instructions','instructions','Slide7.jpg');
slide_image = imread(slide_location);
slide_as_texture = Screen('MakeTexture', window, slide_image);

Screen('DrawTexture', window, slide_as_texture, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
waitForRightArrow()

sca; % Close the screen

%% CLOSE EVERYTHING

Screen('CloseAll') % Close all off-screen images
sca; % Close the screen
