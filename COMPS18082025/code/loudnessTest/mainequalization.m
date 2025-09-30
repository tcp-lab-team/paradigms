function all_loudness = leftrightequalization(ppnum, wrun, setup)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fast access for testing purpos                                                        %
%                                                                                       %
% addpath(genpath([pwd '/functions/']));addpath(genpath([pwd '/stimuli/']));startup1;   %
% Screen( 'Preference', 'SkipSyncTests', 1);                                            %
% ppnum ='1'; wrun ='1'; setup =2; % set to 2 for fMRI                                    %
%                                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Psychtoolbox set up 

% Clear the workspace and screen
close all;
clearvars -except ppnum wrun setup
dbstop error

% Setup paths
%restoredefaultpath;

% Add necessary paths
addpath('stimuli');
addpath('design');
addpath('lib');
addpath('instructions');
addpath('./functions');  % If the functions folder is in the same directory as your script

% Initialize Psychtoolbox
%setenv('GSTREAMER_1_0_ROOT_X86_64', 'C:\gstreamer\1.0\msvc_x86_64\');

%ptb_path = 'C:\Users\compi\Documents\COMPS\code\toolboxes\Psychtoolbox-3-PTB_Beta-2020-05-10_V3.0.16\Psychtoolbox';
%ptb_path = fullfile('C:\toolbox\Psychtoolbox'); %DH ADDED FOR FIL

% FOR FIL

%setup_psychtoolbox_path(ptb_path); %DH COMMENTED OUT FOR FIL
PsychStartup;
PsychtoolboxVersion

Screen('Preference', 'SkipSyncTests', 1);


%% MONITOR SETTINGS

setup = 0; 
wrun = 1; 

switch setup

    case 0          % windows pc
        % screen info
        cfg.setup.disp_dist       = 500;                          % display distance in mm
        cfg.setup.screen_number   = max(Screen('Screens'));       % always use 2nd screen (or only monitor)
        [cfg.setup.screen_width, cfg.setup.screen_height] = Screen('DisplaySize', cfg.setup.screen_number);
        cfg.setup.hz              = round(Screen('FrameRate', cfg.setup.screen_number));
        cfg.setup.full_screen     = 1;                           

        % path and invironment info
        cfg.setup.base_path       = pwd;
        cfg.setup.environment     = 'Windows PC';
        Screen( 'Preference', 'SkipSyncTests', 1);      % skip synctest for testing

    case 1          % macbook
        % screen info
        cfg.setup.disp_dist       = 500;                          % display distance in mm
        cfg.setup.screen_height   = 180;   % mm
        cfg.setup.screen_width    = 285;   % mm
        cfg.setup.hz              = 60;
        cfg.setup.screen_number   = 0;
        cfg.setup.full_screen     = 1;      

        % path and invironment info
        cfg.setup.base_path       = pwd;
        cfg.setup.environment     = 'Macbook';
        Screen( 'Preference', 'SkipSyncTests', 1);

    case 2          % fMRI
        % screen info
        cfg.setup.disp_dist       = 500;                          % display distance in mm
        cfg.setup.screen_number   = 1;       % always use 2nd screen (or only monitor)
        [cfg.setup.screen_width, cfg.setup.screen_height] = Screen('DisplaySize', cfg.setup.screen_number);
        cfg.setup.hz              = round(Screen('FrameRate', cfg.setup.screen_number));
        cfg.setup.full_screen     = 1;                            % 

        % path and invironment info
        cfg.setup.base_path       = pwd;
        cfg.setup.environment     = 'fMRI';

    case 3          % MEG (under construction)
        % screen info
        cfg.setup.disp_dist       = 500;                          % display distance in mm
        cfg.setup.screen_number   = max(Screen('Screens'));       % always use 2nd screen (or only monitor)
        [cfg.setup.screen_width, cfg.setup.screen_height] = Screen('DisplaySize', cfg.setup.screen_number);
        cfg.setup.hz              = round(Screen('FrameRate', cfg.setup.screen_number));
        cfg.setup.full_screen     = 1;                            % 

        % path and invironment info
        cfg.setup.base_path       = pwd;
        cfg.setup.environment     = 'MEG';
end
% other screen settings
cfg.setup.dispsize    = [cfg.setup.screen_width cfg.setup.screen_height];
cfg.setup.pixsize     = Screen('Rect', cfg.setup.screen_number);
cfg.setup.w_px=cfg.setup.pixsize(3); cfg.setup.h_px=cfg.setup.pixsize(4);


%% SETTINGS

% Copied from settings_tonotopy
cfg.visual.fixfrac             = 1;
cfg.visual.bull_dim_fact       = 1;              % dim factor of bullseye fixation
cfg.visual.bull_dim_col        = [0.7 0.7 0.7];    
cfg.visual.bull_eye_col        = [0 0 0];
cfg.visual.bull_in_col         = [1 1 1];
cfg.visual.bull_in_col_cor     = [0 1 0];
cfg.visual.bull_in_col_inc     = [1 0 0];
cfg.visual.bull_out_col        = [0 0 0];
cfg.visual.bull_fixrads        = cfg.visual.fixfrac * [44 20 12];        % midpoint, inner_ring, outer_ring size

% equalisation
%settings_tonotopy;                                  % fetch some information from tonotopy settings
equal.refstim         =   4;                        % what stimulus to use as refference
equal.refloud         =   14;                        % what is the 'refference' loudness
equal.minfreq         =   125;%cfg.minfreq;              % minimum frequency to equalize
equal.maxfreq         =   6000;%cfg.maxfreq;              % maxiumum frequency to equalize
equal.nfreq           =   9;                        % number of frequencies to use in equalisation
%equal.freq0           =   2.^(linspace(log2(equal.minfreq),log2(equal.maxfreq),equal.nfreq));     % create logspace freq array
equal.freq0           =   [125 202.8 329 633 866 1405 2279.5 3698.2 6000];

% sound
equal.sampdur         =   0.5; %0.5; %5;                      % duration of sample in ms !!
equal.sil_gap         =   0.25;                     % length of sillence gap
% equal.intloudness     =   logspace(-2, 0, 18); % Reduced range to prevent clipping while maintaining relative relationships
equal.intloudness = logspace(-2.5, 0.5, 25); 
equal.intloudness(11) = 0.0625;
equal.ampl            =   .95;                      % keeping original amplitude
equal.nrchannels      =   1; %cfg.sound.nrchannels;     % number of channels used
equal.samp_rate       =   48000; %cfg.sound.samp_rate;      % sampling rate used

% amplitude mod
equal.amplmod         =   4;                        % reduced frequency of amplitude modulation
equal.mod_index       =   0.5;                      % reduced modulation index
equal.mod_min         =   0.5;                      % increased minimum modulation to prevent complete silence

% misc

cfg.visual.c3              = ones(1,3)*255;        % set color white

equal.fontsize        =   36; %cfg.visual.fontsize;      % set fontsize
equal.backgr          =   round(0.5*cfg.visual.c3); %cfg.visual.backgr;        % set background collor
if IsWin 
    equal.textfont    = 'Calibri';                  % set fontfamily 
elseif IsOSX
    equal.textfont    = 'Arial';
end
equal.textcol         =   cfg.visual.c3*1;          % set text color
equal.introtxt        =   {'Judge the loudness of the sounds', ' ', '(Press any key to continue)'};
equal.keytxt          =   {'First sound louder: 1', 'Second sound louder: 2', ...
                           'Loudness about the same: 3', ' ','(Press any key to start)'};
equal.bull_eye_col    =   cfg.visual.bull_eye_col;  % color of bullseye
equal.bull_in_col     =   cfg.visual.bull_in_col;   % color of inner ring
equal.bull_out_col    =   cfg.visual.bull_out_col;  % color of outer ring

%% Copied from settings_tonotopy
cfg.visual.bullsize        = ang2pix( cfg.visual.bull_dim_fact, cfg.setup.disp_dist, cfg.setup.screen_width, cfg.setup.pixsize(3),1);

%% More settings
equal.bull_fixrads    =   cfg.visual.bull_fixrads;  % radious of bulls
equal.bullsize        =   cfg.visual.bullsize;

% Get the screen numbers
screens = Screen('Screens');

% Use the primary screen (usually the first one)
screenNumber = max(screens);  % This gets the external screen if available, otherwise the primary screen

[w, screenrect] = Screen('OpenWindow', screenNumber, equal.backgr);
HideCursor;

%% CREATE SOUND SAMPLES

% set waveform values
soundmatrix           = zeros(length(equal.freq0), ...                      % precreate sound matrix
                              length(equal.intloudness), ...
                              equal.sampdur * equal.samp_rate);
modwave               = createwaveform(equal.amplmod, ...                   % create waveform for amplitude mod
                                       equal.sampdur, ...
                                       equal.samp_rate); 
modwave               = ((equal.mod_index  * modwave) + 1)/ ...             % adjust modulatotion waveform (if needed)
                          (2/(equal.mod_index-equal.mod_min )) + equal.mod_min ;  
freq0waves            = equal.ampl * createwaveform(equal.freq0, ...        % create waveforms for all f0s
                                                    equal.sampdur, ...
                                                    equal.samp_rate);

% apply loudness modulation and set for all loudnesses
moddedwaves           = freq0waves .* modwave;
for iloud = 1:size(soundmatrix,2)
    temp_signal = reshape(moddedwaves * equal.intloudness(iloud), length(equal.freq0), 1,[]);
    % Normalize each frequency's signal to prevent clipping
    for freq_idx = 1:length(equal.freq0)
        max_val = max(abs(squeeze(temp_signal(freq_idx,:,:))));
        if max_val > 1
            temp_signal(freq_idx,:,:) = temp_signal(freq_idx,:,:) / max_val;
        end
    end
    soundmatrix(:,iloud,:) = temp_signal;
end

%% DO ACTUAL EQUALISATION

% prepair everything
others                      = 1:size(soundmatrix,1); %setdiff(1:size(soundmatrix,1),equal.refstim);     % all counds except for reference stim
if ~exist([pwd '/loudness/reff-loudness.mat'],'file')
    all_loudness            = zeros(1,size(soundmatrix,1));                     % set loudness values
    equal.ind_louds         = ones(1, size(all_loudness, 2)) * equal.refloud;   % set initial value to refloudness
    disp('File Not Found!')
else
    load (fullfile( pwd, 'loudness', ['reff-loudness.mat']), 'all_loudness');   % or load to already have a good guess
    equal.ind_louds         = all_loudness;
    disp('File Found!')
end

all_loudness(equal.refstim) = equal.refloud;                                    % set refference freq to refference loudness

% display instructions image
instructions = imread('loudnessTestInstructions.jpg');
instructions = Screen('MakeTexture', w, instructions);
Screen('DrawTexture', w, instructions);
Screen('Flip', w); KbWait(-1, 3);

% display buttons image
instructions = imread('buttonsSlide.jpg');
instructions = Screen('MakeTexture', w, instructions);
Screen('DrawTexture', w, instructions);
Screen('Flip', w); KbWait(-1, 3);

% compare stimuli to ref
 for i=length(others):-1:1

    % set start comparison value
    equal.ind_loud = equal.ind_louds(others(i));

    % compare loudness to refference and save
    if setup == 3
        [trainloudness,cc]      = compareloudness_MEG(squeeze(soundmatrix(equal.refstim,equal.refloud,:)), ...
                                                      squeeze(soundmatrix(others(i),:,:)), equal, w, screenrect);
    else
        [trainloudness,cc]      = compareloudness_MRI(squeeze(soundmatrix(equal.refstim,equal.refloud,:)), ...
                                                      squeeze(soundmatrix(others(i),:,:)), equal, w, screenrect);
    end
    all_loudness(others(i))  = trainloudness;

    if strcmp(cc,'ESCAPE')
            break;
    end 
end

disp('Inaccuracy:')
inaccuracy = equal.refloud - all_loudness(equal.refstim);

%% SHUT DOWN AND SAVE DATA
inaccuracy = equal.refloud - all_loudness(equal.refstim);
save(fullfile(pwd, 'subjectDataSaved', [ppnum '-loudness.mat']), 'all_loudness', 'equal', 'inaccuracy');

subjectDataFolderName = ['COMPS' ppnum]; % E.g. COMPS0031-T1
subjectDataDir = fullfile(pwd, '..', '..', 'subjectData', subjectDataFolderName);

if ~exist(subjectDataDir, 'dir') % Create folder if doesn't exist
    mkdir(subjectDataDir);
end

save(fullfile(pwd, '..', '..', 'subjectData', ['COMPS' ppnum], [ppnum '-loudness.mat']), 'all_loudness', 'equal', 'inaccuracy'); % Save again in main subjectData folder

disp('Subject data saved!');

%% cleanup
ShowCursor;     
ListenChar;     
sca;    

end