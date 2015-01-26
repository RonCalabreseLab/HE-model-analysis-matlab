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
%     options: Passed to optimization algorithm.
%     initPop: Initial population as a matrix to seed into GA search
%     		(default=curent selected params in a_pf).
%     minGoal: Use gradient descent minimization to reach below this goal
%     		using fgoalattain.
%     minWeight: Passed to fgoalattain.
%     godlikeAlgos: Instead of Matlab optimizers, use the GODLIKE
%     		optimizer with these passed as the 'which_ones'*/
%     		argument (Default: {'GA'}).
%     godlikePopsize: Passed to GODLIKE as 'popsize' (Default: 50*input
%     		dimensions).  
%
% Returns:
%   a_pf: param_func object with optimized parameters.
%
% Description:
%   Default is using the Matlab 'Global Optimization Toolbox'
% multi-objective evolutionary algorithm (gamultiobj), but a global
% multi-objective minimization with slack (fgoalattain) from the regular
% 'Optimization Toolbox' can also be selected by setting props.minGoal. One
% can switch to using an external optimizer, GODLIKE
% (http://www.mathworks.com/matlabcentral/fileexchange/24838-godlike-a-robust-single---multi-objective-optimizer),
% if the 'godlikeAlgos' option is specified.
%
% Example:
% >> a_f = param_func({'N/A', 'Metrics'}, init_pars_struct, [], ...
%                     @(p, the_pf) fitness_func(p, the_pf), ...
%                     'my simulation');
% >> gamultoptim_props = struct('UseParallel', true, 'PopulationSize', 512, ...
%                               'Generations', 30);
% >> a_f_opt = optimizeGA(a_f, struct('gaoptimset', gamultoptim_props));
%
% See also: param_func, gamultiobj, gaoptimset, fgoalattain, GODLIKE
%
% $Id: optimize.m 599 2012-03-14 15:04:00Z cengiz $
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2014/10/01

% Copyright (c) 2014 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

% TODO: this should go into param_fitter (and Pandora), but param_func is
% inherently designed for taking an input voltage and inegrating over
% time. Make a generic param_func base class, and make the current one a
% param_vfunc. 

if ~ exist('props', 'var')
  props = struct;
end

if isfield(props, 'gaoptimset')
  error('Prop "gaoptimset" replaced with "options"')
end

start_time = clock;

props = mergeStructs(props, get(a_pf, 'props'));

error_func = ...
    @(p) f(setParams(a_pf, p, struct('onlySelect', 1)), a_pf);

par = getParams(a_pf, struct('onlySelect', 1)); % initial params

param_ranges = getParamRanges(a_pf, struct('onlySelect', 1));

init_pop = getFieldDefault(props, 'initPop', par);

if isfield(props, 'godlikeAlgos')
  % convert options to input required for set_options
  options = ...
      mergeStructs(getFieldDefault(props, 'options', struct), ...
                   struct);
  cell_opts = [fieldnames(options), struct2cell(options)];
  cell_opts_flat = reshape(cell_opts', 1, prod(size(cell_opts)));
  [pars, fval, population, score, exitflag, output] = ...
      GODLIKE(error_func, getFieldDefault(props, 'godlikePopsize', length(par)*50), ...
              param_ranges(1, :), param_ranges(2, :), ...
              getFieldDefault(props, 'godlikeAlgos', {'GA'}), ...
              set_options(cell_opts_flat{:}));

  % save fit stats in a_pf
  a_pf = setProp(a_pf, 'population', population, 'score', score, 'pars', pars);    
else
  optimset_props = ...
      mergeStructs(struct('TolFun', 1e-6, 'Display', 'iter', ...
                          'InitialPopulation', init_pop), gaoptimset);
  
  optimset_props = ...
      mergeStructs(getFieldDefault(props, 'options', struct), ...
                   optimset_props);
  
  if ~ isfield(props, 'minGoal')
    [pars, fval, exitflag, output, population, score] = ...
        gamultiobj(error_func, length(par), ...
                   [], [], [], [], ...
                   param_ranges(1, :), param_ranges(2, :), ...
                   optimset_props);
    % save fit stats in a_pf
    a_pf = setProp(a_pf, 'population', population, 'score', score, 'pars', pars);
  else
    [pars, fval, attainfactor, exitflag, output, lambda] = ...
        fgoalattain(error_func, par, props.minGoal, ...
                    getFieldDefault(props, 'minWeight', abs(props.minGoal)), ...
                    [], [], [], [], ...
                    param_ranges(1, :), param_ranges(2, :), [], ...
                    optimset_props);
    disp('Attainfactor:')
    attainfactor
    a_pf = setProp(a_pf, 'lambda', lambda, 'pars', pars);
  end

end % godlike else

disp([ 'Exit flag: ' num2str(exitflag) ])
  
disp('Output:')
output
  
disp('Fval:')
fval

% set back fitted parameters
a_pf = setParams(a_pf, pars(1, :), struct('onlySelect', 1));

% display parameters
displayParams(a_pf, struct('onlySelect', 1))

elapsed_seconds = etime(clock, start_time);
disp(['Fitting complete in ' ...
      sprintf('%dh %dm %.2fs', round(elapsed_seconds / (60*60)), ...
              round(mod(elapsed_seconds, 60*60) / 60), ...
              mod(elapsed_seconds, 60))])

end

