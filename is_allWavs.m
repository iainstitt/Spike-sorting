% This code loops through all recordings and calls the funciton
% 'is_computeWaveforms.m' if spikes have been sorted and manually assigned.
% % I.S. 2017

sortProbes = {'A','B','C'}; % The probes we would like to sort from the INTAN recording system
animalNames = {'0139','0151','0153'};
% This part adds paths
addpath(genpath('C:\Users\FrohlichLab\Documents\KiloSort-master')) % path to kilosort folder
addpath(genpath('C:\Users\FrohlichLab\Documents\npy-matlab-master')) % path to npy-matlab scripts
pathToYourConfigFile = 'C:\Users\FrohlichLab\Dropbox (Frohlich Lab)\Codebase\CodeIain\KiloSort-master\iainCode'; % Path to my custom configuration files

for ianimal = 1:numel(animalNames)
    animalCode = animalNames{ianimal};
    pathDir = ['J:\' animalCode '\'];
    saveDir = 'Z:\Individual\Iain\ferretData\';
    files = dir([pathDir animalCode '_*']); % detect files to sort
    cl    = struct2cell(files);
    nm    = cl(1,:); clear name
    for n = 1:numel(nm); name{n} = nm{n}; end
    recNames = unique(name); % all recording names
    
    for irec = 1:numel(files)
        recName = files(irec).name(1:end-14);
        recPath = [pathDir files(irec).name '\'];
        display(['Processing rec: ' recName])
        
        if ~exist([saveDir recNames{irec}],'dir'); mkdir(saveDir,recNames{irec}); end
        savePath = [saveDir recNames{irec}  '\'];
        % make directories for all probes
        if ~exist([savePath 'A'],'dir');
            mkdir(savePath,'A');
            mkdir(savePath,'B');
            mkdir(savePath,'C');
            mkdir(savePath,'D');
        end
        
        for iprobe = 1:numel(sortProbes)
            fpath    = [recPath 'spikeSort\' sortProbes{iprobe} '\'];

            if ~exist([fpath 'spikeWaveforms.mat'],'file');
                if exist([fpath 'phy.log'],'file'); if exist([fpath 'cluster_groups.csv'],'file')
                        is_computeWaveforms(fpath)
                        fprintf('Copying file %s port %s... \n',recName,sortProbes{iprobe})
                        copyfile([fpath 'spikeWaveforms.mat'],[savePath sortProbes{iprobe} '\']); end
                else
                    fprintf('No file detected %s port %s... \n',recName,sortProbes{iprobe})
                end % Bail
                
            end
            
        end
    end
end