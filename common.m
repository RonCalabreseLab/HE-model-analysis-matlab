hn_list = [3 4 6 7];

input_names = ...
      {'5_19A', '5_19B', '5_20B', '5_22B', '5_26A', '5_27B'};

% sort by maximal absolute error
sort_MAE = @(a_db)...
    sortrows(addColumns(a_db, 'Max', ...
                        get(max(abs(delColumns(a_db, {'Distance', 'RowIndex'})), 2), ...
                            'data')), 'Max');

% add MPP metrics, make them funcs
add_MPP = @(a_db)...
          addColumns(a_db, {'pMPP', 'sMPP'}, ...
                     [a_db(:, 'peri_phase_median_HE8', :).data - ...
                    a_db(:, 'peri_phase_median_HE12', :).data, ...
                    a_db(:, 'sync_phase_median_HE8', :).data - ...
                    a_db(:, 'sync_phase_median_HE12', :).data]);