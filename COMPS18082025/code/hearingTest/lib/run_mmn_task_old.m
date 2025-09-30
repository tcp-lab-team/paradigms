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

ptb_path = 'C:\projects\COMPS\code\toolboxes\Psychtoolbox-3-PTB_Beta-2020-05-10_V3.0.16\Psychtoolbox';
id = 'Test';
pid = 'COMPS';
%mode = 'meg';
mode = 'debug';


%% Clear the workspace and screen
close all;
clearvars -except id pid mode ptb_path
dbstop error


%% Setup paths
restoredefaultpath;
addpath('stimuli');
addpath('design');
addpath('lib');
addpath('instructions');

setenv('GSTREAMER_1_0_ROOT_X86_64', 'C:\gstreamer\1.0\msvc_x86_64\');
setup_psychtoolbox_path(ptb_path);


%% Start data structure
data = struct();
data.id = id;
data.recording_date = datetime;

% Some potentially useful information about the setup
data.matlab_version = version;
data.ptb_version    = PsychtoolboxVersion;
data.computer       = computer;
data.audiodevinfo   = audiodevinfo;

% Experimental parameters
data.n_trials = 1500;

% Trigger values and what they mean
data.trial_list  = [1 2 3];
data.trial_label = {'start_movie', 'standard', 'deviant'}';


%% Load important files

dir_script = fileparts(mfilename('fullpath'));

% Load Design
load(fullfile(dir_script,'design','mmn_design.mat'));

% Movie file
moviename = fullfile(dir_script,'stimuli','tom_and_jerry_no_audio_50fps.mp4');

% Load audio files
standard_file = '/stimuli/standard.wav';
deviant_file = '/stimuli/deviant.wav';

% Read audio files
[y1, fs1] = audioread(standard_file);
[y2, fs2] = audioread(deviant_file);

% Duplicate audio files (since we are using stereo channnels)
standard = [y1 y1]';
deviant  = [y2 y2]';


%% Setup trigger object
if strcmp(mode,'meg')
    warning('Running in MEG mode! Triggers will be send.');
    port = hex2dec('3ff8');                         % !!! check the port address in device manager !!!
    onset = data.trial_list;                        % three trial types
    offset = 0;                                     % for resetting the port and marking the offset
    io = io64;                                      % create parallel port object
    status = io64(io);                              % check status of parallel port
    assert(status==0,'Parallel port not opened.');
else
    warning('Running in test mode. No triggers will be send!!!');
end


%% Initialize Psychtoolbox sound
InitializePsychSound(1);
devices = PsychPortAudio('GetDevices', [], []);
pahandle = PsychPortAudio('Open', [], [], 1, fs1, 2);



%% Setup screen
% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
if strcmp(mode,'debug')
    PsychDebugWindowConfiguration(0,0.5)
end

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


%% Instructions
% Draw instructions screen 1
start_img1_location = fullfile('instructions','instructions','Slide1.jpg');
start_img1 = imread(start_img1_location);
start_texture1 = Screen('MakeTexture', window, start_img1);

Screen('DrawTexture', window, start_texture1, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
t_inst = Screen('Flip', window);
t_inst_getsecs = GetSecs;

if strcmp(mode,'meg')
    io64(io,port,data.trial_list(1));
end
KbStrokeWait;

% startText = sprintf(['Welcome to the last part of the experiment.\n\n\n',...
%     'You will now watch a short silent movie (15 mins).\n\n',...
%     'You will also hear tones playing in the background,\n\n',...
%     'but you should just ignore them.\n\n\n',...
%     'Please, let us now if you cannot see the movie or\n\n'...
%     'hear the tones, right away, so we can fix it.\n\n\n\n',...
%     'Press any button to continue.']);
% DrawFormattedText(window, startText, 'center', 'center', white);
% Screen('Flip', window);
% KbStrokeWait;

start_img2_location = fullfile('instructions','instructions','Slide2.jpg');
start_img2 = imread(start_img2_location);
start_texture2 = Screen('MakeTexture', window, start_img2);

Screen('DrawTexture', window, start_texture2, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
Screen('Flip', window);
KbStrokeWait;


% % Draw instructions
% startText = sprintf(['Please, stay awake and try to move as little as possible.\n\n',...
%     'We want to hear your thoughts about the movie later on.\n\n\n\n',...
%     'Now, just relax and enjoy the movie.\n\n\n\n',...
%     'Press any button to start the movie.']);
% DrawFormattedText(window, startText, 'center', 'center', white);
% Screen('Flip', window);
% KbStrokeWait;


%% Play movie
% Open movie file:
[movie duration fps imgw imgh] = Screen('OpenMovie', window, moviename);

% Set a small window at the center of the screen for the movie
percent_screen = 0.2; % what percentage of the screen should be used for the video box
height = round(screenYpixels*percent_screen);
width = height*2.4; % will multiply by 2.4 since this is the native resolution of the video
box_size = [width, height]; % Width x Height
rect = CenterRectOnPoint([0, 0, box_size], windowRect(3)/2, windowRect(4)/2);
%rect = [100, 100, 400, 300];

frame_rate = 50; % Set the desired frame rate (e.g., 50 fps)
Screen('NominalFrameRate', screenNumber, 2, frame_rate);
Screen('Flip', window);

% Start playback engine:
Screen('PlayMovie', movie, 1, 1);

% Get timing of movie start and send trigger
t_movie_start = Screen('Flip', window);
t_movie_start_getsecs = GetSecs;
if strcmp(mode,'meg')
    io64(io,port,data.trial_list(1));
end
% Display the movie frames
t = 1; % Start with first trial
while 1
    
    
    tex = Screen('GetMovieImage', window, movie);
    if tex > 0
        
        current_time = GetSecs-t_movie_start;
        %  if current_time >= design.trial_timing(t) && t<= design.n_trials
        if abs(current_time - design.trial_timing(t))<0.005 && t<= design.n_trials
            is_deviant = design.trial_sequence(t)==3;
            % Since tones differ in there duration (standard: 50 ms, deviant 100ms,
            % we will either use an SOA of 400 or 450 ms to ensure a constant SOA
            % of 500.
            t_tone(t) = GetSecs;
            if is_deviant
                PsychPortAudio('FillBuffer', pahandle, deviant);
                PsychPortAudio('Start', pahandle, 1, 0, 1);
                %wait2(400);
            else
                PsychPortAudio('FillBuffer', pahandle, standard);
                PsychPortAudio('Start', pahandle, 1, 0, 1);
                %wait2(450);
            end
            t=t+1; % Update trial index
        end
        
        
        Screen('DrawTexture', window, tex, [], rect);
        Screen('Flip', window);
        Screen('Close', tex);
        
        
        % Check if the escape key is pressed
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('Escape'))
            break; % End the loop if escape key is pressed
        end
    else
        break;
    end
end
%
% % Play the tone sequence
% for t = 1:20%design.n_trials
%     is_deviant = design.trial_sequence(t)==3;
%
%     % Since tones differ in there duration (standard: 50 ms, deviant 100ms,
%     % we will either use an SOA of 400 or 450 ms to ensure a constant SOA
%     % of 500.
%     if is_deviant
%         PsychPortAudio('FillBuffer', pahandle, deviant);
%         PsychPortAudio('Start', pahandle, 1, 0, 1);
%         wait2(400);
%     else
%         PsychPortAudio('FillBuffer', pahandle, standard);
%         PsychPortAudio('Start', pahandle, 1, 0, 1);
%         wait2(450);
%     end
% end


% Stop playback:
Screen('PlayMovie', movie, 0);

% Clean up
Screen('CloseMovie', movie);
PsychPortAudio('Close', pahandle);


%% Draw end screen
end_img_location = fullfile('instructions','instructions','Slide2.jpg');
end_img = imread(end_img_location);
end_texture = Screen('MakeTexture', window, end_img);

Screen('DrawTexture', window, end_texture, [], [0 0 screenXpixels screenYpixels], 0);
t_end = Screen('Flip', window);
t_end_getsecs = GetSecs;



% endText = sprintf(['This was the last part of the experiment.\n\n',...
%     'Well done!\n\n\n\n',...
%     'Press any button to end the experiment.']);
% DrawFormattedText(window, endText, 'center', 'center', white);
% t_end_rest = Screen('Flip', window);
% t_end_rest_getsecs = GetSecs;



% Trigger end
if strcmp(mode,'meg')
    io64(io,port,data.trial_list(3));
end
KbStrokeWait;

% Close Screen, we're done:
sca;


t_tone_cor = t_tone-t_movie_start_getsecs;
figure; hold all
plot(t_tone_cor);
plot(design.trial_timing(1:numel(t_tone)));
legend({'Actual', 'Design'});
xlabel('Trial'), ylabel('Time');

figure; plot((t_tone_cor(2:end)-t_tone_cor(1:end-1)).*1000,'.'); xlabel('Trial'), ylabel('ITI');


