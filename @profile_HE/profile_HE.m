function a_prof = profile_HE(results, a_trace_HE, intermediate_data, filtered_traces, ...
                             id, props)

% profile_HE - Holds results and intermediate data from analysis of HE simulation.
%
% Usage:
% a_prof = profile_HE(results, intermediate_data, filtered_traces, id, props)
%
% Parameters:
%   results: Structure with results to be inserted into database.
%   a_trace_HE: Original trace_HE object where profile was generated from.
%   intermediate_data: Structure returned from primary_fitness.
%   filtered_traces: Low and high pass filtered traces in structure.
%   id: Identification string.
%   props: A structure with any optional properties.
%
% Returns a structure object with the following fields:
%   trace_HE, intermediate_data, filtered_traces.
%
% Description:
%   Encapsulates the data and provides functions to analyze and
% calculate fitness.
%
% Example:
% >> a_prof = getResults(a_trace_HE_obj);
%
% General methods of profile_HE objects:
%   profile_HE		- Construct a new profile_HE object.
%
% Additional methods:
%   See methods('profile_HE')
%
% See also: trace_HE/getResults
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2014/04/07

% Copyright (c) 2007-2014 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

if nargin == 0 % Called with no params
  a_prof = struct;
  a_prof.trace_HE = trace_HE;
  a_prof.intermediate_data = struct;
  a_prof.filtered_traces = struct;
  a_prof.id = '';
  a_prof.props = struct;
  a_prof = class(a_prof, 'profile_HE');
elseif isa(results, 'profile_HE') % copy constructor?
  a_prof = results;
else
  if ~ exist('props', 'var')
    props = struct;
  end

  a_prof = struct;
  a_prof.trace_HE = a_trace_HE;
  a_prof.intermediate_data = intermediate_data;
  a_prof.filtered_traces = filtered_traces;

  a_prof = class(a_prof, 'profile_HE', results_profile(results, id, props));
end


