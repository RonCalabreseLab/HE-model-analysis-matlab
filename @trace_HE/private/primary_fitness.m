function [ fitness_raw, intermediate_data, freerunisistats, tracedata] = ...
    primary_fitness( time, soma_Vm, filterNum, HNfirstlast, HNmediansp, targets)

% primary_fitness - Calculate fitness for one Genesis file (one ganglion).
%
% Usage:
% [fitness_error, functional_model, intermediate_data, freerunisi, tracedata] =
%    primary_fitness( time, soma_Vm, filterNum, HNfirstlast, HNmediansp, targets)
%
% Parameters:
%   time: 1st column from Genesis file that contains the time vector.
%   soma_Vm: 2nd & 3rd columns from Genesis file that contain the soma Vm in [V].
%   filterNum: Slow wave filter coefficients loaded from baseline_filter_coeff.mat.
%   HNfirstlast: Time of first and last spikes of each burst [s],
%   		loaded from HN4_peri_stats.mat.
%   HNmediansp: Time of each median spike [s], also from HN4_peri_stats.mat.
%   targets: Structure with target values loaded from targetdata.mat.
%
% Returns:
%   fitness_error: Calculated fitness as difference from target for
%   	peri & sync all of the following:
%	(phase, freq, spike height [mV],  slow wave height [mV], duty cycle)
%   intermediate_data: Structure with the fitness information that
%   	contains all the data necessary to redo any calculations or
%   	analyses from the point of post-spike detection onward.
% 	Reference channel (HN4 peri) is appended to some structures to
% 	calculate phase off of that phase reference. 
%   freerunisistats: Check for initial spikes before inhibitory
%   	input (during first 15 seconds). If there are none, then
%   	this is a  'bad' model. Return mean and  standard deviation
%   	(STD) of inter-spike-intervals (ISIs).
%   tracedata: Low-pass and high-pass soma Vm traces [V].
%
% Description:
% First finds spikes and calculates measures and then fitness errors.
% Notes: livingdata and nbursts no longer passed. Targets will be
% passed from CalculateFitness.
%
% Example:
%
% See also:
%
% Author: Damon Lamb, 2013

% Modified by: Cengiz Gunay <cengique@users.sf.net> 2014/03/21
% 		Added doc. Returns more of the measured characteristics.
% 		Used to return fitness_error.

minspikes = 10;

%fitness_error = [];
intermediate_data = struct;

nsamples  = size(soma_Vm,1);
% expects 2 channels (peri and sync), as each soma Vm is saved to a separate file ...
nchannels = size(soma_Vm,2);

freerunisistats = struct('mean', -1, 'std', -1); 
%% filter data into low and high freq components
lpsoma_Vm = filtfilt(filterNum, 1, soma_Vm);
hpsoma_Vm = soma_Vm - lpsoma_Vm;
tracedata = struct('lpsoma', lpsoma_Vm, 'hpsoma', hpsoma_Vm);

%% detect peaks (spikes) in unfiltered data
% calculate spike detection parameters
% threshold = mean(fullsignal) + rms(highpass signal)
rmsval = zeros(1,nchannels);

for chanind = 1:nchannels
    % calculate rms (euclidean length divided by sqrt(n)) for each channel
    rmsval(chanind) = norm(hpsoma_Vm(:,chanind))/sqrt(nsamples);
    % CG: this looks wrong. Why sqrt(nsamples)?
end

% Threshold = (the max low pass value) + rms value or raw signal. 
% alternately, threshold = meanVm + rmsval;
threshold = max(lpsoma_Vm(8192:end-8192,:)) + rmsval;

spindices = cell(nchannels,1);
sptimes   = cell(nchannels,1);
failedspikedetect = false;
minisi_timesteps = floor(5e-3/(time(2)-time(1))); % 5ms minimum isi, converted to time steps
for chanind = 1:nchannels
    [~, spindices{chanind}]= findpeaks(soma_Vm(:,chanind), 'minpeakheight', threshold(chanind), 'minpeakdistance', minisi_timesteps);
    if length(spindices{chanind}) <= minspikes
        failedspikedetect = true;
        break
    end
    sptimes{chanind} = time(spindices{chanind});
end


if any(cellfun(@isempty, spindices)) || failedspikedetect
    % ZERO FITNESS
    % return failed fitness values
   
    fprintf(1,'Failed to detect spikes : null fitness\n');
    fitness_error = 999*ones(nchannels*5,1); % return a large error
    fitness_raw = repmat(NaN, nchannels*7,1); % return NaN
    return;
end
%% Check for initial spikes before inhibitory input (during first 15 seconds). 
%   If there are none, then this is a 'bad' model.

