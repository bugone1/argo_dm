% Short-term function to carry out OW operations on multiple GlazeO floats,
% skipping the troublesome plotting
%
% INPUTS:
%   action - one of 'process' (the default) or 'plot'. We plot separately
%       because when working over ssh with XWindows the terminal is usually
%       no longer in a state able to support plotting by the time the OW
%       run is complete.
%
% IG, June 2017
function glazeo_ow(action, float_names)

if nargin < 1, action = 'process'; end
if nargin < 2, float_names = {'4901750','4901752'}; end
if ischar(float_names), float_names = {float_names}; end

% Paths
addpath('/u01/rapps/argo_dm/calibration');
addpath('/u01/rapps/seawater');
addpath('/u01/rapps/vms_tools');
addpath('/u01/rapps/m_map');

% Setup
local_config=load_configuration('local_OW.txt');
lo_system_configuration=load_configuration([local_config.BASE 'config_ow_atlantic.txt']);

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
