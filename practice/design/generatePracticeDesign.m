%% Clear workspace
clear all;
close all;

%% Get current directory

% Get the directory where this script is located
scriptDirectory = fileparts(mfilename('fullpath'));

% Change to that directory
cd(scriptDirectory);

%% General Parameters

numSubjects = 400; % How many subjects will be participating in the study 
rng(111); % Set seed for reproducibility 

%% Visual Parameters

% Number of trials and trial types

visualNumTrials = 6; 
numASSRstandard6Quartets = 6;
numASSRdeviant4Quartets = 0;
numASSRdeviant5Quartets = 0;
numASSRdeviant6Quartets = 0;
numASSRdistractorQuartets = 0; % We manually add 3 distractors later on

%% Duration parameters

visualDisplayTime = 0.9; % how long each image is displayed for (seconds) 
visualISIRange = [80, 120]; % inter-stimulus-interval between images (milliseconds), uniformly jittered
visualInterQuartetIntervalRange = [1.6, 1.8]; % interval pause between quartets in the same pair (seconds)
reactionTimeWindow = 2; % Time window within which subject must respond to a two-in-a-row image (seconds)

%% Number of images

numImages = visualNumTrials * 4; % Total number of images for this experimental block. Each trial contains 4 unique images 

%% Same or unique trial sequences for subjects?

% Define whether all subjects should have the same visual trial sequence (i.e. predictable, distractor, mismatch, etc.)
sameVisualTrialSequence = false; % True means one trial sequence for everyone, false means unique sequence for each subject

% Define whether all subjects should have the same visual ISI sequence
sameVisualISIsequence = false; % True means one visual ISI sequence for everyone, false means unique sequence for each subject

%% Generate Image Sequence

% Create a pseudorandomised image sequence for each subject, so images are
% displayed in different orders across subjects

% Randomise a sequence of images indices for all subjects
% We'll then pick out a specific randomised sequence for each unique
% subject in the main run script 

% Preallocate matrix 
randomIndicesMatrix = zeros(numSubjects, numImages);

for i = 1:numSubjects
    randomIndicesMatrix(i, :) = randperm(visualNumTrials * 4);  % Generate random indices and store in each row
end

%% Define image order for all trial sequence types

% Standard sequence types 
% Standard sequences just repeat the images in same order across all quartets that make up the trial

standardSequenceSixQuartets = [1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4]; % ABCD ABCD ABCD ABCD ABCD ABCD

% Standard six quartets, plus a distractor at the end
standardSequenceSixQuartetsPlusDistractor = [1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 3]; % ABCD ABCD ABCD ABCD ABCD ABCD ABCC

% Standard three quartets, plus a distractor at the end
standardSequenceThreeQuartetsPlusDistractor = [1 2 3 4 1 2 3 4 1 2 3 4 1 1 2 3]; % ABCD ABCD ABCD AABC

% Deviant sequence types 
% Deviant sequences will switch the order of the 3rd and 4th images in the last quartet of the sequence

deviantSequenceFourQuartets = [1 2 3 4 1 2 3 4 1 2 3 4 1 2 4 3]; % ABCD ABCD ABCD ABDC
deviantSequenceFiveQuartets = [1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 4 3]; % ABCD ABCD ABCD ABCD ABDC
deviantSequenceSixQuartets = [1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4 1 2 4 3]; % ABCD ABCD ABCD ABCD ABDC                

% Distractor sequence types 
% Note: distractors are only ever one quartet and feature a repeat image that subjects must spot and respond to as quickly as possible via button press.

distractorOrders = [1 1 2 3;  % AABC
                     1 2 2 3;  % ABBC 
                     1 2 3 3]; % ABCC

%% Create trial sequence for each subject

% We're going to create a pseudorandomised trial sequence for each subject, so trials are
% displayed in different orders across subjects

% First initialize matrices for image orders for each trial

imageOrdersForEachTrial = zeros(visualNumTrials, 24, numSubjects); % 24 because the longest sequence is 6 quartets * 4

% Create matrix of trial type names with correct number of each trial type and then shuffle

