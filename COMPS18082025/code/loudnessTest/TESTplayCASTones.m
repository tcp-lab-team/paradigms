%% Psychtoolbox set up

% % function data = run_mmn_task(id, pid, mode)
% %
% %
% % if nargin<1
% %     id = 'Test';
% % end
%
%
% ptb_path = 'C:\projects\EIFES\code\tasks\Psychtoolbox-3-3.0.19.7\Psychtoolbox';
%
% cd(ptb_path);

% volume setting = 72 translates to 80 dB in ear volume based on iPhone
% "audiometer" 

ptb_path = 'C:\Users\compi\Documents\COMPS\code\toolboxes\Psychtoolbox-3-PTB_Beta-2020-05-10_V3.0.16\Psychtoolbox';
id = 'Test';
pid = 'COMPS';

close all;
clearvars -except id pid mode ptb_path
dbstop error


restoredefaultpath;

addpath('stimuli');
addpath('design');
addpath('lib');
addpath('instructions');

setenv('GSTREAMER_1_0_ROOT_X86_64', 'C:\gstreamer\1.0\msvc_x86_64\');

setup_psychtoolbox_path(ptb_path);

PsychtoolboxVersion

%% Play equalised CAS tones to test whether equalisation has worked :) 

load('Sequence4InNormalForm.mat')

% Initialize Psychtoolbox and audio
Screen('Preference', 'SkipSyncTests', 1);  % Skip sync tests for faster development
AssertOpenGL;
PsychDefaultSetup(2);

% Define the folder where the tones are stored
toneFolder = 'C:\Users\compi\Documents\COMPS\code\tasks\CAS\CASTones';  % Update this path to the location of your .wav files
numTones = 6000;  % Total number of tones

% Open the audio device
InitializePsychSound(1);
devices = PsychPortAudio('GetDevices', [], []);
device_id = 4;
pahandle = PsychPortAudio('Open', device_id, [], 1, 48000, 2);
% pahandle = PsychPortAudio('Open', [], [], 1, 48000, 2);

% Initialise toneData

toneData = cell(1, numTones);  % Create a cell array to store each tone's audio data

% Preload tones into memory (optional, but may help with performance)
for i = 1:numTones
    % Construct the filename for each tone
    toneFile = fullfile(toneFolder, sprintf('tone%d.wav', i));
    
    % Load the audio file into memory
    [y1, freq] = audioread(toneFile);
    
    toneData{i} = [y1 y1]';
        
    % Load the tone into the audio device buffer
    PsychPortAudio('FillBuffer', pahandle, toneData{i});
        
    PsychPortAudio('Start', pahandle, 1, 0, 1);  % Play the tone immediately
    
    Sequence4InNormalForm(i)
    
    % Wait for the duration of the tone + the pause (200ms tone + 50ms pause)
    WaitSecs(0.2 + 0.05);  % 200ms for the tone, 50ms pause
        
    % Optionally stop the sound before loading the next tone
    PsychPortAudio('Stop', pahandle, 1);  % Stop playback before starting next tone

end

% % Play the tones consecutively
% for i = 1:numTones
%     % Play the current tone
%     PsychPortAudio('Start', pahandle, 1, 0, 1);
%     
%     % Wait for the duration of the tone + the pause
%     WaitSecs(0.2 + 0.05);  % 200ms for the tone and 50ms pause
%     
%     % Optionally, you can stop the sound before starting the next one
%     PsychPortAudio('Stop', pahandle, 1);
% end

% Close the audio device
PsychPortAudio('Close', pahandle);

% [~, idx] = min(abs(Sequence4InNormalForm - 1000));
% 
% % Display the index and the corresponding value
% disp(['Index: ', num2str(idx)]);
% disp(['Value closest to 1000: ', num2str(Sequence4InNormalForm(idx))]);


%% Play UNequalised CAS tones to test whether equalisation actually did something :) 

