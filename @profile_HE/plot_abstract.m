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
% 	(passed to trace/plotData and plot_stack)
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

% use trace_HE/plot_abstact and parse its contents
a_plot = plot_abstract(get(a_prof, 'trace_HE'), title_str, props);

peri_plot = a_plot.plots{1};
sync_plot = a_plot.plots{2};

% superpose with annotations
y_level = -23; % mV - line to display marks

annotate_plot = @(trace_index)...
    plot_superpose({...
      set(a_plot.plots{trace_index}, 'axis_labels', ...
                        {'time [s]', ['HE ' num2str(a_prof.trace_HE.gangno) ' [mV]' ]}), ...
      plot_abstract({a_prof.intermediate_data.medianspikeraw{trace_index}, ...
                    repmat(y_level, length(a_prof.intermediate_data.medianspikeraw{trace_index}), 1), ...
                    'dr'}, ...
                    {}, '', {}, 'plot'), ...% median phase
      plot_abstract({a_prof.intermediate_data.firstlastraw{trace_index}(:, 1), ...
                    repmat(y_level, size(a_prof.intermediate_data.firstlastraw{trace_index}, 1), 1), ...
                    '<r'}, ...
                    {}, '', {}, 'plot'), ...% first spike
      plot_abstract({a_prof.intermediate_data.firstlastraw{trace_index}(:, 2), ...
                    repmat(y_level, size(a_prof.intermediate_data.firstlastraw{trace_index}, 1), 1), ...
                    '>r'}, ...
                    {}, '', {}, 'plot')... % last spike
                   });
% peri
a_plot.plots{1} = annotate_plot(1);

% sync
a_plot.plots{2} = annotate_plot(2);
