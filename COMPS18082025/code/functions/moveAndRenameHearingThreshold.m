function moveAndRenameHearingThreshold(subjectIDNumber)
% moveAndRenameHearingThreshold - Renames and moves hearingThreshold.mat
% from ../hearingTest to ../subjectData/COMPS{subjectIDNumber}
%
% Input:
%   subjectIDNumber - string or char, e.g., '0200-T0'

    % Path to original file (one dir up, then into hearingTest)
    hearingTestDir = fullfile('..', 'hearingTest');
    originalFile = fullfile(hearingTestDir, 'hearingThreshold.mat');

    % Check that source file exists
    if ~isfile(originalFile)
        warning('?? File not found: %s\nSkipping move.', originalFile);
        return;
    end

    % New filename
    newFileName = ['hearingThreshold' subjectIDNumber '.mat'];

    % Target directory path: one dir up, subjectData/COMPS{id}
    targetDir = fullfile('..', 'subjectData', ['COMPS' subjectIDNumber]);

    % Full path to new file location
    targetPath = fullfile(targetDir, newFileName);

    % Move and rename the file
    movefile(originalFile, targetPath);

    fprintf('? Moved and renamed to: %s\n', targetPath);
end