baseTrialTypes = [
    repmat({'standardSequenceSixQuartets'}, 1, numASSRstandard6Quartets), ...
    repmat({'deviantSequenceFourQuartets'}, 1, numASSRdeviant4Quartets), ...
    repmat({'deviantSequenceFiveQuartets'}, 1, numASSRdeviant5Quartets), ...
    repmat({'deviantSequenceSixQuartets'}, 1, numASSRdeviant6Quartets), ...
    repmat({'distractor'}, 1, numASSRdistractorQuartets)
];

shuffledTypes = baseTrialTypes(randperm(length(baseTrialTypes)));
trialTypeNames = repmat(shuffledTypes', 1, numSubjects);

trialTypeNames(1, :) = {'distractor'};
trialTypeNames(4, :) = {'standardSequenceSixQuartetsPlusDistractor'};
trialTypeNames(6, :) = {'standardSequenceThreeQuartetsPlusDistractor'};

% Fill in image orders for each trial based on trial type names
for subject = 1:numSubjects
    for trial = 1:visualNumTrials
        switch trialTypeNames{trial, subject}
            case 'standardSequenceSixQuartets'
                imageOrdersForEachTrial(trial, 1:length(standardSequenceSixQuartets), subject) = standardSequenceSixQuartets;
            case 'deviantSequenceFourQuartets'
                imageOrdersForEachTrial(trial, 1:length(deviantSequenceFourQuartets), subject) = deviantSequenceFourQuartets;
            case 'deviantSequenceFiveQuartets'
                imageOrdersForEachTrial(trial, 1:length(deviantSequenceFiveQuartets), subject) = deviantSequenceFiveQuartets;
            case 'deviantSequenceSixQuartets'
                imageOrdersForEachTrial(trial, 1:length(deviantSequenceSixQuartets), subject) = deviantSequenceSixQuartets;
            case 'distractor'
                distractorIndex = randi(size(distractorOrders, 1));
                imageOrdersForEachTrial(trial, 1:size(distractorOrders, 2), subject) = distractorOrders(distractorIndex, :);
            case 'standardSequenceSixQuartetsPlusDistractor' 
                imageOrdersForEachTrial(trial, 1:length(standardSequenceSixQuartetsPlusDistractor), subject) = standardSequenceSixQuartetsPlusDistractor;
            case 'standardSequenceThreeQuartetsPlusDistractor' 
                imageOrdersForEachTrial(trial, 1:length(standardSequenceThreeQuartetsPlusDistractor), subject) = standardSequenceThreeQuartetsPlusDistractor;
        end
    end
end

%% Generate Visual ISI Sequence

% Generate predetermined sequence of pseudo-randomised ISIs for each subject 

if sameVisualISIsequence == true
    % Generate one sequence and repeat it for all subjects
    baseISISequence = visualISIRange(1) + (visualISIRange(2) - visualISIRange(1)) * rand(visualNumTrials, 28);
    visualISIMatrixMilliseconds = repmat(baseISISequence, [1, 1, numSubjects]);
else
    % Generate different sequences for each subject (original behavior)
    visualISIMatrixMilliseconds = visualISIRange(1) + (visualISIRange(2) - visualISIRange(1)) * rand(visualNumTrials, 28, numSubjects);
end

% Convert to seconds
visualISIMatrixSeconds = visualISIMatrixMilliseconds / 1000;

% Set ISIs to 0 at the end of each quartet (there shouldn't be an ISI after the 4th image of a quartet; that should be the IQI, inter-quartet interval)

visualISIMatrixSeconds(:, 4, :) = 0;  % End of first quartet
visualISIMatrixSeconds(:, 8, :) = 0;  % End of second quartet
visualISIMatrixSeconds(:, 12, :) = 0; % End of third quartet
visualISIMatrixSeconds(:, 16, :) = 0; % End of fourth quartet
visualISIMatrixSeconds(:, 20, :) = 0; % End of fifth quartet
visualISIMatrixSeconds(:, 24, :) = 0; % End of sixth quartet
visualISIMatrixSeconds(:, 28, :) = 0; % End of seventh quartet

%% Generate Visual IQI Sequence

visualIQImatrixSeconds = visualInterQuartetIntervalRange(1) + (visualInterQuartetIntervalRange(2) - visualInterQuartetIntervalRange(1)) * rand(visualNumTrials*6, numSubjects);

%% AUDITORY 

auditoryNumTrials = 0;

%% SAVE DATA

save('practiceDesign.mat');