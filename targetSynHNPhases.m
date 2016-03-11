% intro figures

%% Data from Angela

% columns: HN 4 3 6 7
% rows: 5/19A, 5/19B, 5/20B, 5/22B, 5/26A, 5/27B
hn_phase_peri = [
0 1.073 0.925 0.876
0 1.114 0.856 0.929
0 0.994 0.862 0.798
0 0.992 0.846 0.809
0 1.0222 0.826 0.672
0 1.069 0.873 0.865];

hn_phase_peri_db = ...
    tests_db(hn_phase_peri, {'HN4', 'HN3', 'HN6', 'HN7'}, ...
             {'May19A', 'May19B', 'May20B', 'May22B', 'May26A', 'May27B'}, ...
             'HN peri phases');

% median, 1st/last spike
he8_phase_peri = [
0.494 0.161 0.826
0.556 0.375 0.711
0.468 0.151 0.807
0.429 0.0418 0.797
0.406 0.0295 0.822
0.567 0.358 0.800];

he8_phase_peri_db = ...
    tests_db(he8_phase_peri, {'median', 'spike1st', 'spikelast'}, ...
             {'May19A', 'May19B', 'May20B', 'May22B', 'May26A', 'May27B'}, ...
             'HE(8) peri phases');

hn_he8_ipsc_nS_peri = [
3.57 6.27 4.42 3.66
3.52 7.03 6.22 5.77
3.65 4.68 4.12 2.95
12.53 7.85 16.97 11.89
2.67 3.27 6.31 3.14
6.201 8.223 5.880 5.382];

hn_he8_ipsc_nS_peri_db = ...
    tests_db(hn_he8_ipsc_nS_peri, {'HN3', 'HN4', 'HN6', 'HN7'}, ...
             {'May19A', 'May19B', 'May20B', 'May22B', 'May26A', 'May27B'}, ...
             'HN->HE(8) IPSC strength [nS]');

% calculate relative synaptic weights
rel_weights = @(x) x ./ repmat(sum(x, 2), 1, size(x,2));

hn_he8_ipsc_rel_peri_db = hn_he8_ipsc_nS_peri_db;
hn_he8_ipsc_rel_peri_db.data = ...
    rel_weights(hn_he8_ipsc_nS_peri_db.data);
hn_he8_ipsc_rel_peri_db.id = 'HN->HE(8) relative IPSC strength';

% median, 1st/last spike
he12_phase_peri = [
0.425 0.063 0.796
0.475 0.234 0.686
0.371 0.0223 0.824
0.324 0.9881 0.686
0.261 0.894 0.554
0.390 0.210 0.567];

he12_phase_peri_db = ...
    tests_db(he12_phase_peri, {'median', 'spike1st', 'spikelast'}, ...
             {'May19A', 'May19B', 'May20B', 'May22B', 'May26A', 'May27B'}, ...
             'HE(12) peri phases');


hn_he12_ipsc_nS_peri = [
1.97 2.18 3.47 3.97
1.14 4.62 7.40 16.97
2.48 2.43 4.94 12.15
6.15 6.21 12.02 12.98
0.87 0.67 4.34 4.66
1.73 3.42 4.67 12.27];

hn_he12_ipsc_nS_peri_db = ...
    tests_db(hn_he12_ipsc_nS_peri, {'HN3', 'HN4', 'HN6', 'HN7'}, ...
             {'May19A', 'May19B', 'May20B', 'May22B', 'May26A', 'May27B'}, ...
             'HN->HE(12) IPSC strength [nS]');

% calculate relative synaptic weights
rel_weights = @(x) x ./ repmat(sum(x, 2), 1, size(x,2));

hn_he12_ipsc_rel_peri_db = hn_he12_ipsc_nS_peri_db;
hn_he12_ipsc_rel_peri_db.data = ...
    rel_weights(hn_he12_ipsc_nS_peri_db.data);
hn_he12_ipsc_rel_peri_db.id = 'HN->HE(12) relative IPSC strength';

%% synchronous

% columns: HN 4 3 6 7
% rows: 5/19A, 5/19B, 5/20B, 5/22B, 5/26A, 5/27B
hn_phase_sync = [
0 0.106 0.073 0.100
0 0.127 0.061 0.121
0 -0.025 0.0486 0.0886
0 0.025 0.0591 0.104
0 0.0324 0.0616 0.0896
0 0.063 0.108 0.109];

hn_phase_sync_db = ...
    tests_db(hn_phase_sync, {'HN4', 'HN3', 'HN6', 'HN7'}, ...
             {'May19A', 'May19B', 'May20B', 'May22B', 'May26A', 'May27B'}, ...
             'HN sync phases');

% median, 1st/last spike
he8_phase_sync = [
0.535 0.237 0.826
0.587 0.385 0.821
0.458 0.131 0.800
0.464 0.13 0.823
0.456 -0.892 0.82
0.565 0.348 0.822];

he8_phase_sync_db = ...
    tests_db(he8_phase_sync, {'median', 'spike1st', 'spikelast'}, ...
             {'May19A', 'May19B', 'May20B', 'May22B', 'May26A', 'May27B'}, ...
             'HE(8) sync phases');

% median, 1st/last spike
he12_phase_sync = [
0.590 0.276 0.864
0.653 0.398 0.860
0.478 0.089 0.856
0.467 0.043 0.891
0.549 -0.839 0.873
0.597 0.390 0.838];

he12_phase_sync_db = ...
    tests_db(he12_phase_sync, {'median', 'spike1st', 'spikelast'}, ...
             {'May19A', 'May19B', 'May20B', 'May22B', 'May26A', 'May27B'}, ...
             'HE(12) sync phases');

%% Replicate Mike's plot

input_num = 1;
hn_phase_peri_db(:, {'HN4'}) = 1;       % Should be not 0, but 1?
plot_one_hns = ...
    @(input_num) ...
    plotXRows(transpose(hn_phase_peri_db(:, {'HN3', 'HN4', 'HN6', ...
                    'HN7'}) - 1), input_num, input_names{input_num}, '', ...
                     struct('command', 'plot', 'plotProps', ...
                            struct('LineStyle', '-', ...
                                   'LineWidth', 2, ...
                                   'Color', input_colors{input_num}, ...
                                   'Marker', input_markers{input_num}, ...
                             'MarkerEdgeColor', 'black', ...
                             'MarkerFaceColor', input_colors{input_num}, ...
                             'MarkerSize', 10)));

all_plots = {};
for input_num = 1:6
  all_plots{input_num} = plot_one_hns(input_num);
end
plotFigure(plot_superpose(all_plots))
% - make rows plot on the y-axis? use plot instead of scatter

% TODO:
% - Make a plot for HE8 and 12 showing a the strength of input based on
% the phase of input without specifying the names of the
% interneurons. Maybe use a histogram or take weighted average of
% synapses and phases to make a single point. => Use this to define a new SSI?
