function playSound(filename, volume, stimulus_duration, scaleFactor)
    % This function plays an audio file, scales it to the correct volume,
    % and adjusts its duration based on the stimulus_duration.
    
    % Load the .wav file (replace with the actual path to your .wav file)
    [wavData, fsFile] = audioread(filename); 

    % Desired sampling frequency
    fs = 48000; 
    
    % Check if the sampling rate matches; if not, resample the audio
    if fsFile ~= fs
        disp('Warning: Resampling the audio to match the desired sampling frequency.');
        wavData = resample(wavData, fs, fsFile);
    end
    
    % Normalize the .wav file to ensure it's in the range [-1, 1]
    wavData = scaleFactor * wavData / max(abs(wavData)); % Normalize to avoid clipping
    
    % Calculate the number of samples required to match the stimulus duration
    numSamples = round(stimulus_duration * fs); 

    % Calculate the number of repetitions required to cover the stimulus duration
    numRepeats = ceil(numSamples / length(wavData)); 

    % Create a seamless loop by repeating the audio
    repeatedSound = repmat(wavData, numRepeats, 1);

    % Trim to the exact length needed for the stimulus duration (no extra gap)
    repeatedSound = repeatedSound(1:numSamples, :);

    % Scale the sound to the correct volume (dB)
    volume_db = 10^(volume / 20); % Convert dB to amplitude
    repeatedSound = repeatedSound * volume_db;

    % Play the sound for the stimulus duration
    sound(repeatedSound, fs);
end
