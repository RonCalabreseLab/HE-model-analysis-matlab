function [] = CalculateFitness(somafilenamedir, fitfilenamedir, targetdatadir, ganglion)
% assumes data is organized peri first

if(ischar(ganglion))
    ganglion = int32(str2double(ganglion));
end

% if(ischar(nbursts))
%     nbursts = int32(str2double(nbursts));
% end
%fprintf(1, '\n\n\nsomadata: %s\nfitnessfile: %s\nGanglion: %d\nnumber of bursts: %d\n', somafilenamedir, fitfilenamedir, ganglion, nbursts);

% --------------------------------------
% load data
%somadata = dlmread(somafilenamedir, '');
somadata = load(somafilenamedir);
% load filter from base analysis directory
load('baseline_filter_coeff.mat'); 

% load target data (associated with input pattern - contains targets for ganglion 8 or 12)
load(fullfile(targetdatadir, 'targetdata.mat'));
% select data for appropriate ganglion
ganglionname = sprintf('Ganglion_%d', ganglion);
targetdata = fitdata.(ganglionname); % fitdata is a structure saved in the targetdata.mat file 
                                     %  Difference between names intentional, fitdata contains the
                                     %  target data for each ganglion.


% load phase reference, HN4_peri
load(fullfile(targetdatadir, 'HN4_peri_stats.mat'));

% % select data for livingdata (based on ganglion)
% inds = find(orWithin(livingheader, {sprintf('HE%d', ganglion)}));
% if isempty(inds)
%     error('No match found for selected ganglion')
% end
% 
% %fprintf(1, 'livingheader: %s \n',livingheader{inds});
% livingdata = struct('phase', livingstats.mean.phase(inds), 'duty', livingstats.mean.duty(inds));
% %fprintf(1, 'livingdata: %f \n',livingstats.mean.phase(inds));
% %fprintf(1, 'livingdata: %f \n',livingstats.mean.duty(inds));


% call primary_fitness with loaded data
[fitness, bOkModel, intermediatedata] = primary_fitness( somadata(:,1),  somadata(:,2:3), Num, firstlast, medianspike, targetdata);
fitness= abs(fitness);

% save fitness to fitfilenamedir
dlmwrite(fitfilenamedir, fitness, ' ');

intermediate_filenamedir = strcat(fitfilenamedir(1:end-3),'mat');
% if model was 'ok' - i.e. had identifiable spikes, bursts, etc., then save intermediate data to the
% same location as .fit, but with .mat extension
if bOkModel
    save(intermediate_filenamedir, 'intermediatedata');
end


end