% n spikes between the times of time 5 and 15:
meanisi = zeros(nchannels, 1);
stdisi = zeros(nchannels, 1);
for chanind = 1:nchannels
    freerunsptimes = sptimes{chanind}((sptimes{chanind}>5) & (sptimes{chanind}<15));
    if ~isempty(freerunsptimes)
        freerunisi = diff(freerunsptimes);
        meanisi(chanind)= mean(freerunisi);
        stdisi(chanind)= std(freerunisi);
    end
end
 freerunisistats = struct('mean', mean(meanisi), 'std', mean(stdisi));
%% detect bursts

firstlast = cell(nchannels+1,1);    % extra entry for phase reference channel
medianspike = cell(nchannels+1, 1); % extra entry for phase reference channel
burstspikes = cell(nchannels, 1);
burstspinds = cell(nchannels, 1);
burstSFz    = cell(nchannels, 1);
spikeheight = cell(nchannels, 1);
burstmintrough = cell(nchannels, 1);
burstmedplateau= cell(nchannels, 1);

%min_spburst = 5; %Replaced with dynamic number of spikes per burst based on the estimated average number of spikes per burst

for chanind = 1:nchannels
    % calculate an average number of spikes per burst
    nvalidspikes = length(sptimes{chanind}((sptimes{chanind} >= targets.StartTime) & (sptimes{chanind} <= targets.EndTime)));
    avgSPB = nvalidspikes/targets.n_bursts;
    % use either 1/3 a burst or, at minimum, 5 spikes as the minimum number of spikes in a burst.
    min_spburst = max(5, floor(avgSPB/3));
    
    max_isi = 1;
    min_ibi = 0.5;
    
    % primitive adaptive algorithm for identifying bursts:
    % loops until a the correct number of bursts are detected.
    for ipower = 1:11 % 11=ceiling(-log(maxspikefreq * max_isi)/log(0.75)) with maxspikefreq = 20 (between burts, so this is extreme)
        firstlastind = ...
            findburst(sptimes{chanind}, max_isi, min_spburst, min_ibi, ...
                      targets.StartTime, targets.EndTime); 
        % changed findburst to a more effective algorithm  Oct 11
        % removed int32(*) DGL
        
        % CG commented out to clean up output:
        %fprintf(1, '%2d : (%3d ?= %2d)  maxisi:= %f\n',ipower, size(firstlastind, 1), targets.n_bursts , max_isi);
        if (size(firstlastind, 1) == targets.n_bursts); break; end
        max_isi = max_isi * .75;
        
%%         % debug -------------------------------------------------------------- 
%         subplot(2,1,chanind)
%         cla
%         plot(sptimes{chanind}, -.02, 'r.');
%         hold on;
%         if ~isempty(firstlastind)
%         
%             plot(sptimes{chanind}(firstlastind(:,1)), -.020, 'bo')
%             plot(sptimes{chanind}(firstlastind(:,2)), -.020, 'ko')
%         end
%         % --------------------------------------------------------------------
    end
    
    if (isempty(firstlastind) || size(firstlastind, 1) ~= targets.n_bursts)  
        % Detectable spikes, but ZERO FITNESS
        % TODO figure out / return failed fitness values
        fprintf(1,'failed to isolate bursts : null fitness\n');
        fitness_error = 999*ones(nchannels*5,1);
        fitness_raw = repmat(NaN, nchannels*7,1); % return NaN
        return % CG: fails to proceed to next channel
    else
        %% initialize arrays
        firstlast{chanind} = sptimes{chanind}(firstlastind);
        medianspike{chanind} = zeros(size(firstlast{chanind},1),1);
        burstspikes{chanind} = cell(size(firstlast{chanind},1), 1);
        burstspinds{chanind} = cell(size(firstlast{chanind},1), 1);
        burstSFz{chanind}    = cell(size(firstlast{chanind},1), 1);
        burstmintrough{chanind} =  zeros(length(medianspike{chanind})-1,1); % only inbetween bursts, hence -1 in 2nd dimension /```\_v__/````\
        burstmedplateau{chanind}=  zeros(length(medianspike{chanind}),1);  %/`^`\____/`^``\
        %% calculate burst (and trough) parameters
        for burstind = 1:length(medianspike{chanind})
            burstspikes{chanind}{burstind} = sptimes{chanind}(firstlastind(burstind,1):firstlastind(burstind,2))';
            burstspinds{chanind}{burstind} = spindices{chanind}(firstlastind(burstind,1):firstlastind(burstind,2))';%int32
            medianspike{chanind}(burstind) = median(burstspikes{chanind}{burstind})';
            burstSFz{chanind}{burstind} = 1./diff(burstspikes{chanind}{burstind})';
           if burstind >1
               troughind = spindices{chanind}([firstlastind(burstind-1,2),firstlastind(burstind,1)]);
               burstmintrough{chanind}(burstind-1) = min(lpsoma_Vm(troughind(1):troughind(2),1));
           end
           medspind =int32(median(burstspinds{chanind}{burstind})); % median spike of each burst, to define phase             
           burstmedplateau{chanind}(burstind) = lpsoma_Vm( medspind, chanind); % height of lowpass at median spike is plateau value. TODO consider averaging between nearest two spikes to median
           if burstind > 1
               tmpind = spindices{chanind}([firstlastind(burstind-1,2),firstlastind(burstind,1)]);
               burstmintrough{chanind}(burstind-1) = min(lpsoma_Vm(tmpind(1):tmpind(2),chanind));
           end
        end
        spikeheight{chanind} = hpsoma_Vm([burstspinds{chanind}{:}],chanind);
    end
