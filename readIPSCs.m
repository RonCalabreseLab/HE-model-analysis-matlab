function [ipsc_mag_nS, ipsc_std_nS] = ...
    readIPSCs(input_num, he_num, hn_num, props)

% Read Angela and Anca's files to find IPSC magnitude and standard
% deviation in nS

common

% or use the which() function to find this script's location
filename = [ '../../common/analysis/' ...
             input_names{input_num} '/HN' sprintf('%02d', hn_num) ...
             'toHE' sprintf('%02d', he_num) '_' ...
             input_names{input_num} '_avg_std.m' ];

% load and evaluate all contents of file
try
  str_ipsc = ...
      textread(filename, '%s', 'whitespace', '', 'bufsize', 100e3);  
  % correct empty lines
  str_ipsc = regexprep(str_ipsc{1}, '=\s+([.\d]+)', '=$1;');
  % rename std to std_array to avoid confusing Matlab
  eval(regexprep(str_ipsc, 'std =', 'std_array ='));
catch me
  disp(['Error trying to load filename "' filename '"'])
  rethrow(me);
end

% avg is the average IPSC trace
% std_array is its STD at each point

% IPSC magnitude [nA] from left point to peak
[m,i]=max(avg);
ipsc_mag = m - avg(1);
% Removed, just too much: std_array(1)
ipsc_std = std_array(i);

% convert to conductance [nS]
% nS = 1e3 * nA / ( E_hold - E_rev [mV]) 
% defaults: 
%   E_rev = -62.5 mV
%   E_hold = -45 mV
delta_v = (-45 + 62.5);
ipsc_mag_nS = 1e3 * ipsc_mag / delta_v;
ipsc_std_nS = 1e3 * ipsc_std / delta_v;


