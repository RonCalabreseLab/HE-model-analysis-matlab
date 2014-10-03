function a_bundle = collectBundles(dirname)
% collect all bundles in current directory and merge into one

bundle_files = dir([ dirname filesep 'trial*bundle.mat' ]);

% load all bundles into a cell array (or celery) and count rows
num_files = length(bundle_files);
disp(['Found ' num2str(num_files) ' bundle files. Concatenating...']);

assert(num_files > 0);

num_dataset_items = 0;
num_db_rows = 0;
num_joined_db_rows = 0;
bundles = cell(1, num_files);
for file_num = 1:num_files
  s = load([ dirname filesep bundle_files(file_num).name ]);
  num_dataset_items = num_dataset_items + length(s.a_bundle.dataset.list);
  num_db_rows = num_db_rows + dbsize(s.a_bundle.db, 1);
  num_joined_db_rows = num_joined_db_rows + dbsize(s.a_bundle.joined_db, 1);
  bundles{file_num} = s.a_bundle;
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