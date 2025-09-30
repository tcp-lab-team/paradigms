function equaliseCASTones(ppnum)

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


% addpath(genpath('C:\Users\compi\Documents\COMPS\code\tasks\pred_adapt_MEG_COPY\functions'))

% function mainpredsound_MEG(ppnum, wrun, setup)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fast acces for testing purpos                                                        %
%                                                                                       %
addpath(genpath([pwd '/functions/']));addpath(genpath([pwd '/stimuli/']));%startup1;   %
%Screen( 'Preference', 'SkipSyncTests', 1);                                            %
ppnum = num2str(ppnum);
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

load('sequence4InNormalForm.mat');

[~, unequalised_mod_tones] = create_tones_main(Sequence4InNormalForm, cfg.stim_t, cfg.sound.MEG.samp_rate, ...
                                                    cfg.ramp_ops, cfg.ramp_dns);

%% apply PERSONALISED equalised loudness curves for sequence4

% Get the current script's directory
current_dir = fileparts(mfilename('fullpath'));

if exist(fullfile(current_dir, 'subjectDataSaved', [ppnum '-loudness.mat']), 'file')
    % load loudness values for participant
    load(fullfile(current_dir, 'subjectDataSaved', [ppnum '-loudness.mat']), 'all_loudness', 'equal');  
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


%% Save the Personally equalised tones

% Create stimuli directories if they don't exist
parent_dir = fileparts(current_dir);  % Go up to tasks directory
cas_dir = fullfile(parent_dir, 'CASPart1');  % Path to CAS directory
cas2_dir = fullfile(parent_dir, 'CASPart2');  % Path to CASpart2 directory
cas3_dir = fullfile(parent_dir, 'CASPart3');  % Path to CASpart3 directory

stimuli_dir1 = fullfile(cas_dir, 'stimuli');  % Path to CASpart1/stimuli directory
stimuli_dir2 = fullfile(cas2_dir, 'stimuli');  % Path to CASpart2/stimuli directory
stimuli_dir3 = fullfile(cas3_dir, 'stimuli');  % Path to CASpart3/stimuli directory

% Save each tone as a separate file
for i = 1:size(personalised_equalised_mod_tones, 1)
    % Extract and process the tone
    tone = squeeze(personalised_equalised_mod_tones(i, 1, :))';
    
    % Create stereo tone and apply left-right equalisation
    stereo_tone = [tone; tone] .* relloudnes';
    
    % Determine which directory to save to and reset tone number
    if i <= 1992
        % First batch: CASpart1/stimuli
        tone_num = i;
        filename = fullfile(stimuli_dir1, sprintf('tone%d.wav', tone_num));
    elseif i <= 3984
        % Second batch: CASpart2/stimuli
        tone_num = i - 1992;
        filename = fullfile(stimuli_dir2, sprintf('tone%d.wav', tone_num));
    else
        % Third batch: CASpart3/stimuli
        tone_num = i - 3984;
        filename = fullfile(stimuli_dir3, sprintf('tone%d.wav', tone_num));
    end
    
    % Save as WAV file
    audiowrite(filename, stereo_tone', samp_rate);
    
    % Print progress every 100 tones
    if mod(i, 100) == 0
        disp(['Saved ' num2str(i) ' tones']);
    end
end

disp('Equalised tones generated!');

%% Generate standard tone for MMN

% Create single frequency tone (500 Hz)
standardFreq = 633;
cfg.stim_t = 0.05;  % 50ms duration

[~, unequalised_standard_tone] = create_tones_main(standardFreq, cfg.stim_t, cfg.sound.MEG.samp_rate, ...
                                                    cfg.ramp_ops, cfg.ramp_dns);

% Apply the same personalized equalization
log_standard_freq = log2(standardFreq);
[~, standard_idx] = min(abs(personalised_aprox_idx - log_standard_freq));
personalised_equalised_standard_tone = personalised_aprox_loudness(standard_idx) * unequalised_standard_tone;

% Create stereo tone and apply left-right equalisation
tone = squeeze(personalised_equalised_standard_tone)';
stereo_tone = [tone; tone] .* relloudnes';

% Save in MMNpart1/stimuli directory
mmn_dir = fullfile(parent_dir, 'MMNpart1');  % Path to MMN directory
mmn_stimuli_dir = fullfile(mmn_dir, 'stimuli');  % Path to MMNpart1/stimuli directory
filename = fullfile(mmn_stimuli_dir, 'standard.wav');
audiowrite(filename, stereo_tone', samp_rate);

% Save in MMNpart2/stimuli directory as well
mmn2_dir = fullfile(parent_dir, 'MMNpart2');  % Path to MMNpart2 directory
mmn2_stimuli_dir = fullfile(mmn2_dir, 'stimuli');  % Path to MMNpart2/stimuli directory
filename2 = fullfile(mmn2_stimuli_dir, 'standard.wav');
audiowrite(filename2, stereo_tone', samp_rate);

disp('Standard tone generated and saved!');

%% Generate deviant tone for MMN

% Create single frequency tone (1000 Hz)
deviantFreq = 1000;
cfg.stim_t = 0.1;  % 100ms duration

[~, unequalised_deviant_tone] = create_tones_main(deviantFreq, cfg.stim_t, cfg.sound.MEG.samp_rate, ...
                                                    cfg.ramp_ops, cfg.ramp_dns);

% Apply the same personalized equalization
log_deviant_freq = log2(deviantFreq);
[~, deviant_idx] = min(abs(personalised_aprox_idx - log_deviant_freq));
personalised_equalised_deviant_tone = personalised_aprox_loudness(deviant_idx) * unequalised_deviant_tone;

% Create stereo tone and apply left-right equalisation
tone = squeeze(personalised_equalised_deviant_tone)';
stereo_tone = [tone; tone] .* relloudnes';

% Save in MMNpart1/stimuli directory
filename = fullfile(mmn_stimuli_dir, 'deviant.wav');
audiowrite(filename, stereo_tone', samp_rate);

% Save in MMNpart2/stimuli directory as well
filename2 = fullfile(mmn2_stimuli_dir, 'deviant.wav');
audiowrite(filename2, stereo_tone', samp_rate);

disp('Deviant tone generated and saved!');