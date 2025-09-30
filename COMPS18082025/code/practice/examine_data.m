% Script to examine saved ASSR data
clear all;
close all;

% Load the saved data
load('subjectDataSaved/savedASSRData0007.mat');

% Display information about the loaded variables
whos

% Display some key information
fprintf('\nLast saved trial: %d\n', last_saved_trial);
fprintf('Last saved tone: %d\n', last_saved_tone);
fprintf('Last saved time: %.2f seconds\n', last_saved_time);
fprintf('Last saved points: %d\n', last_saved_points);

% Display first few rows of each table
fprintf('\nFirst few rows of imageData:\n');
disp(head(imageData));

fprintf('\nFirst few rows of allResponseTimes:\n');
disp(head(allResponseTimes));

fprintf('\nFirst few rows of clicktrainDataASSR:\n');
disp(head(clicktrainDataASSR));

% Select paradigm
paradigm = 'ASSR'; % You can choose from ASSR, P50, MMN or CAS
% Load the design file for the specified paradigm
design_file = sprintf('%s_design.mat', paradigm);
load(design_file);
whos
 
mean(diff(imageData.onsetTime(~isnan(imageData.onsetTime))))

% Plot the timing of clicktrains
figure;
plot(clicktrainDataASSR.onsetTime, 'b.');
xlabel('Tone Number');
ylabel('Onset Time (seconds)');
title('Clicktrain Timing');
grid on; 

figure;
x = imageData.onsetTime(~isnan(imageData.onsetTime));
plot(x(2:end)-x(1:end-1),'o')


