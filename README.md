There has been a lot of effort in the last few years to make spike sorting both unsupervised and computationally efficient. The main groups that have been working on this have been Kennth Harris' and Liam Paninski's groups (there are others too). I have decided to implement the Harris lab spike sorting pipeline, because of it's speed when using GPU computing.

Here is the GitHub page of 'kilosort' from the Harris lab: https://github.com/cortex-lab/KiloSort

I downloaded the code a while ago, so it might be worth checking in periodically to see if any major bugs pop up, or if they have moved on to a completely new pipeline (as they seem to do almost every year or two). 

I like this code for a number of reasons, but the main ones are that they have multiple preprocessing stages, such as common average rereferencing and spatial whitening that do a very nice job of suppressing the tACS artifact. 

One of the painful things about this code was the need to get the correct version of Visual Studio (2013) and CUDA (7.0.28). I just kept trying combinations until one of them worked. But this may be different for your machine, GPU, and version of Windows. I would recommend running this on the GPU, so either use Guoshi's PC in the main lab, or invest in a decent GPU for your machine. The makers of kilosort use the GTX1080 from Nvidia with windows (https://www.nvidia.com/en-us/geforce/products/10series/geforce-gtx-1080/)

Then I run the function 'is_prepareSpikeSort.m', with the animals ID specified at the top of the m-file. This code will read the broadband signals saved by the INTAN system and save them as a matrix in a binary file 'rawData.dat'. This is the format that kilosort is expecting. Binary files are generated for each probe, eg: 'A', 'B', 'C', etc. 

After this is complete, we can run the spike sorting function 'is_sortAllRecordings.m'. Again, we will have to specify the animal ID at the top of this m-file. This code runs through the kilosort preprocessing procedure, detects spikes, and then performs clustering. There are a number of parameters that we have to define for each probe : this information is contained in the 'config_cortex_32.m', 'config_cortex_16.m', and 'config_thalamus_16.m' files. These files are pretty self-explanatory, but you should make sure that they fit with your data (for example, the number of clusters should be 2 to 4 times the number of channels). We also have to specify the spatial layout of our probes, since kilosort looks for spikes as transient spatiotemporal events (this is designed for more dense arrays....), this information is contained in the 'make_cortexChannelMap.m', 'make_thalamusChannelMap.m', and 'make_cortex_2x8_Map.m' files. 

After spike sorting is complete, the code will save results in a format that will be readable in the 'Phy' program (another contribution from the Harris lab). This program is for manual accepting/merging/rejection of clustering results. Here is the 'Phy' GitHub page: https://github.com/kwikteam/phy

Now we have to load the spike sorting results into Phy. You will first have to install Phy according to the instructions on the GutHub page. We then go to the Anaconda prompt and cd into the folder that contains out spike sorting results. When we are ready to look at the data, we activate Phy by typing 'activate phy':

After you have gone through the all clusters for this probe, you press 'Ctrl S' to save the cluster assignment, and then 'Ctrl Q' to quit. Then move on to the next probe or recording. 

After you have gone through all recordings using Phy, it is then time to go back to the raw data and compute the spike waveforms. This seems a bit silly, since we have already done spike sorting based on the waveforms.... but kilosort does not actually give you the waveforms as an output (or even the channel where spikes were detected). So I have written extra code that uses the spike timestamps of each cluster to go through and compute the spike triggered average broadband signal on each electrode, and then detect the channel that has the largest range. 

To compute the waveforms, just run the function 'is_allWavs.m' and specify the ID of the animals you would like to process. Note: this code also copies data onto the Z-Drive - I just do this so I can access it on the other PC's that I use. When this is finished, you will have an output structure 'spikeWaveforms.mat' 
