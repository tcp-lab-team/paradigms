% TEST_TONE_GENERATOR Demo for the TONE_GENERATOR routine.
%
%   See also TONE_GENERATOR.

%   Author: Kamil Wojcicki, UTD, November 2011.

clear all; close all; clc; randn('seed',0); rand('seed',0); fprintf('.\n');


% inline function for periodogram spectrum computation
psd = @(x,w,nfft)( 10*log10(abs(fftshift(fft(x(:).'*diag(w(length(x))),nfft))).^2/length(x)) );


% define common parameters
fs = 48E3;                              % sampling frequency (Hz)
duration = 50;                          % signal duration (ms)
N = floor(duration*1E-3*fs);            % signal length (samples)
nfft = 2^nextpow2( 4*N );               % FFT analysis length
freq = [ 0:nfft-1 ]/nfft*fs - fs/2;     % frequency vector (Hz)
%   window = @hanning;                      % analysis window function
%   window = @(N)( chebwin(N,40) );         % analysis window function
window = @(N)( chebwin(N,100) );        % analysis window function


% define parameters specific to generation of the single pure tone signal
amplitude = 1;                          % pure tone amplitude
frequency = 5E2;                        % pure tone frequency (Hz)
phase = pi/16;                          % pure tone phase (rad/sec)
fade_duration = 10;                     % fade-in and fade-out duration (ms)
fade_window = @(N)( hanning(N).^2 );    % fade-in and fade-out window function handle

% Generate standard tone
[standard,time] = tone_generator(fs,duration,amplitude,frequency,phase,fade_duration,fade_window);
figure; plot(time,standard); title('Standard');
sound(standard,fs);
audiowrite('standard.wav',standard,fs);

% Generate deviant tone
duration = 100;    
[deviant,time] = tone_generator(fs,duration,amplitude,frequency,phase,fade_duration,fade_window);
figure; plot(time,deviant); title('Deviant');
sound(deviant,fs);
audiowrite('deviant.wav',deviant,fs);


% Try generating a tone sequence:
tone_sequence = [standard zeros(1,fs*.5) standard zeros(1,fs*.5) standard zeros(1,fs*.5) deviant zeros(1,fs*.45) standard zeros(1,fs*.5)];
sound(tone_sequence,fs);
audiowrite('tone_sequence.wav',tone_sequence,fs);
