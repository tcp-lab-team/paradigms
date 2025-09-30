%% Cleaning

close all;
clearvars 

%% Load SubjectID

% Get the current script's directory and go up to the parent directory
current_dir = fileparts(mfilename('fullpath')); % Gets loudnessTest folder
parent_dir = fileparts(current_dir);            % Gets tasks folder

filePath = fullfile(parent_dir, 'subjectIDNumber.mat'); % The GUI saves most recent subject's ID number here

% Load the .mat file
load(filePath);

%% Setup paths

addpath(fullfile(current_dir, 'stimuli'));
addpath(genpath(fullfile(current_dir, 'functions')))

%% Run Loudness Test

% Run the loudness equalization test
all_loudness = mainequalization(subjectIDNumber, 1, 0);
