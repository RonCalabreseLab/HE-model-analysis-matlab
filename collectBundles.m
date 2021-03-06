function a_bundle = collectBundles(dirname, props)
% Collect all bundles in directory and merge into one. When numbering the
% item indices, count the oldest files first as an indication of earlier
% parameter search iterations.

common

props = defaultValue('props', struct);

% BUG: all external directory listing functions in Matlab R2014a/b are
% buggy. There is a buffer clearing issue that either truncates entries
% or start with junk from last run. Repeating this operation 5-10 times
% (!) eventually works.

% $$$ bundle_files = ...
% $$$     strsplit(ls('-rt', [ dirname filesep 'trial*bundle.mat' ]), '\s', ...
% $$$              'DelimiterType', 'RegularExpression');

while true
  % Use /bin/sh to prevent garbled output (https://www.mathworks.com/matlabcentral/answers/93930-why-do-system-commands-like-ls-not-function-as-expected-when-i-call-them-from-matlab-7-11-r2010b)
  % load in reverse time order to approximate GA generations
  ls_cmd = [ 'cd ' dirname '; /bin/sh -c "ls -rt trial*bundle.mat" < /dev/null' ];
  [status, files] = unix(ls_cmd);
  if status ~= 0
    error([ 'ls failed with status: ' num2str(status) ]);
  end
  
  % => no change!
  bundle_files = ...
      strsplit(files, '\s', ...
               'DelimiterType', 'RegularExpression');

  % strsplit workarounds %$#%@#
  if isempty(bundle_files{1}) 
    bundle_files = bundle_files(2:end);
  end

  if isempty(bundle_files{end}) 
    bundle_files = bundle_files(1:(end-1));
  end

  % make sure the output of ls is clean (Matlab bug workaround)
  if exist([dirname filesep bundle_files{1}], 'file') && ...
      exist([dirname filesep bundle_files{end}], 'file')
    break;
  else
    disp(['Can''t find file "' bundle_files{1} '" OR "' bundle_files{end} ...
          '" assuming broken ls.' ...
          ' Repeating.'])
    %system('sleep 1s') => results in an uninterruptible process if
    %something goes wrong
  end
  
end

% load all bundles into a cell array (or celery) and count rows
num_files = length(bundle_files);

disp(['Found ' num2str(num_files) ' bundle files. Concatenating...']);

assert(num_files > 0);

% TODO: do this load process in the above loop in case it fails midway
num_dataset_items = 0;
num_db_rows = 0;
num_joined_db_rows = 0;
bundles = cell(1, num_files);
for file_num = 1:num_files
  try
% $$$     % Matlab buffer bug workaround; file names broken across two items
% $$$     if ~ exist([ dirname filesep bundle_files{file_num} ], 'file') && ...
% $$$         exist([dirname filesep bundle_files{file_num} bundle_files{file_num + 1}], 'file')
% $$$       % correct next entry
% $$$       bundle_files{file_num + 1} = [bundle_files{file_num} bundle_files{file_num + 1}];
% $$$       disp(['Matlab bugfix, concatenating entries ' num2str(file_num) '-' num2str(file_num+1) ': "' ...
% $$$             bundle_files{file_num + 1} '"' ]);
% $$$       disp([ 'Next entry #' num2str(file_num + 2) ': "' bundle_files{file_num + 2} '"' ]);
% $$$       continue;
% $$$     else
    s = load([ dirname filesep bundle_files{file_num} ]);
% $$$     end
    num_dataset_items = num_dataset_items + length(s.a_bundle.dataset.list);
    num_db_rows = num_db_rows + dbsize(s.a_bundle.db, 1);
    num_joined_db_rows = num_joined_db_rows + dbsize(s.a_bundle.joined_db, 1);
    bundles{file_num} = s.a_bundle;
  catch me
    file_num
    disp([ '"' bundle_files{file_num} '"' ])
    rethrow(me);
  end
end

% measure contents of first bundle
a_bundle = bundles{1};
offset_items = length(a_bundle.dataset.list);
offset_db_rows = dbsize(a_bundle.db, 1);
offset_joined_db_rows = dbsize(a_bundle.joined_db, 1);

% expand it to handle content of all bundles
a_bundle.dataset.list = ...
    repmat(a_bundle.dataset.list, 1, num_files);
a_bundle.db.data = ...
    repmat(a_bundle.db.data, num_files, 1);
a_bundle.joined_db.data = ...
    repmat(a_bundle.joined_db.data, num_files, 1);

% loop again to fill it, but we must correct itemset and rowindex values
for file_num = 2:num_files
  % correct ItemIndex
  bundles{file_num}.db(:, 'ItemIndex') = ...
      bundles{file_num}.db(:, 'ItemIndex') + offset_items;
  bundles{file_num}.joined_db(:, '/ItemIndex.*/') = ...
      bundles{file_num}.joined_db(:, '/ItemIndex.*/') + offset_items;
  bundles{file_num}.joined_db(:, '/RowIndex.*/') = ...
      bundles{file_num}.joined_db(:, '/RowIndex.*/') + offset_db_rows;
  % concat data
  a_bundle.dataset.list(offset_items + ...
                        (1:length(bundles{file_num}.dataset.list))) = ...
    bundles{file_num}.dataset.list;
  a_bundle.db.data(offset_db_rows + ...
                   (1:dbsize(bundles{file_num}.db, 1)), :) = ...
    bundles{file_num}.db.data;
  a_bundle.joined_db.data(offset_joined_db_rows + ...
                          (1:dbsize(bundles{file_num}.joined_db, 1)), :) = ...
    bundles{file_num}.joined_db.data;
  % Increment offsets
  offset_items = ...
      offset_items + length(bundles{file_num}.dataset.list);
  offset_db_rows = ...
      offset_db_rows + dbsize(bundles{file_num}.db, 1);
  offset_joined_db_rows = ...
      offset_joined_db_rows + dbsize(bundles{file_num}.joined_db, 1);
end

% workaround to add trial back if missing 
if ~ any(ismember(getParamNames(a_bundle.joined_db), 'trial'))
  a_bundle.joined_db = makeHErowDb(a_bundle.db);
end

% re-create joined_db if a join_func is specified
if isfield(props, 'joinDBfunc')
  a_bundle.joined_db = feval(props.joinDBfunc, a_bundle.db);
end

% trial numbers were used to be index numbers, to use these new numbers like
% indices, create a new hash
precision = getFieldDefault(props, 'precision', 6);
a_bundle.dataset.props.precision = precision;

% first eliminate trial collusions that overwrote same files
% $$$ [unique_trials_db, unique_idx] = ...
% $$$     unique(a_bundle.db(:, 'trialGA'));

% create hash and put it in dataset props
a_bundle.dataset.props.trialHashFunc = calcTrialHash;
a_bundle.dataset.props.trial_hash = ...
    cell2struct(num2cell((1:dbsize(a_bundle.joined_db, 1))'), ...
                cellfun(@(x) calcTrialHash(x, precision),  ...
                        num2cell(a_bundle.joined_db(:, 'trial').data), ...
                        'UniformOutput', false), 1);

% update param_names as well
a_bundle.dataset.props.param_names = ...
    getParamNames(a_bundle.joined_db);

% write a new param file
if isfield(a_bundle.dataset.props, 'param_row_filename')
  parfile_name = [ dirname filesep ...
                   a_bundle.dataset.props.param_row_filename ];
else
  parfile_name = [ dirname filesep 'all.par' ];
end
writeParFile(a_bundle.joined_db, parfile_name, struct('noAppend', 1));

% set the new param file
% BUG: giving full path to param file messes up with simNewParams
a_bundle.dataset.props.param_row_filename = ...
    parfile_name;

% also set the params directly
a_bundle.dataset.props.param_rows = ...
    a_bundle.joined_db(:, 1:a_bundle.joined_db.num_params).data;
