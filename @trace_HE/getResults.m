function [ results, intermediate_data ] = getResults(a_htr, props)

% getResults - Returns the raw fitness values.
%
% Usage:
% results = getResults(a_htr)
%
% Parameters:
%   a_htr: A trace_HE object.
%   props: A structure with any optional properties.
%     onlyTargets: If 1, return target values as result instead of measurements.
%
% Returns:
%   results: A structure that contain fitness names and values.
%
% Description:
%
% See also: trace
%
% $Id: getResults.m 1335 2012-04-19 18:04:32Z cengique $
%
% Author: 
%   Cengiz Gunay <cgunay@emory.edu>, 2014/03/24

% Copyright (c) 2007-2014 Cengiz Gunay <cgunay AT emory.edu>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

% TODO: something like this
% $$$ CalculateFitness('data/simhe_6inputs_somaVm_HE_12_trial_2.txt', ...
% $$$                  'analysis/simhe_6inputs_somaVm_HE_12_trial_2.txt', ...
% $$$                  '../../common/input-patterns/5_19B', 12)

props = defaultValue('props', struct);

% moving these from CalculateFitness
filter_coef = load('baseline_filter_coeff.mat'); 


input_dir = ...
    getFieldDefault(a_htr, 'inputDir', ...
                           '../../common/input-patterns');

% load target data (associated with input pattern - contains targets for ganglion 8 or 12)
targets = ...
    load(fullfile(input_dir, a_htr.inputname, 'targetdata.mat'));

% fitdata contains the target data for each ganglion.
% select data for appropriate ganglion
targetdata = targets.fitdata.(sprintf('Ganglion_%d', a_htr.gangno)); 

% load phase reference, HN4_peri
HN4_peri_ref = ...
    load(fullfile(input_dir, a_htr.inputname, ...
                  'HN4_peri_stats.mat'));

time = (0:size(a_htr.peri_tr.data, 1))'*a_htr.peri_tr.dt;

% call primary_fitness with loaded data
[ fitness_raw, intermediate_data, freerunisistats, tracedata] = ...
    primary_fitness( time,  [a_htr.peri_tr.data, a_htr.sync_tr.data], ...
                     filter_coef.Num, HN4_peri_ref.firstlast, ...
                     HN4_peri_ref.medianspike, targetdata);

if isfield(props, 'onlyTargets')
  % targets only for median phase
  result_names = {'phase_median', 'freq_Hz', 'spike_height_mV', ...
                  'slow_wave_height_mV', 'duty_cycle'};
  results_vals = intermediate_data.fitness_target;
else
  result_names = {'phase_first', 'phase_median', 'phase_last', 'freq_Hz', ...
                  'spike_height_mV',  'slow_wave_height_mV', 'duty_cycle'};
  results_vals = fitness_raw;
end

% replicate names for peri and sync
peri_names = cellfun(@(x)([ 'peri_' x ]), result_names, ...
                     'UniformOutput', false);
sync_names = cellfun(@(x)([ 'sync_' x ]), result_names, ...
                     'UniformOutput', false);

% DON'T add ganglion number: read as separate files and parameterized
%all_names = ...
%    cellfun(@(x)([ 'HE' num2str(a_htr.gangno) '_' x ]), [peri_names, sync_names], ...
%                    'UniformOutput', false);
all_names = [peri_names, sync_names];

% return results_profile subclass object

% Warning: returning raw fitness, so targets aren't subtracted -
% although they are used before that.
results = profile_HE(cell2struct(num2cell(results_vals), ...
                                 all_names), a_htr, intermediate_data, ...
                     tracedata, a_htr.peri_tr.id, props);

