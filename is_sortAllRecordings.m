useGPU = 1; % Flag to use GPU or not
sortProbes = {'A','B','C'}; % The probes we would like to sort from the INTAN recording system
% This part adds paths
addpath(genpath('C:\Users\FrohlichLab\Documents\KiloSort-master')) % path to kilosort folder
addpath(genpath('C:\Users\FrohlichLab\Documents\npy-matlab-master')) % path to npy-matlab scripts
pathToYourConfigFile = 'C:\Users\FrohlichLab\Dropbox (Frohlich Lab)\Codebase\CodeIain\KiloSort-master\iainCode'; 

animalCodes = {'0155'}; % Enter the code of all of the animals you would like to sort. Eg: {'0114','0116','0124','0125'};

% Loop through animals 
for ianimal = 1:numel(animalCodes)
    animalCode = animalCodes{ianimal};
    pathDir = ['J:\' animalCode '\']; % Path to all files containing binary files
    files = dir([pathDir animalCode '_*']); % detect files to sort
    % Detect recording names
    cl    = struct2cell(files);
    nm    = cl(1,:);
    for n = 1:numel(nm); name{n} = nm{n}; end
    recNames = unique(name); % all recording names
    
    % Loop through all recordings per animal
    for irec = 1:numel(files)
        recName = files(irec).name(1:end-14); % We get the recording name without the date information
        recPath = [pathDir files(irec).name '\'];
        display(['Processing rec: ' recName])
        
        % Loop through probes from INTAN system
        for iprobe = 1:numel(sortProbes)
            fpath    = [recPath 'spikeSort\' sortProbes{iprobe} '\']; % Path to binary data file
            
            % Run the configuration file, it builds the structure of options (ops)
            switch sortProbes{iprobe}
                case 'A' % PPC probe 
                    run(fullfile(pathToYourConfigFile, 'config_cortex_32.m')); % 'config_cortex_32.m' corresponds to the 32 channel Innovative Neurophysiology probe
                    make_cortexChannelMap(fpath);
                case 'B' % Visual cortex
%                     run(fullfile(pathToYourConfigFile,'config_cortex_32.m')); We also sometimes use the same 32 channel probe for visual cortex. 
%                     make_cortexChannelMap(fpath);
                    run(fullfile(pathToYourConfigFile, 'config_cortex_16.m')); % 'config_cortex_16.m' corresponds to the 16 channel (2x8) Innovative Neurophysiology probe
                    make_cortex_2x8_Map(fpath);
                case 'C'
                    run(fullfile(pathToYourConfigFile, 'config_thalamus_16.m')); % 'config_thalamus_16.m' corresponds to the 16 channel Microprobes probe. 
                    make_thalamusChannelMap(fpath);
            end
            
            % Skip if we have already sorted this probe from this recording
            if exist([fpath 'params.py'],'file');
                fprintf('Skipping %s port %s... already sorted \n',recName,sortProbes{iprobe})
                continue; end % Bail if already computed
            
            rawFile = dir([fpath 'rawData.dat']);
            if rawFile.bytes < 100e6; continue; end % skip if file is too small (we run into errors with small files)
            
            % Kilosort preprocessing
            [rez, DATA, uproj] = is_preprocessData(ops); % preprocess data and extract spikes for initialization
            rez                = fitTemplates(rez, DATA, uproj);  % fit templates iteratively
            rez                = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)
            
            % save python results file for Phy
            rezToPhy(rez, fpath);
            close all
            
            % delete the whitened data since it takes up so much space
            fileToDelete = [fpath 'temp_wh.dat'];
            delete(fileToDelete)
        end
    end
end