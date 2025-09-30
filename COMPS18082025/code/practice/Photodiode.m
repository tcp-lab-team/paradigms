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

ptb_path = 'C:\Users\compi\Documents\COMPS\code\toolboxes\Psychtoolbox-3-PTB_Beta-2020-05-10_V3.0.16\Psychtoolbox';
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

PsychtoolboxVersion

%% MEG photodiode demo
%
% Recommended photodiode usage:
% use white & black (not grey)
%     white for stimulus / stimulus onset
%     black for fixation / inter-trial
% (quits on any keypress)

%% PsychToolbox basic setup
PsychDefaultSetup(2);                           % apply common Psychtoolbox parameters
Screen('Preference', 'SkipSyncTests', 1);       % suppress warnings about VBL timing
KbName('UnifyKeyNames');                        % improve portability of your code acorss operating systems
KbQueueCreate                                   % create a keyboard queue
KbQueueStart                                    % start the keyboard queue recording

%% Screen setup & open
scn = max(Screen('Screens'));                   % find second screen if connected
[pWin,wRect] = Screen('OpenWindow',scn);        % open a display window
[wWidth,wHeight] = Screen('WindowSize',pWin);   % find window width & height
[x0,y0] = RectCenter(wRect);                    % find the centre of the window

%% Vpixx correction - if in MEG
PC = getenv('COMPUTERNAME');
switch PC
    case 'MEG-STIM'
        BackupCluts
        gamma = 2.2;
        propixxclut = linspace(0,1,256)'.^gamma*[1 1 1];
        [oldtable1, success] = Screen('LoadNormalizedGammaTable', pWin, propixxclut);
    otherwise
        % do nothing - use normal gamma
end

%% Stim loop
% Parameters
% define some colours
grey = [127 127 127];
black = [0 0 0];
white = [255 255 255];
% photodiode patch size
photodiodeW = 50;
photodiodeRect = [0, wHeight-photodiodeW, photodiodeW, wHeight];
% stimulus details
stimulusduration = 2; 
stimulus = imread('Mosquito.bmp');
ITI = 3;

% grey screen
Screen('FillRect', pWin, grey);
t = Screen('Flip', pWin);

% Loop
disp('Press any key to quit')
while 1
    % check for any keypress
    [keypressed,firstpress,firstrelease,lastpress,lastrelease] = KbQueueCheck;
    if keypressed
        break
    end    
    
    % prep stimulus
    Screen('PutImage', pWin, stimulus);
    Screen('FillRect', pWin, white, photodiodeRect);
    % present stimulus
    t0 = Screen('Flip', pWin);
    % prep fixation
    Screen('FillRect', pWin, grey);
    Screen('FillRect', pWin, black, photodiodeRect);
    Screen('FillOval', pWin, white, [x0-5;y0-5;x0+5;y0+5]);
    WaitSecs('UntilTime', t0+stimulusduration);
    % present fixation
    t1 = Screen('Flip', pWin);
    WaitSecs('UntilTime', t0+stimulusduration+ITI);
end

%% End
KbQueueStop
KbQueueRelease
sca