function a_crit_db = overwrite_crit_stds(a_crit_db)
% overwrite_crit_stds - Set physiological STD values into 2nd row of a_crit_db.
% 
% Usage: 
% overwrite_crit_stds(a_crit_db)

  a_crit_db(2, '/duty/') = 0.1;
  a_crit_db(2, '/phase/') = 0.03;
  a_crit_db(2, '/freq/') = 7;
  a_crit_db(2, '/spike_height/') = 7.5;
  a_crit_db(2, '/wave_heigh/') = 5;
  if dbsize(a_crit_db(:, '/MPP/'), 2) > 0 
    a_crit_db(2, '/MPP/') = 0.06;
  end
