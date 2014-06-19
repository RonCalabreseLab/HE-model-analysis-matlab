function a_plot = plot_abstract(a_prof, title_str, props)

% plot_abstract - Plots HE traces in a horizontal stack annotated with measurements.
%
% Usage: 
% a_plot = plot_abstract(a_prof, title_str, props)
%
% Parameters:
%   a_prof: A trace_HE object.
%   title_str: (Optional) String to append to plot title.
%   props: A structure with any optional properties.
%     plotHNs: If given, plot firing patterns of HN neurons.
%     (passed to trace/plotData and plot_stack)
%
% Returns:
%   a_plot: A plot_abstract object that can be visualized.
%
% Description:
%
% See also: trace, trace/plot, plot_abstract
%
% $Id: plot_abstract.m 1335 2012-04-19 18:04:32Z cengique $
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2014/03/19

% Copyright (c) 2007-2014 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

if ~ exist('props', 'var')
  props = struct;
end

prof_props = get(a_prof, 'props');

% use trace_HE/plot_abstact and parse its contents
a_plot = plot_abstract(get(a_prof, 'trace_HE'), title_str, props);

% do the same additions separately for peri and sync traces
a_plot.plots{1} = annotate_plot(1, 'peri');
a_plot.plots{2} = annotate_plot(2, 'sync');

  function a_trace_plot = annotate_plot(trace_index, peri_sync)
  
  % superpose with annotations
  y_level = -23; % mV - line to display burst annotation marks

  hn_plots = {};
  if isfield(props, 'plotHNs')
    
    input_dir = ...
        getFieldDefault(a_prof.trace_HE, 'inputDir', ...
                                      '../../common/input-patterns');
    
    % plot HN activity at this y-level
    hn_y_level = -18;
    hn_y_sep = 4;
  
    % neurons
    hn_nums = [7 6 4 3];
    hn_colors = ...
        [ 0 153 255;
          255 0 153;
          45 157 34;
          141 86 170 ] ./ 255;
    he_num = a_prof.trace_HE.gangno;
  
    % parse Genesis synaptic weights file
    weights_file = fileread(fullfile(input_dir, a_prof.trace_HE.inputname, 'synaptic_wts_new.g'));

    % TODO: read weights during profile generation and save in props
    for hn_ind = 1:length(hn_nums)
      parse_str = ...
          regexp(weights_file, ...
                 ['HE' num2str(he_num) '_peri[\w/]+S' num2str(hn_nums(hn_ind)) ...
                  ' gmax \{synwt\d+ \* ([\d\.e+-]+)\}'], 'tokens');
      %disp([ 'HE' num2str(he_num) ' from HN' num2str(hn_nums(hn_ind)) ...
      %       '(' peri_sync '): ' parse_str{1}{1} ]);
      hn_weight = eval(parse_str{1}{1});
      mult_name = ...
          regexp(fieldnames(prof_props.params), ...
                 ['synS_mult_HE' num2str(he_num) '_HN' ...
                  num2str(hn_nums(hn_ind)) '.*' ], 'match');
      mult_name = [ mult_name{:} ];     % hack
      mult_name = mult_name{1};
      if isfield(prof_props.params, 'synS_mult')
        % general multiplier for all HNs
        hn_weight = hn_weight * prof_props.params.synS_mult;
      elseif ~isempty(mult_name)
        % per HN multiplier exists
        hn_weight = hn_weight * prof_props.params.(mult_name);
      end
  
      % read spike times file
      spikes = load(fullfile(input_dir, a_prof.trace_HE.inputname, ...
                             ['HN' num2str(hn_nums(hn_ind)) '_' peri_sync ]));

      % delay per ganglion is 20ms * (#HE - #HN)
      delay = 0.02 * (he_num - hn_nums(hn_ind));
      
      % TODO: default modulation = 0.1
      
      % plot spikes as points scaled by synaptic weight
      hn_plots = [ hn_plots ...
                   {plot_abstract({spikes - delay, ...
                          repmat(hn_y_level + (hn_ind - 1) * hn_y_sep, ...
                                 length(spikes), 1), ...
                          'o', 'MarkerSize', 0.5 + hn_weight * 0.5e9, ...
                          'MarkerEdgeColor', 'none', ...
                          'MarkerFaceColor', hn_colors(hn_ind, :)}, ...
                                  {}, '', {}, 'plot')}];
    end
  
  end

  % annotate burst first, median, and last spikes
  a_trace_plot = ...
      plot_superpose({...
        set(a_plot.plots{trace_index}, 'axis_labels', ...
                          {'time [s]', ['HE ' num2str(a_prof.trace_HE.gangno) ' [mV]' ]}), ...
        plot_abstract({a_prof.intermediate_data.medianspikeraw{trace_index}, ...
                      repmat(y_level, length(a_prof.intermediate_data.medianspikeraw{trace_index}), 1), ...
                      'dk', 'MarkerFaceColor', 'k'}, ...
                      {}, '', {}, 'plot'), ...% median phase
        plot_abstract({a_prof.intermediate_data.firstlastraw{trace_index}(:, 1), ...
                      repmat(y_level, size(a_prof.intermediate_data.firstlastraw{trace_index}, 1), 1), ...
                      '<k', 'MarkerFaceColor', 'k'}, ...
                      {}, '', {}, 'plot'), ...% first spike
        plot_abstract({a_prof.intermediate_data.firstlastraw{trace_index}(:, 2), ...
                      repmat(y_level, size(a_prof.intermediate_data.firstlastraw{trace_index}, 1), 1), ...
                      '>k', 'MarkerFaceColor', 'k'}, ...
                      {}, '', {}, 'plot'),... % last spike
        hn_plots{:}}, {}, '', struct('noCombine', 1));
  end
end