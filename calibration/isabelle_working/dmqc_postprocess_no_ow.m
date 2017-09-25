function dmqc_postprocess_no_ow(float_num, psal_comment)
% Assuming a float has undergone pressure correction and visual QC, but not
% OW processing (e.g., because there are too few profiles), export NetCDF
% files and create output ZIP, HTML, etc.
%
% Isabelle Gaboury, 29 Aug. 2017

% Adjust paths
% Make sure the Seawater and VMS tools toolboxes are on the path
if ~ispc
    addpath('/u01/rapps/argo_dm/calibration');
    addpath('/u01/rapps/vms_tools');
%     addpath('/u01/rapps/m_map');
%     addpath('/u01/rapps/gsw/');
%     addpath('/u01/rapps/gsw/library');
else
    addpath('w:\argo_dm\calibration');
    addpath('w:\seawater');
    addpath('w:\vms_tools');
    addpath('w:\m_map');
    addpath('w:\gsw');
    addpath('w:\gsw\library');
end

if nargin < 2
    psal_comment = 'Too few profiles passed visual QC to compute a conductivity adjustment';
end

% Setup
local_config=load_configuration('local_OW.txt');
lo_system_configuration=load_configuration([local_config.BASE 'config_ow.txt']);
ftp_user = 'igabouryi@sshreadwrite';

% Adjustments
% viewplots_nocorr(lo_system_configuration,local_config,float_num, psal_comment);
% reducehistory(local_config,float_num);
publishtoweb_nocorr(local_config,lo_system_configuration,float_num,1,ftp_user);