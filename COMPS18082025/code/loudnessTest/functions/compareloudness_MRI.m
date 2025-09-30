function [relloudness, cc] = compareloudness_MRI(refstim,compstim,equal, w, screenrect)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                      %
%      MAIN EQUALISATION TASK, COMPARISON ON TWO TONES IN LOUDNESS     %
%                                                                      %                                                                      %%
%    Input:                                                            %
%      - refstim: [lengthstim x 1] sound sequence of refference        %
%      - compstim: [lengthstim x loudnesses] sequence of target        %
%      - equal: struct with settings for equalistation                 %
%      - [w, screenrect]: psychtoolbox drawscreen                      %
%                                                                      %
%    Return:                                                           %
%      - relloudness: relative loudness value compared to refference   %
%      - cc: last pressed button                                       %
%                                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert needed inputs into variables
ind_loud    =  equal.ind_loud;
samp_rate   =  equal.samp_rate;
sil_gap     =  equal.sil_gap;
out         =  0; % for while loop

% Work out which device we're on (i.e. are we on Daniel's
% laptop or in the FIL/testroom), so we can adjust settings accordingly

[~, hostname] = system('hostname'); 
hostname = strtrim(hostname); % Remove random trailing whitespace

% Change setup depending on device

if contains(hostname, 'meg', 'Ignorecase', true) % If we're in the actual MEG ROOM

    mode = 'meg'; % Turns the triggers on
    device_id = []; % Switches audio device output to FIL audio output

elseif contains(hostname, 'stimulus', 'Ignorecase', true) % If we're in the FIL TEST ROOM

    mode = 'meg'; % Turns the triggers on
    device_id = []; % Switches audio device output to test room audio output

else % If we're on a non-FIL device
    
    mode = 'debug'; % Switches off the triggers so code runs on non-FIL device
    device_id = []; % Switches audio device output to non-FIL audio output

end

KbName('UnifyKeyNames');    % enable unified mode KbName
KbCheck;
ListenChar(2);              % disable output of keypresses 

% Perform basic initialization of the sound driver:
PsychPortAudio('Close');
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', device_id, 1, 1, samp_rate, equal.nrchannels,[],1);

% load fixation bull into memory
BullTex(1)     = get_bull_tex_2(w, equal.bull_eye_col, equal.bull_in_col, equal.bull_out_col, equal.bull_fixrads);
bullrect       = CenterRect([0 0 equal.bullsize equal.bullsize], screenrect);

% wait for key stroke
%keys = imread('loudnessTestKeys.jpg');
%keys = Screen('MakeTexture', w, keys);
%Screen('DrawTexture', w, keys);
%Screen('Flip', w); KbWait(-1, 3);

% main equalisation procedure
first_loop = true;  % flag to track first iteration
while out~=1
    
    % draw fixation
    Screen('DrawTexture',w,BullTex(1),[],bullrect);
    [~] = Screen('Flip', w);
    
    % build stim
    stim = refstim';
    if first_loop
        % Add 0.5s silence at the start only for first iteration
        stim = [zeros(1, samp_rate * 0.5), stim];
        first_loop = false;  % reset flag after first iteration
    end
    stim = [stim,zeros(1,samp_rate*sil_gap)];       % add silence gap
    stim = [stim,squeeze(compstim(ind_loud,:))];    % add compare sound
    
    % Prepare and play audio with proper buffering
    PsychPortAudio('FillBuffer', pahandle, stim);
    PsychPortAudio('Start', pahandle, 1, 0, 1);
    % Wait for audio to finish playing
    PsychPortAudio('Stop', pahandle, 1, 1);
    
    % wait for key stroke
    keys = imread('loudnessTestKeys.jpg');
    keys = Screen('MakeTexture', w, keys);
    Screen('DrawTexture', w, keys);
    WaitSecs(0.3);
    Screen('Flip', w);% Show the drawn text at next display refresh cycle
    
    %wait for input
    [~, keyCode] = KbWait(-1,3);
    
    %find out which key was pressed
    cc=KbName(keyCode);  %translate code into letter (string)
    
    %calculate performance or detect forced exit
    if strcmp(cc,'ESCAPE') % if escape was pressed
        sca; 
        break; 
    elseif strcmp(cc,'1!')
        ind_loud = ind_loud+1;
        ind_loud = min(ind_loud,size(compstim,1));
    elseif strcmp(cc,'2@')
        ind_loud = ind_loud-1;
        ind_loud = max(ind_loud,1);
    elseif strcmp(cc,'3#')
        out = 1;
    end
    
end
relloudness = ind_loud;     % save new relative loudness
PsychPortAudio('Close', pahandle);% Close the audio device: