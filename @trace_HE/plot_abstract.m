function a_plot = plot_abstract(t, title_str, props)

% plot_abstract - Plots HE traces in a horizontal stack.
%
% Usage: 
% a_plot = plot_abstract(t, title_str, props)
%
% Parameters:
%   t: A trace_HE object.
%   title_str: (Optional) String to append to plot title.
%   props: A structure with any optional properties.
%	  (passed to trace/plotData and plot_stack)
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

trace_props = ...
    mergeStructs(props, struct('timeScale', 's', 'quiet', 1));

title_str = defaultValue('title_str', t.id);

a_plot = plot_stack({plotData(t.peri_tr, '', trace_props), ...
                    plotData(t.sync_tr, '', trace_props)}, [], 'x', ...
                    title_str, ...
                    mergeStructs(props, ...
                                 struct('yLabelsPos', 'left', ...
                                        'noTitle', 1)));
