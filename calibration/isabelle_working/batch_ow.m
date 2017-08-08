function batch_ow(float_names, action, region)
% BATCH_OW - Carry out OW processing for a list of floats
%   USAGE: batch_ow(float_names, action, region)
%   INPUTS:
%       float_names - List of floats to process
%       action - One of 'process' (the default) or 'plot'
%       region - One of '' (the default), 'pacific', or 'atlantic'
%   VERSION HISTORY
%       June 2017, Isabelle Gaboury - Written for processing of Atlantic
%           floats
%       17 July 2017, IG - Generalized for other regions, removed any
%           hard-coded variables

% Process the inputs
if ischar(float_names), float_names = {float_names}; end
if nargin < 2, action = 'process'; end
if nargin < 3, region = ''; end

% Paths
if ~ispc
    addpath('/u01/rapps/argo_dm/calibration');
    addpath('/u01/rapps/seawater');
    addpath('/u01/rapps/vms_tools');
    addpath('/u01/rapps/m_map');
else
    addpath('w:\argo_dm\calibration');
    addpath('w:\seawater');
    addpath('w:\vms_tools');
    addpath('w:\m_map');
end
 
% Load configuration files
local_config=load_configuration('local_OW.txt');
if strcmpi(region,'atlantic')
    lo_system_configuration=load_configuration([local_config.BASE 'config_ow_atlantic.txt']);
else
    lo_system_configuration=load_configuration([local_config.BASE 'config_ow.txt']);
end

% Default figure position
set(0,'defaultfigureposition',[500 500 560 420]);
 
% Processing
cd(local_config.MATLAB)
for ii=1:length(float_names)
    display(['Working on float ' float_names{ii}]);
    try
        if strcmpi(action,'process')
            update_salinity_mapping('',float_names{ii},lo_system_configuration);
            set_calseries('',float_names{ii},lo_system_configuration);
            calculate_piecewisefit('',float_names{ii},lo_system_configuration);
        elseif strcmpi(action,'plot')
            plot_diagnostics_ow('',float_names{ii},lo_system_configuration);
        end
    catch ex
        display(['Float ' float_names{ii} ' failed: ' ex.message]);
    end
end
cd(local_config.BASE)
end
