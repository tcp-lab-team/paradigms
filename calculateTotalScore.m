% Script to calculate total scores across all paradigms

%% CLEANING

clear all 

%% GET SUBJECT ID
% Subject ID is entered via the GUI; we need to retrieve it
load('subjectIDNumber.mat'); % The GUI saves most recent subject's ID number here

% Concatenate "COMPS_" with the subject ID number for full subject ID
subjectIDFull = ['COMPS_' sprintf('%04s', subjectIDNumber)]; % For final subject ID e.g. COMPS_0044

%% INITIALISE VARIABLES

ASSRPoints = 0;
MMNPart1Points = 0;
MMNPart2Points = 0;
P50Part1Points = 0;
P50Part2Points = 0;
P50Part3Points = 0;
CASPart1Points = 0;
CASPart2Points = 0;
CASPart3Points = 0;

availablePoints = 0; % Total number of points available, increases with every distractor displayed. E.g. if 5 distractors have been displayed, there will be 5 points available (but the subject may or may not have actually scored them). We'll use to calculate accuracy at end.

% Define paradigms to check
paradigms = {'ASSR', 'MMNPart1', 'MMNPart2', 'P50Part1', 'P50Part2', 'P50Part3', 'CASPart1', 'CASPart2', 'CASPart3'};

%% ADD UP SCORES ACROSS PARADIGMS

% Loop through each paradigm
for i = 1:length(paradigms)
    paradigm = paradigms{i};
    
    % Get subject's saved data
    subjectDataFileName = paradigm + "SavedData" + subjectIDNumber + '.mat'; % E.g. ASSRSavedData0031-T1
    subjectDataFolderName = "COMPS" + subjectIDNumber; % E.g. COMPS0031-T1
    subjectDataDir = fullfile(pwd, '..', 'subjectData', subjectDataFolderName);    
    dataPath = fullfile(subjectDataDir, subjectDataFileName);

    % Check if file exists
    if exist(dataPath, 'file')
        % Load the data
        load(dataPath);
        % Get points based on paradigm
        switch paradigm
            case 'ASSR'
                ASSRPoints = scoringData.points; % Saves number of points scored by subject during ASSR task
                availablePoints = availablePoints + 3; % There are 2 distractors in ASSR task so +2 available points 
            case 'MMNPart1'
                MMNPart1Points = scoringData.points;
                availablePoints = availablePoints + 8;
            case 'MMNPart2'
                MMNPart2Points = scoringData.points;
                availablePoints = availablePoints + 5;
            case 'P50Part1'
                P50Part1Points = scoringData.points;
                availablePoints = availablePoints + 6;
            case 'P50Part2'
                P50Part2Points = scoringData.points;
                availablePoints = availablePoints + 6;
            case 'P50Part3'
                P50Part3Points = scoringData.points;
                availablePoints = availablePoints + 8;
            case 'CASPart1'
                CASPart1Points = scoringData.points;
                availablePoints = availablePoints + 8;
            case 'CASPart2'
                CASPart2Points = scoringData.points;
                availablePoints = availablePoints + 8;
            case 'CASPart3'
                CASPart3Points = scoringData.points;
                availablePoints = availablePoints + 8;
        end
    else
        warning(['No data found for ' paradigm ' paradigm']);
    end
end

% Calculate total points
totalPoints = ASSRPoints + MMNPart1Points + MMNPart2Points + P50Part1Points + P50Part2Points + ...
    P50Part3Points + CASPart1Points + CASPart2Points + CASPart3Points;

% Calculate accuracy 
accuracy = totalPoints/availablePoints; % What % of distractors the subject correctly responded to

% Display total points
fprintf('Total points for %s: %d\n', subjectIDFull, totalPoints); 
fprintf('Accuracy for %s: %d\n', subjectIDFull, accuracy);

%% CALCULATE GBP BONUS 

bonus = totalPoints * 0.2; % 20p per point scored

if accuracy >= 0.75
    bonus = bonus + 4; 
end

bonus = round(bonus, 2);

fprintf('GBP renumeration for %s: %.2f\n', subjectIDFull, bonus);

%% SAVE DATA

% Save all points data with subject ID in filename
subjectDataFileName = paradigm + "SavedData" + subjectIDNumber; % E.g. ASSRSavedData0031-T1
subjectDataFolderName = "COMPS" + subjectIDNumber; % E.g. COMPS0031-T1
subjectDataDir = fullfile(pwd, '..', 'subjectData', subjectDataFolderName);
save(fullfile(subjectDataDir, ['totalPoints' subjectIDNumber '.mat']), 'ASSRPoints', 'MMNPart1Points', 'MMNPart2Points', ...
    'P50Part1Points', 'P50Part2Points', 'P50Part3Points', 'CASPart1Points', ...
    'CASPart2Points', 'CASPart3Points', 'totalPoints', 'availablePoints', 'accuracy', 'subjectIDFull');

%% SHOW FINAL SCORE

% Create message with scores
message = sprintf('You scored: %d / %d\n\nAccuracy = %.1f%%\n\nYou won \x00A3%.2f', ...
    totalPoints, availablePoints, accuracy * 100, bonus);

% Show message box
msgbox(message, 'Final Score', 'modal');

