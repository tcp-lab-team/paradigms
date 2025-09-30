function all_loudness = leftrightequalization(ppnum, wrun, setup)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Fast acces for testing purpos                                                        %
%                                                                                       %
% addpath(genpath([pwd '/functions/']));addpath(genpath([pwd '/stimuli/']));startup1;   %
% Screen( 'Preference', 'SkipSyncTests', 1);                                            %
% ppnum ='997'; wrun ='1'; setup =0; % set to 2 for fMRI                                    %
%                                                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SETTINGS

% equalisation (copy pasted from mainequalisation, only used for ref)
settings_tonotopy;                                  % fetch some information from tonotopy settings
equal.refstim         =   6;                        % what stimulus to use as refference
equal.refloud         =   9;                        % what is the 'refference' loudness
equal.minfreq         =   cfg.minfreq;              % minimum frequency to equalize
equal.maxfreq         =   cfg.maxfreq;              % maxiumum frequency to equalize
equal.nfreq           =   9;                        % number of frequencies to use in equalisation
equal.freq0           =   2.^(linspace(log2(equal.minfreq),log2(equal.maxfreq),equal.nfreq));     % create logspace freq array

% sound
equal.sampdur         =   0.8;                      % duration of sample in ms
equal.sil_gap         =   0.4;                      % length of sillence gap
equal.intloudness     =   logspace(-1, 0, 18);      % set loudness levels
equal.ampl            =   .95;                      % amplitude
equal.nrchannels      =   2;                        % number of channels used
equal.samp_rate       =   cfg.sound.samp_rate;      % sampling rate used

% amplitude mod
equal.amplmod         =   8;                        % frequency of amplitude modulation
equal.mod_index       =   1;                        % index of amplitude mod
equal.mod_min         =   0;                        % minimum of amplitude modulation

% misc
equal.fontsize        =   cfg.visual.fontsize;      % set fontsize
equal.backgr          =   cfg.visual.backgr;        % set background collor
if IsWin 
    equal.textfont    = 'Calibri';                  % set fontfamily 
elseif IsOSX
    equal.textfont    = 'Arial';
end
equal.textcol         =   cfg.visual.c3*1;          % set text color
equal.introtxt        =   {'Judge the loudness of the sounds between ears', ' ', '(Press any key to continue)'};
equal.keytxt          =   {'First sound louder: 1', 'Second sound louder: 2', ...
                           'Loudness about the same: 3', ' ','(Press any key to start)'};
equal.bull_eye_col    =   cfg.visual.bull_eye_col;  % color of bullseye
equal.bull_in_col     =   cfg.visual.bull_in_col;   % color of inner ring
equal.bull_out_col    =   cfg.visual.bull_out_col;  % color of outer ring

equal.bull_fixrads    =   cfg.visual.bull_fixrads;  % radious of bulls
equal.bullsize        =   cfg.visual.bullsize;


%% CREATE SOUND SAMPLES

% set waveform values
soundmatrix           = zeros(length(equal.intloudness), ...                % precreate sound matrix
                              equal.sampdur * equal.samp_rate);
modwave               = createwaveform(equal.amplmod, ...                   % create waveform for amplitude mod
                                       equal.sampdur, ...
                                       equal.samp_rate); 
modwave               = ((equal.mod_index  * modwave) + 1)/ ...             % adjust modulatotion waveform (if needed)
                          (2/(equal.mod_index-equal.mod_min )) + equal.mod_min ;  
freq0waves            = equal.ampl * createwaveform(equal.freq0(equal.refstim), ...        % create waveforms for all f0s
                                                    equal.sampdur, ...
                                                    equal.samp_rate);

% apply loudness modulation and set for all loudnesses
moddedwaves           = freq0waves .* modwave;
for iloud = 1:size(soundmatrix,1)
    soundmatrix(iloud,:)      =   moddedwaves * equal.intloudness(iloud); % set loudnesses and fit into soundmatrix
end

%% DO ACTUAL EQUALISATION

% prepair everything
equal.ind_louds         = ones(1, 2) * equal.refloud;   % set initial value to refloudness

% set start comparison value
equal.ind_loud = equal.ind_louds(1);

% compare loudness to refference and save
if setup == 3
    [trainloudness,cc]      = compareloudness_leftright_MEG(soundmatrix, ...
                                                        equal, w, screenrect);    
else
    [trainloudness,cc]      = compareloudness_leftright(soundmatrix, ...
                                                        equal, w, screenrect);
end

relloudnes = [1, equal.intloudness(equal.refloud) / equal.intloudness(trainloudness)];
relloudnes = relloudnes / max(relloudnes);

%% SHUT DOWN AND SAVE DATA
save (fullfile( pwd, 'loudness', ppnum, [ppnum '-rl_loudness.mat']), 'relloudnes');

% cleanup
ShowCursor;     ListenChar;     sca;    clearvars;


end