function argo_calibration(lo_system_configuration,float_names)
% have to edit "ow_config.txt" if this system is moved somewhere else.
% ----------------------------------------------------------------------
% script ow_calibration
% dir names and float names have to correspond,
% e.g. float_dirs={'sio/';'uw/'}
%      float_names={'R49000139';'R39033'};
% these variables have to be set before ow_calibration is called.
%lo_system_configuration = load_configuration( '../calibration/ow_config.txt'); has already been loaded
for i=1:length(float_names)
    disp([datestr(now) ' Working on ' float_names{i}])
    update_salinity_mapping('',float_names{i},lo_system_configuration);
    set_calseries('',float_names{i},lo_system_configuration);
    calculate_piecewisefit('',float_names{i},lo_system_configuration);
    plot_diagnostics_ow('',float_names{i},lo_system_configuration);
end