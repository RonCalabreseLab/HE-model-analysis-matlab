function state = gaplotInputSpread(options, state, flag)

med_pop = median(state.Population, 1)';
std_pop = std(state.Population, 0, 1)';

% or NaN to plot into currently open axis?
pos = get(gca, 'OuterPosition');

% delete the existing axis?
delete(gca);

plot(plot_bars(med_pop, med_pop, ...
               med_pop + std_pop, [], {}, {}, ...
               ['Median\pm{}STD of inputs'], ...
               [0 (length(med_pop) + 1) 0 Inf], ...
               struct('dispNvals', 0)), ...
     pos); 

