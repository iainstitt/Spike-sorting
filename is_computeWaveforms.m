function is_computeWaveforms(fpath)
% This function loads the raw data that was used to sort spikes in
% kilosort, and then computes the mean waveform from each channel for each
% spike cluster. 
% I.S. 2017
% inputs: fpath - the path to the file in which kilosort was run

fileToLoad = [fpath 'rawData.dat'];
d = dir(fileToLoad); % detect raw data file
numBytes = d.bytes; % get the number of bytes in the file
probeID = fpath(end-1); % detect probe ID
% determine number of channels based on probe ID
if strcmp(probeID,'C'); numChans = 16; 
elseif strcmp(probeID,'B'); numChans = 16;
else numChans = 32; end

szMat = [numChans (numBytes/numChans)/2]; % dimensions of the file
% load raw data matrix
fid = fopen(fileToLoad,'r');
dataMat = fread(fid,szMat,'*int16');
fclose(fid);

spkTimes = readNPY([fpath 'spike_times.npy']); % these are in samples, not seconds
spkClus = readNPY([fpath 'spike_clusters.npy']); % cluster ID's for each spike
mapFile = dir([fpath '*Map.mat']); % map file used for sorting
load([fpath mapFile.name]); % load map file
dataMat = dataMat(chanMap,:); % remap raw data into same format as kilosort

% load in sorting results
fileID   = fopen([fpath 'cluster_groups.csv']);
formatSpec = '%f %s';
LogFile = textscan(fileID,formatSpec,'HeaderLines',1,'Delimiter', '\t');
fclose(fileID);
% Keep only 'good' clusters
goodIndex = cellfun(@any,regexp(LogFile{2},'good'));
clus = LogFile{1}(goodIndex);

fs    = 30e3; % sample rate
win = round([-0.001 0.002]*fs); % window to extract around spike time: -1 to 2 ms
wfWin = win(1):win(2); % samples around the spike times to load

clusData = struct; % initialize cluster data struct
for iclus = 1:numel(clus)
    fprintf('Computing waveform clus %d/%d \n',iclus,numel(clus))
    curClus = double(spkTimes(spkClus==clus(iclus))); % spike times for cluster 'iclus'
    % remove spikes that may cause errors at the edges
    curClus(curClus<win(2) | curClus>size(dataMat,2)-win(2)) = [];
    theseWF = zeros(numel(curClus), numChans, numel(wfWin),'int16'); % initialize spike matrix
    for ispk = 1:numel(curClus)
        theseWF(ispk,:,:) = dataMat(:,curClus(ispk)+wfWin) - repmat(dataMat(:,curClus(ispk)+wfWin(1)),1,numel(wfWin)); % grad snippets of data and subtract the pre-spike baseline
    end
    spkMean = squeeze(mean(theseWF,1)); % compute STA broadband signal across all channels
    rspk = range(spkMean,2); % compute range of average spikes
    chanID = find(rspk==unique(max(rspk))); % find the channel with the largest range
    realChan = chanMap(chanID); % map back to original channels
    
    % load data into clusData structure
    clusData(iclus).clusID = clus(iclus);
    clusData(iclus).spkMean = spkMean;
    clusData(iclus).chanID = chanID;
    clusData(iclus).realChan = realChan;
    clusData(iclus).spkTimes = curClus/fs;
end
save([fpath 'spikeWaveforms'],'clusData')
%    
% % Plot spike waveforms
% for iclus = 1:numel(clus)
%     spkwav = clusData(iclus).spkMean(clusData(iclus).chanID,:);
%     plot((1:91)/30e3,spkwav/abs(min(spkwav))); hold on
% end
% xlabel('Time (s)')
% ylabel('Spike amp. normalized to trough')
% title(fpath)
% 


