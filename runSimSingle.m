function files = runSimSingle(row_db, genesis_script, props)
  
% TODO:
% - need docs
% - add to Pandora
  
  props = defaultValue('props', struct);
  
  cmd_suffix = ' > /dev/null 2>&1';
  if isfield(props, 'quiet') && props.quiet == 0
    cmd_suffix = '';
  end

  precision = getFieldDefault(props, 'precision', 6);
  
  % space-separated param names
  param_names = ...
      cellfun(@(x)[x ' '], getParamNames(row_db), 'UniformOutput', false);
  
  % run it
  cmdline = ...
      ['GENESIS="lgenesis" GENESIS_PAR_ROW="' ...
       num2str(row_db(1, 1:row_db.num_params).data, precision) ...
       '" GENESIS_PAR_NAMES="' param_names{:}...
       '" sim_genesis.sh ' genesis_script cmd_suffix ];
  if isfield(props, 'quiet') && props.quiet == 0
      disp(['Executing: ' cmdline]);
  end
  [status,result] = system(cmdline);

  if isfield(props, 'quiet') && props.quiet == 0
      disp(['Output: ' result])
  end

  if status ~= 0 
      error('Failed running command.');
  end