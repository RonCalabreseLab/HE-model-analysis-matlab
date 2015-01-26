function multobj_fitness = fitnessMultObj(a_bundle, a_crit_db, params_struct, ...
                                          a_pf, props)
  
  props = defaultValue('props', struct);

  g_file = getFieldDefault(props, 'gFile', 'simhe_ind_synscale.g');
  
  % create params db
  param_row_db = ...
      params_tests_db(length(fieldnames(params_struct)), ...
                      struct2DB(params_struct));
  
  % learn which are the changed params
  all_param_names = getParamNames(a_pf);
  changed_param_names = getParamNames(a_pf, struct('onlySelect', 1));
    
  % calculate unique trial number for this run
  trial_num = 0;
  multiplier = 1;
  mult_exp = getFieldDefault(props, 'multExp', 1e1);
  for param_num = 1:length(changed_param_names)
    param_name = changed_param_names{param_num};
    orig_param_num = find(strcmp(all_param_names, param_name));
    % multiply offset of current parameter from its lower range
    trial_num = trial_num + (params_struct.(param_name) ...
                             - a_pf.props.paramRanges(1, orig_param_num))* multiplier;
    multiplier = multiplier * mult_exp * ...
          diff(a_pf.props.paramRanges(:, orig_param_num));
  end

  % run one simulation and update param file and all bundle structures
  % [this is specific to HE model, cannot move to bundle]
  updated_allsyns_bundle = ...
      simNewParams(a_bundle, param_row_db, ...
                   mergeStructs(props, ...
                                struct('simFunc', ...
                                       @(row_db) runSimSingle(row_db, ...
                                                    g_file, props), ...
                                       'trial', trial_num)));
  % compare to crit
  ranked_db = delColumns(rankMatching(updated_allsyns_bundle.joined_db, ...
                                      a_crit_db), ...
                         {'RowIndex', 'Distance'});
  
  %displayRows(ranked_db)
  
  % return squared z-scores
  multobj_fitness = ranked_db.data .* ranked_db.data;