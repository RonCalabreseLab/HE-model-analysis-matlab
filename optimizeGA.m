function a_pf = optimizeGA(a_pf, props)

% optimizeGA - Optimize model parameters to fit criteria in multi-objective fashion.
%
% Usage:
%   a_pf = optimizeGA(a_pf, props)
%
% Parameters:
%   a_pf: A param_func object, where the x argument is replaced with a
%   		pointer to the object itself (e.g., f(p, a_pf)).
%   props: A structure with any optional properties.
%     gaoptimset: Optimization toolbox parameters supercedes defaults.
%     hybridmethod: Use local optimizer at points selected by GA
%     		optimizer: 'lsqcurvefit' (default),
%     		'ktrlink' (requires external libraries), 'fmincon'
%     		(requires Optimization Toolbox).
%
% Returns:
%   a_pf: param_func object with optimized parameters.
%
% Description:
%
% Example:
%
% See also: param_func, gamultiobj, gaoptimset
%
% $Id: optimize.m 599 2012-03-14 15:04:00Z cengiz $
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2014/10/01

% Copyright (c) 2014 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

% TODO: this should go into Pandora

if ~ exist('props', 'var')
  props = struct;
end

props = mergeStructs(props, get(a_pf, 'props'));

error_func = ...
    @(p) f(setParams(a_pf, p, struct('onlySelect', 1)), a_pf);

par = getParams(a_pf, struct('onlySelect', 1)); % initial params

param_ranges = getParamRanges(a_pf, struct('onlySelect', 1));

optimset_props = ...
    mergeStructs(struct('TolFun', 1e-6, 'Display', 'iter', ...
                        'InitialPopulation', par), gaoptimset);

if isfield(props, 'gaoptimset')
  optimset_props = mergeStructs(props.gaoptimset, optimset_props);
end

tic;
[par, fval, exitflag, output, population, score] = ...
    gamultiobj(error_func, length(par), ...
               [], [], [], [], ...
               param_ranges(1, :), param_ranges(2, :), ...
               optimset_props);
toc

disp([ 'Exit flag: ' num2str(exitflag) ])

disp('Output:')
output

disp('Fval:')
fval

% save fit stats in a_pf
a_pf = setProp(a_pf, 'population', population, 'score', score);

% set back fitted parameters
a_pf = setParams(a_pf, par, struct('onlySelect', 1));

end

