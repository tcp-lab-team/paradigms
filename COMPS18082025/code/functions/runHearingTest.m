function runHearingTest(hearingTestToneFilePath, window, screenXpixels, screenYpixels, pahandle, screens)
% runHearingTest Runs a quick hearing test playing a specific tone.
%
% Inputs:
%   - hearingTestToneFilePath: path to the audio file (wav) to use as the beep tone.
%   - window: Psychtoolbox window pointer.
%   - screenXpixels, screenYpixels: screen dimensions.
%   - pahandle: PsychPortAudio handle already initialized.
%   - current_dir: directory path for instruction images.
%
% No outputs, just runs the test and shows instructions on screen.

    hearing_test_soa = 1; % seconds between beep onsets
    repeatHearingTest = true;

    % Load the tone audio data from toneFilePath
    [y, ~] = audioread(hearingTestToneFilePath);
    soundData = {y'};
    
    % Fill buffer once outside loop
    PsychPortAudio('FillBuffer', pahandle, soundData{1});

    while repeatHearingTest
        % Draw "Can you hear?" instruction screen
        Screen('DrawTexture', window, screens.canYouHear, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
        Screen('Flip', window);

        keyPressed = false;
        startTime = GetSecs;

        while ~keyPressed
            % Play beep sound
            PsychPortAudio('Start', pahandle, 1, 0, 1);

            % Wait for response or timeout
            while GetSecs - startTime < hearing_test_soa
                [keyIsDown, ~, keyCode] = KbCheck();
                if keyIsDown
                    if keyCode(KbName('1!')) % Yes
                        disp('Yes: User can hear the beep.');
                        repeatHearingTest = false;
                        keyPressed = true;
                        break;
                    elseif keyCode(KbName('2@')) % No
                        disp('No: User cannot hear the beep.');

                        % Show assistance screen
                        Screen('DrawTexture', window, screens.fixingAudio, [], [0 0 screenXpixels screenYpixels], 0, [], 1);
                        Screen('Flip', window);

                        WaitSecs(5);
                        keyPressed = true;
                        break;
                    end
                end
            end

            if keyPressed
                break;
            end

            startTime = GetSecs;
        end
    end

    PsychPortAudio('Stop', pahandle);
end
