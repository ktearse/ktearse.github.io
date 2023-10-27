% P20A HW7: Electronic music passage
% Author: Katherine Tearse UID 906065514
% Date: 5/27/2023

% required file: billieJean.mp4
% created file: psych20ahw8audio.mp4

clear       %clear previously defined variables
clc         %clear command window
close all   %close figure windows
rng shuffle %shuffle random number generator


%% DRUMS
[billieJean, sampleRate] = audioread("billieJean.mp4");              %read audio file

%Create drums, containing first 4 drum beats
drums = billieJean(8000:100000, :);

%Loop drums
numDrumLoops = 32;
drumsLoop = repmat(drums, numDrumLoops, 1);

%% BASS TONES

%Define variables to use to create bass tones
drumsNumSamples = height(drums);
drumsSecs = drumsNumSamples / sampleRate;

%Create 110Hz sine wave
tone110Secs = drumsSecs;
tone110Freq = 110;
tone110NumSamples = ceil(drumsSecs * sampleRate) ;
tone110TimeVector = linspace(0, tone110Secs, tone110NumSamples);
sineTone110Hz = sin(2 * pi * tone110Freq * tone110TimeVector)';

%Create 98Hz sine wave
tone98Secs = drumsSecs;
tone98Freq = 98;
tone98NumSamples = ceil(drumsSecs * sampleRate) ;
tone98TimeVector = linspace(0, tone98Secs, tone98NumSamples);
sineTone98Hz = sin(2 * pi * tone98Freq * tone98TimeVector)';

%Apply fadeout to both sineTones
fadeVector = linspace(1, 0, drumsNumSamples)' ; 
sineTone110Hz = sineTone110Hz.* fadeVector;
sineTone98Hz = sineTone98Hz.* fadeVector;

%Create sweep sine wave
freqInitial = 196;                     
freqFinal = 110;           
sweepVector = linspace(freqInitial, freqFinal, drumsNumSamples);
sweep = sin(2 * pi * cumsum(sweepVector) / sampleRate)'; 

%Create bassline
bassLine = [sineTone110Hz; sineTone98Hz; sineTone110Hz; sineTone98Hz; sineTone110Hz; sineTone98Hz; sineTone110Hz; sweep];
bassLine = bassLine /max(abs(bassLine));

%Loop bassLine to create bassLoop
bassLoop = repmat(bassLine, numDrumLoops/8, 1);


%% SAWTOOTH TONE make sure it loops right
%Create sawtooth tone
sawToneWidth = 0;
sawToneFreq = 110;
sawToneTimeVector =  linspace(0, drumsSecs, drumsNumSamples);
sawTone110Hz = sawtooth(2 * pi * sawToneFreq * sawToneTimeVector, sawToneWidth)'; 

%Apply fade 
sawToneFadeVector = fadeVector.^2;
sawTone110Hz = sawTone110Hz.* sawToneFadeVector;

%Create and apply pad to end of sawtooth tone
sawToneNumSamples = height(sawTone110Hz);
sawToneSecs = sawToneNumSamples /sampleRate;
sawTonePadNumSamples = sawToneNumSamples * 3;
sawTonePad = zeros(276003, 1);
sawTone110Hz = [sawTone110Hz; sawTonePad];

%Loop sawtooth tone to create sawLoop
sawLoop = repmat(sawTone110Hz, numDrumLoops/4, 1); 

%% WHITE NOISE

%Create white noise tones and apply fa
whiteNoiseSecs = 4 * drumsSecs;
whiteNoiseSecsSamples = round(whiteNoiseSecs * sampleRate);
whiteNoiseNumSamples = drumsNumSamples*4; 
whiteNoise1 = randn(whiteNoiseSecsSamples, 1);
whiteNoise2 = randn(whiteNoiseSecsSamples, 1);

%Apply fade in
whiteNoiseFadeInVector = (linspace(0, 1, whiteNoiseNumSamples)' ).^3;
whiteNoise1 = whiteNoise1 .* (whiteNoiseFadeInVector);
whiteNoise2 = whiteNoise2 .* (whiteNoiseFadeInVector);
whiteNoise = whiteNoise1 + whiteNoise2;

%Rescale white Noise so each channel's RMS = 0.01
targetWhiteNoiseRMS = 0.01;
currentWhiteNoiseRMS = sqrt(mean(whiteNoise.^2));
whiteNoise = whiteNoise * targetWhiteNoiseRMS/currentWhiteNoiseRMS;

%Loop whiteNoise to create whiteNoiseLoop
whiteNoiseLoop = repmat(whiteNoise, numDrumLoops/4, 1);


%% RANDOM TONES

%Define variables for use in creating randTonesStereo
drumsLoopNumSamples = height(drumsLoop);
drumsLoopSecs = drumsLoopNumSamples / sampleRate;

randTonesStereo1 = cell(16*numDrumLoops,2);  %Create temporary variable to store cell array
for i = 1:16*numDrumLoops
    
    %Create random sine tone 
    toneRandFreq = 110* randi([2 10]);
    toneRandSecs = drumsLoopSecs/(16*numDrumLoops);
    toneRandNumSamples = ceil(toneRandSecs * sampleRate);
    toneRandTimeVector = linspace(0, toneRandSecs, toneRandNumSamples);
    sineToneRandom = sin(2*pi * toneRandFreq * toneRandTimeVector)';
    
    %Apply fade to sine tone
    fadeVectorRandom = linspace(1, 0, toneRandNumSamples)'; 
    sineToneRandom = sineToneRandom.* fadeVectorRandom;
    randomNumber = rand;
    
    %Make the position in stereo field random
    leftChannel = sineToneRandom.* rand;
    rightChannel = sineToneRandom.* (1-rand);

    %Add both channels to the temporary cell array
    randTonesStereo1{i, 1} = leftChannel;
    randTonesStereo1{i, 2} = rightChannel;
end

randTonesStereo = cell2mat(randTonesStereo1);      %Convert the cell array to an array
randTonesStereo = randTonesStereo(1:height(drumsLoop), 1:2); %Trim off the end to make randTonesStereo the same length as bassLoop for mixing

%% FINAL SIGNAL

%Mix the sounds together to create the final signal
signal = drumsLoop + bassLoop + .05*sawLoop + whiteNoiseLoop + .5*randTonesStereo;

%Apply linear fadeout across last 20 seconds of signal 
signalNumSamples = height(signal);          
signalSecs = signalNumSamples / sampleRate; %Determine how long signal is to find last 20 seconds

signalLast20Index = (signalSecs - 20) * sampleRate;
signalBeforeLast20 = signal(1:signalLast20Index, :);  %split signal into first section
signalLast20 = signal(signalLast20Index:end, :);      %    and last 20 seconds

signalLast20FadeVector = linspace(1, 0, height(signalLast20))';  %create fade vector
signalLast20Faded = signalLast20.* signalLast20FadeVector;       %apply fade vector

signal = [signalBeforeLast20; signalLast20Faded];                %rejoin first ~46 seconds and last 20 seconds into signal

%Normalize signal
signal = signal / max(abs(signal(:)));

%Save to psych20ahw8audio.mp4
audiowrite('psych20ahw8audio.mp4', signal, sampleRate)

%Play signal
sound(signal, sampleRate)
pause 
clear sound

