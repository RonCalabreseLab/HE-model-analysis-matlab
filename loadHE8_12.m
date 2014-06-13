function [a_prof] = loadHE8_12(a_fs, index, params_row, props)
    
  % Get param names
  param_names = paramNames(a_fs, index);

  % add all the params to props
  props = ...
      mergeStructs(defaultValue('props', struct), ...
                   struct('params', ...
                          cell2struct(num2cell(params_row)', param_names', 1)));
    
  % find parameter for input 
  input_idx = strmatch('inputdir', param_names);

  if isempty(input_idx)
    disp('Parameter names:');
    param_names
    error(['Cannot find parameter for "input" in the parameter name ' ...
           'list above.']);
  end

  % find parameter for ganglion num
  ganglion_idx = strmatch('HE', param_names);

  if isempty(ganglion_idx)
    disp('Parameter names:');
    param_names
    error(['Cannot find parameter for "HE" in the parameter name ' ...
           'list above.']);
  end

  % set input from list
  input_names = ...
      {'5_19A', '5_19B', '5_20B', '5_22B', '5_26A', '5_27B'};
  
  % load traceHE object
  a_htr = trace_HE(fullfile(a_fs.path, getItem(a_fs, index)), params_row(ganglion_idx), ...
                   input_names{params_row(input_idx)}, a_fs.dt, a_fs.dy, 'soma Vm');

  % return results profile
  a_prof = ...
      getResults(a_htr, props);
  
