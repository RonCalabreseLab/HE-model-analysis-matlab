function [a_results_bundle a_ranked_db] = ...
      searchSetCModel(a_bundle, param_row_db, a_crit_db, sort_func, ...
                      sim_name, props)
% searchSetCModel - run the search algorithm for a model from set C
% props:
%   GAopts: Structure passed to search function (GODLIKE, etc). Inside
%   		it, the 'options' field specify extra options to GODLIKE.
%   inputRanges: Column vector of low and high values for inputs
%   		(default=[0 4]'). If only one column is supplied, it's
%   		used for all parameters.
%   fitmoProps: Passed to fitnessMultObj.
%   fitParams: Cell array of parameters to be varied (default={'/synS_mult/'}).

% TODO:
% - return a little report?

common

props = defaultValue('props', struct);

% For backwards compat
sim_name = defaultValue('sim_name', 'simhe-2synscales');

% - include model# on directory, initialize dir if needed
setC_id = param_row_db(1, 'setCId').data;

% check if batch number given
col_names = getColNames(param_row_db);
if any(ismember(col_names, 'batch'))
  batch_id = param_row_db(1, 'batch').data;
  batch_name = [ '-batch' num2str(batch_id) ];
else
  batch_name = '';
end

inputdir_name = ...
    [ 'input' input_names{param_row_db(1, 'inputdir').data} filesep ];

% check if the bundle already exists
bundle_name = ...
    [ inputdir_name 'bundle_asa_ga_2syns_setCId' num2str(setC_id) batch_name ...
      '.mat'];

found_saved = false;
if exist(bundle_name, 'file')
  disp(['Found an existing file "' bundle_name ...
        '". Loading it and returning.' ]);
  s = load(bundle_name);
  a_results_bundle = s.a_results_bundle;
  found_saved = true;
else

  a_bundle.dataset.path = ...
      [ inputdir_name 'data-' sim_name '-setCId' num2str(setC_id) ...
        batch_name ];

  % if the directory exists, just proceed to load the bundles
  if exist(a_bundle.dataset.path, 'dir')
    display([ 'Directory ' a_bundle.dataset.path ' already exists, ' ...
              'looking for bundles.']);
  else
    fit_props = struct;
    param_names = getParamNames(param_row_db);
    select_params = getFieldDefault(props, 'fitParams', {'/synS_mult/'});
    fit_props.selectParams = select_params;

    % set limits for input parameters
    range_cols = getFieldDefault(props, 'inputRanges', [0 4]');
    param_rows = tests2cols(param_row_db, select_params);
    if size(range_cols, 2) == 1
      range_cols = repmat(range_cols, 1, length(param_rows));
    end
    param_ranges = repmat(NaN, 2, dbsize(param_row_db, 2));
    param_ranges(:, param_rows) = range_cols;
    fit_props.paramRanges = param_ranges;

    fit_func = ...
        @(p, the_pf) ...
        fitnessMultObj(a_bundle, ...
                       a_crit_db, p, the_pf, ...
                       mergeStructs(getFieldDefault(props, 'fitmoProps', struct), ...
                                    struct('precision', 16, ...
                                           'quiet', 1)));
    
    % add 'quiet', 0 to props to see Genesis output
    a_f = param_func({'N/A', 'Metrics'}, ...
                     rows2Struct(param_row_db), [], fit_func, ...
                     ['simhe 2syns set C model ' num2str(setC_id) ' ASA/GA'], ...
                     fit_props);
    
    % parallelize at population level
    optim_props = ...
        struct('Coding', 'real', 'Display', 'on', ...
               'UseParallel', true, ...
               'NumObjectives', 18, ...
               'PopulationSize', 50, ... %50/15
               'TolFun', 1e-4, 'TolX', 1e-4, ...
               'MaxFunEvals', 5000); % 200/10
    ga_props = ...
        struct('options', optim_props); 
    
    ga_props.godlikeAlgos = {'GA'; 'ASA'};

    ga_props = ...
        mergeStructsRecursive(getFieldDefault(props, 'GAopts', struct), ga_props);
    
    f_asa_ga_2syns_modeln = ...
        optimizeGA(a_f, ga_props); 

    save([ inputdir_name 'f_asa_ga_2syns_setCId' num2str(setC_id) batch_name '.mat'], ...
         'f_asa_ga_2syns_modeln');
  end                                     % Exist dir

  % load results 
  a_results_bundle = ...
      collectBundles([a_bundle.dataset.path], struct('precision', 16)); 

end % found bundle

% rank it
a_ranked_db = ...
    sort_func(rankMatching(a_results_bundle.joined_db, a_crit_db));

displayRows(a_ranked_db(1:5, :))

% - save the bundle
if ~ found_saved
  save(bundle_name, ...
       'a_results_bundle');
end
