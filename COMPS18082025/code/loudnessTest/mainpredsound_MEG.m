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
addpath(genpath('C:\Users\compi\Documents\COMPS\code\tasks\pred_adapt_MEG_COPY\functions'))

setenv('GSTREAMER_1_0_ROOT_X86_64', 'C:\gstreamer\1.0\msvc_x86_64\');
setup_psychtoolbox_path(ptb_path);

PsychtoolboxVersion

% function mainpredsound_MEG(ppnum, wrun, setup)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fast acces for testing purpos                                                        %
%                                                                                       %
addpath(genpath([pwd '/functions/']));addpath(genpath([pwd '/stimuli/']));%startup1;   %
%Screen( 'Preference', 'SkipSyncTests', 1);                                            %
ppnum ='1';
wrun ='1';
setup =0;     % set to 2 for fMRI                            %
%                                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sca

settings_main;

%% CONDITIONS AND COUNTERBALANCING
addpath(genpath([pwd '/functions/']));      % add functions to path

nsegments           = cfg.n_segments;                                       % number of segments per block
nblocks             = cfg.n_blocks;                                         % number of blocks
nruns               = cfg.MEG.n_runs;                                           % number of runs

samp_rate = 48000;

nadpts              = 3;                                                    % number of adaptation cohorts
npreds              = 3;                                                    % number of prediction cohorts

nprobs              = cfg.n_probs;                                          % number of probabilities
npairs              = size(cfg.block_pairs, 2);                             % number of freq pairs

nsegments_all       = nsegments * nblocks;                                  % total number of segments      

numTonesToSample = 500; 

% for first time loading exp: do counterbalancing, otherwise load
if str2double(wrun) == 1

% block counterbalance
cb_blocks           = counterbalance([npairs], nblocks/npairs, [], 1, [], 'subdiv');
cb_segments         = counterbalance([nprobs], 1, [], nsegments_all/nprobs, [], 'full');

segmentz = NaN(11, nblocks*nsegments);
segmentz( 1,  :)     = repelem(1:nruns, nsegments*cfg.MEG.bpr);                 % In MEG we can see this as bigger blocks
segmentz( 2,  :)     = repelem(1:nblocks, nsegments);                       % what block
segmentz( 3,  :)     = repmat(1:nsegments, 1, nblocks);                     % trial in block
segmentz( 4,  :)     = cb_segments;                                         % prob condition per segment
segmentz( 5,  :)     = repelem(cb_blocks, nsegments);                       % what freq pair is being presented

segmentz( 6,  :)     = cfg.stim_probs(1, segmentz(4, :));                   % probability of selecting A in section
segmentz( 7,  :)     = cfg.stim_probs(2, segmentz(4, :));                   % probability of selecting B in section

segmentz( 8,  :)     = cfg.cent_freqs(cfg.block_pairs(1, segmentz(5,:)));   % center freq of A this block
segmentz( 9,  :)     = cfg.cent_freqs(cfg.block_pairs(2, segmentz(5,:)));   % center freq of B this block

% aproximate predictablity and adaptability of blocks
pred_idx = nan(1,nblocks);
adpt_idx = nan(1,nblocks);
for b = 1:nblocks
    pred_idx(b) = std(diff(cfg.stim_probs(1, segmentz(4, segmentz(2,:) == b))));
    adpt_idx(b) = mean(cfg.stim_probs(1, segmentz(4, segmentz(2,:) == b)));
end
[~, pred_idx] = sort(pred_idx);
[~, adpt_idx] = sort(adpt_idx);

% set segments predictability
for i = 1:nadpts
    segmentz(10, ismember(segmentz(2, :), pred_idx(repelem(1:nadpts, nblocks/nadpts) == i)))     = i;    % pedictability (1=low-switching, 2=medium-swithing, 3=high-switching)
    segmentz(11, ismember(segmentz(2, :), adpt_idx(repelem(1:npreds, nblocks/npreds) == i)))     = i;    % adaptability (1=A-higher, 2=average, 3=B-higher)
end

% define relative timings  
timingz             =   nan( 12, nblocks * cfg.tpb);
timingz( 1, :)      =   repelem(1:nruns, cfg.tpb*cfg.MEG.bpr);                  % [1]: What run
timingz( 2, :)      =   repelem(1:nblocks, cfg.tpb);                        % [2]: What block
timingz( 3, :)      =   repmat(1:cfg.tpb, 1, nblocks);                      % [3]: What trial in block
timingz( 4, :)      =   repmat(repelem(1:nsegments, cfg.tps), 1, nblocks);  % [4]: What segment
                                                                            % --Here present just for information-- %
timingz( 5, :)      =   nan;                                                % [5]: What time should we start present each trial
timingz( 6, :)      =   nan;                                                % [6]: What time should we stop present each trial
timingz( 7, :)      =   nan;                                                % [7]: The real start time of a trial
timingz( 8, :)      =   nan;                                                % [8]: The estimated real stop time of a trial
timingz( 9, :)      =   nan;                                                % [9]: The real presentation length of a trial
timingz( 10, :)     =   nan;                                                % [10]: The enpostion in sec of buffered audio relative to buffered snipped
timingz( 11, :)     =   nan;                                                % [11]: The presented log frequency this trial
timingz( 12, :)     =   nan;                                                % [12]: The presented frequency this trial

end

%% GENERATE TONES

load('sequence4InNormalForm.mat')

[~, unequalised_mod_tones] = create_tones_main(Sequence4InNormalForm, cfg.stim_t, cfg.sound.MEG.samp_rate, ...
                                                    cfg.ramp_ops, cfg.ramp_dns);

%% apply PERSONALISED equalised loudness curves for sequence4

ppnum = '1';

if exist([pwd '/loudness/' ppnum '/' ppnum '-loudness.mat'],'file')
    % load loudness values for participant
    load(fullfile( pwd, 'loudness', ppnum, [ppnum '-loudness.mat']),'all_loudness', 'equal');  
    % loudnesses
    
    cfg.loudLevel = logspace(-2.5, 0.5, 25); 
    
    personalised_aprox_idx       = linspace(log2(cfg.minfreq), log2(cfg.maxfreq), 6000);                   % set frequencies to aproximate (and take closest)
    personalised_aprox_loudness  = pchip(log2(equal.freq0), cfg.loudLevel(all_loudness), personalised_aprox_idx);          % use piecewise cubic interpolation (instead of spine, to circomvent under/overshoots)
    log_pres_freq   = log2(Sequence4InNormalForm);                          
    
    % Calculate closest index for all tones in one sweep
    % searcharray     = repmat(personalised_aprox_idx', [1, size(log_pres_freq, 2)]);                          % create a repamt search array to use in a one sweep search
    
    % Initialize a vector to store closest indices
    closidx = NaN(size(log_pres_freq));

    % Loop through each frequency in log_pres_freq
    for i = 1:length(log_pres_freq)
        % Find the index of the closest frequency in personalised_aprox_idx
        [~, closidx(i)] = min(abs(personalised_aprox_idx - log_pres_freq(i)));
    end
    
    %[~, closidx]    = min(abs(searcharray-log_pres_freq));                                      % calculate what is the closest value(s index) in interpolated array
    
    % Adjust tone intensity for the entire sequence
    personalised_equalised_mod_tones       = personalised_aprox_loudness(closidx)' .* unequalised_mod_tones;                                    % weigh the tones by intensity
else
    sca; ShowCursor;
    error('[!!!] No loudness equalisation file found, please do loudness equalisation first...');
end

% load left right equalisation load
if exist([pwd '/loudness/' ppnum '/' ppnum '-rl_loudness.mat'],'file')
    load(fullfile( pwd, 'loudness', ppnum, [ppnum '-rl_loudness.mat']),'relloudnes');           % load right left loudness values for participant
else
    relloudnes = [1, 1];                                                                        % set right left loudness to ones
    warning('No right/left equalisation done, equal loudness assumed - [1, 1]');
end

% plot(2.^personalised_aprox_idx, personalised_aprox_loudness)

%% Play the Personally equalised

InitializePsychSound(1);
device_id = 4;
pahandle = PsychPortAudio('Open', device_id, 1, 1, samp_rate, equal.nrchannels, [], 1);

numTonesToSample = 200; 

sca;
ref_loudness = 14;
equal.intloudness = logspace(-2.5, 0.5, 25); 

pause_duration = cfg.iti;

% Calculate total duration and create a buffer for all tones
tone_duration = size(unequalised_mod_tones, 3) / samp_rate;  % Duration of each tone in seconds
total_duration = (tone_duration + pause_duration) * numTonesToSample;  % Total duration for all 25 tones
total_samples = round(total_duration * samp_rate);

% Create a buffer for all tones
all_tones = zeros(1, total_samples);

% Fill the buffer with all tones and pauses
for i = 1:numTonesToSample
    % Calculate start position for this tone
    start_pos = round((i-1) * (tone_duration + pause_duration) * samp_rate) + 1;
    end_pos = start_pos + size(unequalised_mod_tones, 3) - 1;
    
    % Extract and scale the tone
    tone = squeeze(personalised_equalised_mod_tones(i, 1, :))'; % Extract and process the tone
    %tone = 0.95 * squeeze(personalised_equalised_mod_tones(i, 1, :))' * equal.intloudness(ref_loudness);
    
    % Place the tone in the buffer
    all_tones(start_pos:end_pos) = tone;
end

% Fill the audio buffer with all tones
PsychPortAudio('FillBuffer', pahandle, all_tones);

% Get the start time
start_time = GetSecs;

% Play all tones with precise timing
PsychPortAudio('Start', pahandle, 1, start_time, 1);

% Wait for all tones to finish
WaitSecs(total_duration);

% Stop playback
PsychPortAudio('Stop', pahandle);

% %% Save the personalised tones 
% 
% fs = 48000;
% output_folder = 'personalisedTones';  
% 
% numTonesToSave = 10;  % Number of tones
% 
% % Loop through each tone
% for i = 1:numTonesToSave%:size(personalised_equalised_mod_tones, 1)
%     % Extract the current tone from the 3D array (i, 1, :)
%     tone = squeeze(personalised_equalised_mod_tones(i, 1, :)); 
%     
%     % Create a filename for the current tone
%     filename = fullfile(output_folder, sprintf('tone_%d.wav', i));
%     
%     % Save the tone as a .wav file
%     audiowrite(filename, tone, fs);
%     
%     % Optionally, display a message to track progress
%     fprintf('Saved tone %d of %d to %s\n', i, size(personalised_equalised_mod_tones, 1), filename);
% end
% 
% %% Play personalised tones AS FILES
% 
% % Assuming you have saved your .wav files in the output folder
% 
% % Step 1: Read all tones and store them
% for i = 1:numTonesToSave
%     % Create the filename for the current tone
%     filename = fullfile(output_folder, sprintf('tone_%d.wav', i));
%     
%     % Read the tone from the .wav file
%     [tone, ~] = audioread(filename);
%     
%     % Store the tone and fs
%     tones{i} = tone;
% end
% 
% fs = 48000;
% 
% % Step 2: Play the tones with 50ms gap between them
% silence_duration = 0.05;  % 50ms silence gap
% 
% % Loop through each tone and play
% for i = 1:numTonesToSave
%     % Extract the current tone from the cell array
%     tone = tones{i};
%         
%     % Fill the audio buffer with the current tone
%     PsychPortAudio('FillBuffer', pahandle, tone');
%     
%     % Play the tone
%     PsychPortAudio('Start', pahandle, 1, 0, 1);  % Start playing immediately
%     
%     % Wait for the tone to finish before playing the next one
%     WaitSecs(length(tone) / fs);  % Wait for the duration of the current tone
%         
%     % Wait for the 50ms silence to finish
%     WaitSecs(silence_duration);
% end
% 
% % Close the audio device after playback is done
% PsychPortAudio('Close', pahandle);
% 
% %% Play the Reference/Andrew unequalised
% 
% InitializePsychSound(1);
% device_id = 4;
% pahandle = PsychPortAudio('Open', device_id, 1, 1, samp_rate, equal.nrchannels, [], 1);
% 
% sca;
% ref_loudness = 14;
% equal.intloudness = logspace(-2.5, 0.5, 25); 
% 
% % Calculate total duration and create a buffer for all tones
% tone_duration = size(unequalised_mod_tones, 3) / samp_rate;  % Duration of each tone in seconds
% total_duration = tone_duration * 500;  % Total duration for all 25 tones
% total_samples = round(total_duration * samp_rate);
% 
% 
% % Create a buffer for all tones
% all_tones = zeros(1, total_samples);
% 
% % Fill the buffer with all tones
% for i = 1:500
%     % Calculate start position for this tone
%     start_pos = round((i-1) * tone_duration * samp_rate) + 1;
%     end_pos = start_pos + size(unequalised_mod_tones, 3) - 1;
%     
%     % Extract and scale the tone
%     tone = 0.95 * squeeze(unequalised_mod_tones(i, 1, :))' * equal.intloudness(ref_loudness);
%     
%     % Place the tone in the buffer
%     all_tones(start_pos:end_pos) = tone;
% end
% 
% % Fill the audio buffer with all tones
% PsychPortAudio('FillBuffer', pahandle, all_tones);
% 
% % Get the start time
% start_time = GetSecs;
% 
% % Play all tones with precise timing
% PsychPortAudio('Start', pahandle, 1, start_time, 1);
% 
% % Wait for all tones to finish
% WaitSecs(total_duration);
% 
% % Stop playback
% PsychPortAudio('Stop', pahandle);
% 
% %% PREVIOUS WITHOUT PSYCHTOOLBOX
% 
% % Loop through all tones
% for i = 1:10%[12 30 12 30 12 30]%1:30%size(mod_tones, 1)
% % Extract the current tone
% tone = squeeze(unequalised_mod_tones(i, 1, :));
% % tone = squeeze(mod_tones(i, 1, :));
% % Print the frequency
% fprintf('Playing Unequalised tone %d of %d, Frequency: %.2f Hz\n', i, size(unequalised_mod_tones, 1), Sequence4InNormalForm(i)); % change back
% % Play the tone without normalization
% sound(tone, fs);
% % Wait for the tone to finish (0.2 seconds) plus the pause time
% pause(0.2 + pause_time);
% end
% 
% pause(2)
% 
% % Loop through all tones
% for i = 1:100%[12 30 12 30 12 30]%1:30%size(mod_tones, 1)
% % Extract the current tone
% tone = squeeze(personalised_equalised_mod_tones(i, 1, :));
% % tone = squeeze(mod_tones(i, 1, :));
% % Print the frequency
% fprintf('Playing Personally equalised tone %d of %d, Frequency: %.2f Hz\n', i, size(unequalised_mod_tones, 1), Sequence4InNormalForm(i)); % change back
% % Play the tone without normalization
% sound(tone, fs);
% % Wait for the tone to finish (0.2 seconds) plus the pause time
% pause(0.2 + pause_time);
% end
% 
% pause(2)
% 
% % Loop through all tones
% for i = 1:100%[12 30 12 30 12 30]%1:30%size(mod_tones, 1)
% % Extract the current tone
% tone = squeeze(andrew_equalised_mod_tones(i, 1, :));
% % tone = squeeze(mod_tones(i, 1, :));
% % Print the frequency
% fprintf('Playing Andrew-equalised tone %d of %d, Frequency: %.2f Hz\n', i, size(andrew_equalised_mod_tones, 1), Sequence4InNormalForm(i)); % change back
% % Play the tone without normalization
% sound(tone, fs);
% % Wait for the tone to finish (0.2 seconds) plus the pause time
% pause(0.2 + pause_time);
% end
% 
% %% playback length array
% itilen                      =   cfg.iti*cfg.sound.MEG.samp_rate;                % length of iti
% padlen                      =   cfg.padding*cfg.sound.MEG.samp_rate;            % length of padding
% nplayback                   =   cfg.playbacklength;
% halfpad                     =   cfg.padding/2;                              % split padding before and after stim
% % what is the iti length
% if nplayback > 1       % if we sample multiple together
%     playbacklength          =   size(mod_tones,3) + padlen + itilen;        % take length + iti
% else
%     playbacklength          =   size(mod_tones,3) + padlen;                 % take length without iti for single pres mode
% end
% 
% % load fixation bull into memory
% BullTex(1)     = get_bull_tex_2(w, cfg.visual.bull_eye_col, cfg.visual.bull_in_col, cfg.visual.bull_out_col, cfg.visual.bull_fixrads);
% BullTex(2)     = get_bull_tex_2(w, cfg.visual.bull_eye_col, cfg.visual.bull_in_col_cor, cfg.visual.bull_out_col, cfg.visual.bull_fixrads);
% BullTex(3)     = get_bull_tex_2(w, cfg.visual.bull_eye_col, cfg.visual.bull_in_col_inc, cfg.visual.bull_out_col, cfg.visual.bull_fixrads);
% 
% 
% %% INITIALIZE
% PsychPortAudio('Close'); 
% InitializePsychSound(1);
% pahandle = PsychPortAudio('Open', [], 1, 2, cfg.sound.MEG.samp_rate, 1, [], []);
% B = cfg.setup.B;
% 
% % set keys
% nextkey             =   cfg.keys.next;        % key for next trigger
% esckey              =   cfg.keys.esckey;      % key for escape key
% shiftkey            =   cfg.keys.shiftkey;    % key for shiftkey
% 
% % visualy
% bullrect            =   CenterRect([0 0 cfg.visual.bullsize cfg.visual.bullsize], screenrect);
% 
% % set relative start timings for later use
% reltime             =   0:cfg.tpb-1;                                        % set relative time array
% reltime             =   reltime*(cfg.stim_t+cfg.iti);                       % at what relative time to actually present each stimuli
% presdelay           =   cfg.MEG.pressdelay;                                 % schedule one TR in advance to garantee timings
% reltime             =   reltime + presdelay - halfpad;                      % alter relative time to add presentation delay (and to ignore padding)
% blockWait           =   repmat([cfg.MEG.wait_onset  repmat(cfg.MEG.ibi, 1, cfg.MEG.bpr - 1)], 1, cfg.MEG.n_runs); % time to wait for each block
% expendpos           =   linspace(cfg.stim_t + cfg.padding, (cfg.stim_t + cfg.padding) * cfg.tpb, cfg.tpb); % calculate expected endpositions in order to resync over/undershoots
% 
% % save pres frequency info (in hz) into timingz matrix
% timingz( 11, :)     =   reshape(log_pres_freq.',1,[]);                      % [11]: The presented log frequency this trial
% timingz( 12, :)     =   reshape(Sequence4InNormalForm.',1,[]);                          % [12]: The presented frequency this trial
% 
% 
% %% RUN CLICK SOUND FOR FAILSAFE SYNCRONISATION
% 
% % generate the sound
% duration = 0.01; % Duration of the click (seconds) -   10ms
% click = [ones(1, round(cfg.sound.MEG.samp_rate*duration)), zeros(1, round(cfg.sound.MEG.samp_rate*duration))]; % Generate the click
% 
% % put sound in buffer
% PsychPortAudio('FillBuffer', pahandle, click); 
% 
% % play the sound 3 times with 0.5 seconds intervals
% for i = 1:3
%     triggerTime = GetSecs();
%     [clickonset]  = PsychPortAudio('Start', pahandle, [], triggerTime+0.1); % play audio at timing (waitForStart>1?)
%     cfg.setup.B.sendTrigger(i+3);
%     WaitSecs(0.5); % pause for 0.5 seconds before playing again
% end
% 
% %% RUN TRIALS
% rblk                =   (str2double(wrun)-1)*cfg.MEG.bpr + 1;                   % set at what block to start
% responses           =   [];                                                 % empty, for future expension
% 
% % load saved timingz of previous runs
% if rblk > 1
%     load (fullfile( pwd, 'data', ppnum, [ppnum '-mainpred.mat']), 'responses', 'segmentz', 'timingz');
% end
% 
% % present waiting for scanner message till first pulse
% multilinetext(w, cfg.visual.waitforstartexp, screenrect, ...
%               equal.fontsize, equal.textfont, equal.textcol, 1.2, [3]);
% %Screen('Flip', w);
% waitforbitsi(nextkey, esckey, shiftkey, B, segmentz, responses, timingz);  waitfornokey;
% 
% % loop over runs (with possible resume point)
% for crun = str2double(wrun):cfg.MEG.n_runs
% 
%     % sellect block range for run
%     rblk                =   (crun-1)*cfg.MEG.bpr + 1;                                                          % adjust block
% 
%     % give run information
%     multilinetext(w, {['Block ' num2str(crun) '/' num2str(cfg.MEG.n_runs)], ' ', cfg.visual.waitforstartblock{1}}, screenrect, ...
%                   equal.fontsize, equal.textfont, equal.textcol, 1.2, []);
%     Screen('Flip', w);
%     waitforbitsi(nextkey, esckey, shiftkey, B, segmentz, responses, timingz);  waitfornokey;
% 
%     % run over blocks for this run
%     for block = rblk:rblk+cfg.MEG.bpr-1 
% 
%         %% Prepair things in TRs before a block starts
%     
%         % set new temporary arrays for this block
%         start_times     =   nan(1, cfg.tpb);
%         est_stops       =   nan(1, cfg.tpb);
%         real_pres_len   =   nan(1, cfg.tpb);
%         all_endpos      =   nan(1, cfg.tpb);
%     
%         % start waiting for triggers
%         waitforsc      = blockWait(block);     % get waiting period for this block
%         while waitforsc > 0
%     
%             % start measuring pulses
%             blockstarttime      = WaitSecs(1); 
%     
%             % draw fixation
%             Screen('DrawTexture',w,BullTex(1),[],bullrect);
%             [~] = Screen('Flip', w);
%     
%             % prepair things at the right time
%             if waitforsc == 1                              % when the last pulse before stim onset occured
%     
%                 % prepair new block
%                 timingz( 5, timingz(2,:) == block)          =   reltime + blockstarttime;                           % [5]: What time should we start present each trial
%                 timingz( 6, timingz(2,:) == block)          =   reltime + blockstarttime + cfg.stim_t + cfg.padding;% [6]: What time should we stop present each trial
%                 start_sched                                 =   timingz( 5, timingz(2,:) == block);                 % for faster loading save it also in a small temp array
%                 stop_sched                                  =   timingz( 6, timingz(2,:) == block);                 % idem
%                 
%             elseif waitforsc == blockWait(block)           % after the first waiting pulse place everything in buffer
%     
%                 % place current block into the audio buffer
%                 p                                           =   padlen/2;
%                 blockAudio                                  =   zeros(size(personalised_equalised_mod_tones,2), playbacklength);           % predefine zero array
%                                 
%                 blockAudio(:, p+1:size(personalised_equalised_mod_tones,3)+p)      =   squeeze(personalised_equalised_mod_tones(block,:,:));                      % take waveform data from this block
%                 if nplayback > 1
%                         blockAudio          =   reshape(blockAudio', [], size(blockAudio,1)/nplayback)';            % if nplayback is longer then single trial, add iti in buffer
%                         blockAudio          =   blockAudio(:,1:end-itilen);                                         % and remove silent periode between snippets
%                 end
%                 blockAudio                                  =   squeeze(reshape(blockAudio', 1, []));               % take long format
%                 blockAudio                                  =   relloudnes' .* blockAudio;                          % modify intensity left / right
%                 
%                 %blockAudioStereo = repmat(blockAudio, 2, 1);
% 
%                 %PsychPortAudio('FillBuffer', pahandle, blockAudioStereo);                                                 % fill buffer with this array
%                 PsychPortAudio('FillBuffer', pahandle, blockAudio);                                                 % fill buffer with this array
%             end
%     
%             % count
%             waitforsc                                       =   waitforsc -1;          % countdown waitTRs
%         end
%     
%         plot(blockAudio(1,1:10000))
%         
%         %% Main presentation phase of block
%         % loop over trials in block
%         sync_del            =   0;                      % compensate for over/undershoots of bufferplay
%         for trial           =   1:nplayback:cfg.tpb     % go throught trials in steps of nplaybacklength
%             trialend        =   trial+nplayback-1;      % get where we end (if nplaybacklength is 1, this is identical to 'trial')
% 
%             % define what trigger to send
%             if trial == 1                                                                           % if start of block
%                 sendtrg = cfg.MEG.trigger.blockOnset + block;
%             elseif rem(trial-1, cfg.tps) == 0                                                       % if start of segment
%                 sendtrg = cfg.MEG.trigger.segmentOnset + timingz( 4, (timingz(2,:) == block) & (timingz(3,:) == trial));
%             else
%                 sendtrg = cfg.MEG.trigger.stimOnset;
%             end
% 
%             % use scheduled start and stop times to start/stop playing
%             PsychPortAudio('Start', pahandle, 1, ...                                                % start/stop audio playback at predefined timings
%                             start_sched(trial), ...
%                             1, ...
%                             stop_sched(trialend) + sync_del, 1);  
%             cfg.setup.B.sendTrigger(sendtrg);                                                       % sent on-trigger to MEG system  
%             % stop at correct time
%             [startTime, endPos, ~, estStop]    = PsychPortAudio('Stop', pahandle, 3);               % stop when finished and save timings
%             cfg.setup.B.sendTrigger(cfg.MEG.trigger.stimOffset);                                    % set off-trigger to MEG system
% 
%             % save trial timings
%             start_times(trial)          = startTime;            % real start times of trial
%             est_stops(trialend)         = estStop;              % estimated real stop times of trial
%             real_pres_len(trial)        = estStop-startTime;    % real presentation length of trial
%             all_endpos(trialend)        = endPos;               % endpostion in sec of buffered audio relative to buffer
%     
%             % compensate for current delay
%             sync_del                    = expendpos(trial) - endPos;
%         end
%     
%         % get end of block indication
%         cfg.setup.B.sendTrigger(cfg.MEG.trigger.blockOffset)    % end of block trigger
% 
%         %% save timings of this block into the full array
%         timingz( 7, timingz(2,:) == block)            =   start_times;          % [7]: The real start time of a trial 
%         timingz( 8, timingz(2,:) == block)            =   est_stops;            % [8]: The estimated real stop time of a trial
%         timingz( 9, timingz(2,:) == block)            =   real_pres_len;        % [9]: The real presentation length of a trial
%         timingz( 10, timingz(2,:) == block)           =   all_endpos;           % [10]: The enpostion in sec of buffered audio relative to buffered snipped
%     
%     end
% 
%     %% END OF BLOCK
%     save (fullfile( pwd, 'data', ppnum, [ppnum '-mainpred.mat']), 'responses', 'segmentz', 'timingz', 'cfg', 'B');         % already save data (for possible crashes etc.)
% 
%     % present end of block text
%     multilinetext(w, cfg.visual.endofblock, screenrect, ...
%                   equal.fontsize, equal.textfont, equal.textcol, 1.2, []);
%     Screen('Flip', w);
%     waitforbitsi(nextkey, esckey, shiftkey, B, segmentz, responses, timingz);  waitfornokey;
% 
% end
% 
% 
% %% SHUT DOWN AND SAVE DATA
% save (fullfile( pwd, 'data', ppnum, [ppnum '-mainpred.mat']), 'responses', 'segmentz', 'timingz', 'cfg', 'B');
% PsychPortAudio('Close'); 
% cfg.setup.B.close();
% 
% % end