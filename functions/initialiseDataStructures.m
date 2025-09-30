function [t, points, numResponses, scoringData, imageData, ...
          allResponses, auditoryData, data, youScored, distractorOnsetTime, percentComplete, escapeKeyPressed] = initialiseDataStructures(paradigm, numImagesInSequence, auditoryNumTrials)

    % Initialise tone tracker, keeps track of which tone to play from auditory tone sequence
    t = 1;

    % Tracks how many two-in-a-row images subject correctly responds to
    points = 0;

    % Keep track of how many times subject has responded
    numResponses = 0;
    
    youScored = false(1, numImagesInSequence); % Tracks whether you scored
    
    distractorOnsetTime = 0; % Saves onset time of most recent distractor image so we can calculate whether subject has responded within reactionTimeWindow or not

    % Set up table to record scoring data
    scoringData = table();
    scoringData.whichParadigm = {paradigm};  % 'whichParadigm' - Which paradigm was run (e.g. ASSR, MMN, etc.)
    scoringData.points = 0;  % 'points' - Number of points scored
    scoringData.blockCompleted = false;  % 'blockCompleted' - Whether the block was completed

    % Set up table to record image data 
    imageData = table();
    imageData.onsetTime = NaN(numImagesInSequence, 1);  % 'onsetTime' - What time the image is displayed, relative to the start of the experiment
    imageData.fileName = cell(numImagesInSequence, 1);  % 'fileName' - The file name of the displayed image
    imageData.trialNumber = NaN(numImagesInSequence, 1);  % 'trialNumber' - Trial number. Each trial = 2 quartets of 4 images = 8 images displayed
    imageData.imageNumber = NaN(numImagesInSequence, 1);  % 'imageNumber' - Image number within a given trial, i.e. 1 to 8, 1 = 1st image displayed in sequence, 8 = 8th image displayed. 1st trial displays 8 images, 2nd trial displays the next 8, etc.
    imageData.trialType = cell(numImagesInSequence, 1);  % 'trialType' - Is this trial's sequence "predictable", "unpredictable", "mismatch" or "distractor"
    imageData.trialSequenceNumeric = cell(numImagesInSequence, 1);  % 'trialSequenceNumeric' - The specific order that images are shown for this trial, e.g. predictable would be 1 2 3 4 1 2 3 4, unpredictable could be 1 2 3 4 3 4 1 2, mismatch would be 1 2 3 4 1 2 4 3, distractor could be 1 2 2 3 1 2 3 4
    imageData.trialSequenceAlphabetic = cell(numImagesInSequence, 1);  % 'trialSequenceAlphabetic' - The specific order that images are shown for this trial but using letters rather than image number as per Garrido et al., 2015 (https://doi.org/10.1016/j.neuroimage.2015.07.016) , e.g. predictable would be A B C D A B C D, unpredictable could be A B C D C D A B, mismatch would be A B C D A B D C, distractor could be A B B C A B C D
    imageData.machineOnsetTime = NaT(numImagesInSequence, 1, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');  % 'machineOnsetTime' - What time the image is displayed, using the timer of computer itself

    % Upper bound of number of responses so we can pre-allocate size of the response times table
    maxResponses = numImagesInSequence * 10; % Assumes subjects won't respond more than 10x per image displayed!

    % Set up table to record data when subject responds
    allResponses = table();
    allResponses.reactionTime = NaN(maxResponses, 1);  % 'reactionTime' - Time taken for subject to respond since stimulus onset i.e. time now - stimulus onset time (seconds)
    allResponses.globalTime = NaN(maxResponses, 1);  % 'globalTime' - The global time when subject responds, relative to experimentStartTime (seconds)
    allResponses.trialNumber = NaN(maxResponses, 1);  % 'trialNumber' - Trial number. Each trial = 2 quartets of 4 images = 8 images displayed. 1st trial displays 8 images, 2nd trial displays the next 8, etc.
    allResponses.imageNumber = NaN(maxResponses, 1);  % 'imageNumber' - Image number within a given trial that the subject has responded to, i.e. 1 to 8, 1 = 1st image displayed in sequence, 8 = 8th image displayed. NOTE: this is not necessarily the same as the image displaying when subject responds, because the reaction window allows for a delayed reaction. E.g. subject might spot that the 6th image is a two-in-a-row, but only respond while 7th image is showing
    allResponses.correct = NaN(maxResponses, 1);  % 'correct' - Did subject respond correctly to win a point? 1 = yes, 0 = false
    allResponses.imageFileName = cell(maxResponses, 1);  % 'imageFileName' - The file name of the displayed image
    allResponses.trialType = cell(maxResponses, 1);  % 'trialType' - Is this trial's sequence predictable, unpredictable, mismatch or distractor
    allResponses.trialSequenceNumeric = cell(maxResponses, 1);  % 'trialSequenceNumeric' - The specific order that images are shown for this trial, e.g. predictable would be 1 2 3 4 1 2 3 4, unpredictable could be 1 2 3 4 3 4 1 2, mismatch would be 1 2 3 4 1 2 4 3, distractor could be 1 2 2 3 1 2 3 4
    allResponses.trialSequenceAlphabetic = cell(maxResponses, 1);  % 'trialSequenceAlphabetic' - The specific order that images are shown for this trial but using letters rather than image number as per Garrido et al., 2015 (https://doi.org/10.1016/j.neuroimage.2015.07.016), e.g. predictable would be A B C D A B C D, unpredictable could be A B C D C D A B, mismatch would be A B C D A B D C, distractor could be A B B C A B C D
    allResponses.machineGlobalTime = NaT(maxResponses, 1, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');  % 'machineGlobalTime' - The global time when subject responds, using the computer's time settings

    % Set up table to record auditory data 
    auditoryData = table();
    auditoryData.onsetTime = NaN(auditoryNumTrials, 1);  % What time the clicktrain starts, relative to the start of the experiment
    auditoryData.trialNumber = NaN(auditoryNumTrials, 1);  % Trial number tells us which clicktrain we're on, e.g. 1st, 2nd...300th
    auditoryData.trialType = NaN(auditoryNumTrials, 1);  % Trial type tells us the type of auditory trial. For ASSR and CAS, there is only one type = "1". For P50, there's "1" and "2" for 1st and 2nd click. Then for MMN, there's "1" and "2" for standard and deviant tones.
    auditoryData.machineOnsetTime = NaT(auditoryNumTrials, 1, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');  % What time the clicktrain starts, using the computer's time settings

    % Save general setup information 
    data = struct();
    data.id = "COMPS";
    data.recording_date = datetime;
    data.matlab_version = version;
    data.ptb_version    = PsychtoolboxVersion;
    data.computer       = computer;
    data.audiodevinfo   = audiodevinfo;
    
    % Initialise perecent complete flags 
    percentComplete.twentyFive = false; % Tracks whether we've shown 25% complete screen yet 
    percentComplete.fifty = false; % Tracks whether we've shown 50% complete screen yet 
    percentComplete.seventyFive = false; % Tracks whether we've shown 75% complete screen yet
    
    escapeKeyPressed = false; % Initialise escape key tracker; if true experiment will end

end
