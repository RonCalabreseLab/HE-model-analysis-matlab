function hn_weights = getHNweights(a_htr, hn_nums, props)

% getHNweights - Get HN weights from Genesis file and scale by multipliers.
%
% Usage: 
% hn_weights = getHNweights(a_htr, hn_nums, props)
%
% Parameters:
%   a_htr: A trace_HE object.
%   hn_nums: Vector of HN numbers whose weights will be extracted.
%   props: A structure with any optional properties.
%
% Returns:
%   hn_weights: Vector of weights corresponding to requested hn_nums.
%
% Description:
%
% See also: profile_HE/plot_abstact
%
% $Id: plot_abstract.m 1335 2012-04-19 18:04:32Z cengique $
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2014/11/07

% Copyright (c) 2014 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

props = defaultValue('props', struct);

prof_props = get(a_htr, 'props');

input_dir = ...
    getFieldDefault(prof_props, 'inputDir', ...
                                '../../common/input-patterns');
    
he_num = a_htr.gangno;
  
% parse Genesis synaptic weights file
weights_file = fileread(fullfile(input_dir, a_htr.inputname, 'synaptic_wts_new.g'));

% first, get HE scaling factor
% Lookes like this: "float synwt8 = .9//numerically balanced:1.82"
parse_str = ...
    regexp(weights_file, ...
           ['float synwt' num2str(he_num) '\s*=\s*([\d\.e+-]+)'], 'tokens');
he_weight = eval(parse_str{1}{1});

% TODO: read weights during profile generation and save in props?
hn_weights = repmat(NaN, 1, length(hn_nums));
for hn_ind = 1:length(hn_nums)
  parse_str = ...
      regexp(weights_file, ...
             ['HE' num2str(he_num) '_peri[\w/]+S' num2str(hn_nums(hn_ind)) ...
              ' gmax \{synwt\d+ \* ([\d\.e+-]+)\}'], 'tokens');
  %disp([ 'HE' num2str(he_num) ' from HN' num2str(hn_nums(hn_ind)) ...
  %       '(' peri_sync '): ' parse_str{1}{1} ]);
  hn_weight = eval(parse_str{1}{1}) * he_weight;
  
  hn_weights(hn_ind) = hn_weight;
end
