function a_htr = trace_HE(filename, gangno, inputname, dt, dy, id, props)

% trace_HE - Holds peri and sync soma Vm traces from an HE simulation.
%
% Usage:
% a_htr = trace_HE(filename, gangno, dt, dy, id, props)
%
% Parameters:
%   filename: TXT file generated by Genesis.
%   gangno: The ganglion number.
%   inputname: Name of the directory for input patterns (e.g., '5_19B').
%   dt: Time resolution in [s].
%   dy: y-axis resolution in [V].
%   id: Identification string.
%   props: A structure with any optional properties.
%     inputDir: Base directory for input patterns (default:
%		'../../common/input-patterns').
%
% Returns a structure object with the following fields:
%   sync_tr, peri_tr.
%
% Description:
%   Encapsulates the data and provides functions to analyze and
% calculate fitness.
%
% Example:
% >> a_htr = trace_HE('data/HE12soma_Vm2.txt', 5e-4, 1, 'HE12 soma Vm');
%
% General methods of trace_HE objects:
%   trace_HE		- Construct a new trace_HE object.
%
% Additional methods:
%   See methods('trace_HE')
%
% See also: trace
%
% $Id: trace_HE.m 234 2010-10-21 22:06:52Z cengiz $
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2014/03/19

% Copyright (c) 2007-2014 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

if nargin == 0 % Called with no params
  a_htr = struct;
  a_htr.peri_tr = trace;
  a_htr.sync_tr = trace;
  a_htr.gangno = [];
  a_htr.inputname = [];
  a_htr.id = '';
  a_htr.props = struct;
  a_htr = class(a_htr, 'trace_HE');
elseif isa(filename, 'trace_HE') % copy constructor?
  a_htr = filename;
else
  if ~ exist('props', 'var')
    props = struct;
  end

  prefix_name = [ 'HE' num2str(gangno) ' ' inputname ];
  
  a_htr = struct;
  a_htr.peri_tr = ...
      trace(filename, dt, dy, [ prefix_name ' peri ' id ], ...
            struct('channel', 2));

  a_htr.sync_tr = ...
      trace(filename, dt, dy, [ prefix_name ' sync ' id ], ...
            struct('channel', 3));
  a_htr.gangno = gangno;
  a_htr.inputname = inputname;
  a_htr.id = id;
  a_htr.props = props;

  a_htr = class(a_htr, 'trace_HE');
end
