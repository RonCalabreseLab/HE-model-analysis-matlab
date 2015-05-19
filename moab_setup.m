function result = pace_setup(rundir)

% setup the parallel pool
result = PaceParallelToolBox_r2014b_4(true, 'job_storage', rundir)
