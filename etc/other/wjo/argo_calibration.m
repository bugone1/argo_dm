function argo_calibration(lo_system_configuration,float_names)
% have to edit "config.txt" if this system is moved somewhere else.
% ----------------------------------------------------------------------
% function argo_calibration
% dir names and float names have to correspond,
% e.g. float_dirs={'pmel/';'uw/'}
%      float_names={'49000140';'39033'};
%0  update_mat_files_with_new_data
%1  update_historical_mapping_ron
%2  set_calib_series_ron
%3  calculate_running_calib_ron % this is the file which calculates CAL_SAL
%4  plot_diagnostics_ron
%5  do_float_gdac (post argo_calibration_ron)
%6  viewplotsnew 
%float_names={'2900193'};
%float_dirs={'E:\RApps\argo_DM\data\float_source\wjo'};
%MAT files                                                      loaded by      created/updated by
%----------------------------------------------------------------------------------------------------
% C:\z\argo_dm\data\float_source\*.mat                 3,4,5,6         0
% C:\z\argo_dm\data\float_mapped\map_*.mat             2,3,4           1
% C:\z\argo_dm\data\float_calib\calseries_*.mat        3,5,6           2,5,6               this is the file with CellK
% C:\z\argo_dm\data\float_calib\cal_*.mat              4,5,6           3                   this is the file with CAL_SAL
% C:\z\argo_dm\data\constants\coastdat.mat             4
% c:\z\argo_dm\calibration\output\R*_*.nc              5              
for i=1:length(float_names)    
  tic
  update_historical_mapping('', float_names{i}, lo_system_configuration );
  toc %1541.32
  tic
  set_calib_series('', float_names{i}, lo_system_configuration );
  toc %0.09 s
  tic
  calculate_running_calib_mat('', float_names{i}, lo_system_configuration );
  toc %251 s
  tic
  plot_diagnostics_mat('', float_names{i}, lo_system_configuration );
  toc %26 secs
end