end
% Trim HNfirstlast and HNmediansp to start/end times
HN4validinds = find(HNmediansp{1}>=targets.StartTime & HNmediansp{1}<=targets.EndTime);
HNfirstlast{1} = HNfirstlast{1}(HN4validinds,:);
HNmediansp{1} = HNmediansp{1}(HN4validinds,:);

% Append reference channel (HN4 peri) (to calculate phase off of that phase reference)
firstlast{nchannels +1} = HNfirstlast{1};
medianspike{nchannels +1} = HNmediansp{1};

% work in progress - make primary fitness more robust.-------------------------
% % % If HE peri bursts first, that burst must be dropped
% % if firstlast
% % 
% %  %fprintf(1,'failed to isolate bursts : null fitness\n');
% % 
% %  % number of bursts across phases must be equal
% % 
% %  %fprintf(1,'failed to isolate bursts : null fitness\n');
% -----------------------------------------------------------------------------
 % Calculate phases
[phasedata, phaseintermediate] = phasestats(firstlast, medianspike, nchannels+1);

%% calculate SFz stats
meanSFz = zeros(nchannels,1);
stdSFz = zeros(nchannels,1);
slowwave  = zeros(nchannels,1);
meanspkheight = zeros(nchannels,1);
for chanind = 1:nchannels
    meanSFz(chanind) = mean(cell2mat(burstSFz{chanind}));
    stdSFz(chanind)  = std(cell2mat(burstSFz{chanind}));
    slowwave(chanind) = mean(burstmedplateau{chanind}) - mean(burstmintrough{chanind});
    meanspkheight(chanind) = mean(spikeheight{chanind});
end

% channel 1 is peri, channel 2 is sync    
% Compare with targets (note, mV values scaled for comparison for slow wave and spike height)
fitness_target = [
    targets.Peristaltic.Phase
    targets.Peristaltic.Spike_Frequency
    targets.Spike_Height_mV
    targets.Slow_Wave_Height_mV
    targets.Peristaltic.Duty
    
    targets.Synchronous.Phase
    targets.Synchronous.Spike_Frequency
    targets.Spike_Height_mV
    targets.Slow_Wave_Height_mV
    targets.Synchronous.Duty];

fitness_error = [
    phasedata.mean.phase(1)- targets.Peristaltic.Phase
    meanSFz(1)- targets.Peristaltic.Spike_Frequency
    1e3*meanspkheight(1)-targets.Spike_Height_mV
    1e3*slowwave(1)-targets.Slow_Wave_Height_mV
    phasedata.mean.duty(1)- targets.Peristaltic.Duty
    
    phasedata.mean.phase(2)- targets.Synchronous.Phase
    meanSFz(2)- targets.Synchronous.Spike_Frequency
    1e3*meanspkheight(2)-targets.Spike_Height_mV
    1e3*slowwave(2)-targets.Slow_Wave_Height_mV
    phasedata.mean.duty(2)- targets.Synchronous.Duty];

fitness_raw = [
    phasedata.mean.first(1)
    phasedata.mean.phase(1)
    phasedata.mean.last(1)
    meanSFz(1)
    1e3*meanspkheight(1)
    1e3*slowwave(1)
    phasedata.mean.duty(1)
    phasedata.mean.first(2)
    phasedata.mean.phase(2)
    phasedata.mean.last(2)
    meanSFz(2)
    1e3*meanspkheight(2)
    1e3*slowwave(2)
    phasedata.mean.duty(2)];


% Intermediate_data contains all the data necessary to redo any calculations or analyses from the
% point of post-spike detection onward.
intermediate_data = ...
    struct('fitness_error', fitness_error, 'fitness_target', fitness_target, ...           
           'phasedata', {phasedata}, 'phasedata_intermediate', {phaseintermediate},...
           'spiketimes', {sptimes}, 'firstlastraw', {firstlast}, ...
           'firstlastinds', {firstlastind}, 'medianspikeraw', {medianspike}, ...
           'targets', targets);


end
