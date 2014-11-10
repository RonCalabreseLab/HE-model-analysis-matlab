function a_bundle = collectBundles(dirname, props)
% Collect all bundles in directory and merge into one. When numbering the
% item indices, count the oldest files first as an indication of earlier
% parameter search iterations.

common

props = defaultValue('props', struct);

% BUG: all external directory listing functions in Matlab R2014a are
% buggy. There is a buffer clearing issue that either truncates entries
% or start with junk from last run. Repeating this operation 5-10 times
% (!) eventually works.

% $$$ bundle_files = ...
% $$$     strsplit(ls('-rt', [ dirname filesep 'trial*bundle.mat' ]), '\s', ...
% $$$              'DelimiterType', 'RegularExpression');

ls_cmd = [ 'ls -rt ' dirname filesep 'trial*bundle.mat' ];
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

% load all bundles into a cell array (or celery) and count rows
num_files = length(bundle_files);

if isempty(bundle_files{end}) 
  num_files = num_files - 1;
end
disp(['Found ' num2str(num_files) ' bundle files. Concatenating...']);

assert(num_files > 0);

num_dataset_items = 0;
num_db_rows = 0;
num_joined_db_rows = 0;
bundles = cell(1, num_files);
for file_num = 1:num_files
  try
    s = load([ bundle_files{file_num} ]);
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
  %  a_bundle.joined_db = joinRows(a_bundle.joined_db, a_bundle.db(:, 'trial'), ...
  %                             struct('indexColName', 'RowIndex_HE8', ...
  %                                    'keepIndex', 1))
  a_bundle.joined_db = makeHErowDb(a_bundle.db);
end
  
% calculated trial number does not match with the earlier convention, so
% rename it
% $$$ a_bundle.db = ...
% $$$     addParams(renameColumns(a_bundle.db, 'trial', 'trialGA'), ...
% $$$               'trial', (1:dbsize(a_bundle.db, 1))');

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
parfile_name = [ dirname filesep a_bundle.dataset.props.param_row_filename ];
writeParFile(a_bundle.joined_db, parfile_name, struct('noAppend', 1));

% set the new param file
a_bundle.dataset.props.param_row_filename = ...
    parfile_name;

% also set the params directly
a_bundle.dataset.props.param_rows = ...
    a_bundle.joined_db(:, 1:a_bundle.joined_db.num_params).data;
