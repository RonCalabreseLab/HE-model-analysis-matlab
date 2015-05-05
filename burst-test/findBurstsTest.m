function findBurstTest()

% call runxunit in this directory to run these tests
t_he12 = ...
    trace_HE(['simhe-2synscales_input5_22B_m47_batch11_all_cond_rank7_somaVm_HE_12.genflac'], ...
             12, '5_22B', 5e-4, 1, 'input5_22B_m47_batch11_all_cond_rank7', ...
             struct('inputDir', '../../input-patterns'));
%plot(t_he12)

[prof_he12, intermediate_data, freerunisistats, tracedata] = ...
    getResults(t_he12, struct('HNweights', 1, 'debug', 1));
%plot(prof_he12, '', struct('fixedSize', [12 4]))

% 3rd one is the HN4 reference, so shouldn't change:
assert(prof_he12.intermediate_data.firstlastraw{3}(1,1) == 23.249056, ...
       'HN4 firstlast ref broken');

% => pretty bad example, this file should not have been accepted

