function [spkTime,spkWav] = detectSpikes(rawData,Fs)
% This function detects negatively deflecting spikes in broadband data. 
% Inputs:  rawData - broadband (or hp filtered) signal recorded invasively
%          Fs      - Sample rate of input signal
% Outputs: spkTime - Vector of the timestamp of each detected spike
%          spkWav  - Matrix of spike waveforms
% I.S. 2016

w_pre         = round(0.001*Fs);  % 1ms number of pre-event data points stored (def. 20)
w_post        = round(0.0025*Fs); % 2.5ms number of post-event data points stored (def. 44)
stdmin        = -4;               % minimum threshold (def. 5)
detect_fmin   = 300;              % high pass filter for detection 
detect_fmax   = 5000;             % low pass filter for detection 
min_ref_per   = round(0.0015*Fs); % detector dead time (in ms)

% define filter
ford  = 4; % define filter order - this may have to be higher if there are large amplitude low-frequency fluctuations in the data
[b,a] = butter(ford,[detect_fmin detect_fmax]/(Fs/2),'bandpass');

% filter data
hpFiltered = filter(b,a,rawData);

% define threshold
thresh = stdmin * std(hpFiltered);

% extract spike indices
spikeInds(1,:) = find( hpFiltered(1:end-1) > thresh & hpFiltered(2:end) <= thresh);

% delete spikes that occur during dead-time
spikeInds(find(diff(spikeInds) < min_ref_per) + 1) = [];
spikeInds(spikeInds<(3*Fs)) = [];
spikeInds(spikeInds>(numel(rawData)/Fs-0.1)*Fs) = [];

spkTime = spikeInds/Fs; % convert sample to time

% extract spike waveforms
spkMat  = repmat(spikeInds',1,numel(-w_pre:w_post));
subMat  = repmat((-w_pre:w_post),numel(spikeInds),1);
spkInd  = spkMat + subMat;
spkSamp = reshape(spkInd',[1 numel(spikeInds)*numel(-w_pre:w_post)]);

spkWav = reshape(hpFiltered(spkSamp),[numel(-w_pre:w_post) numel(spikeInds)])';

