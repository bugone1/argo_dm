function set_calseries( pn_float_dir, pn_float_name, po_system_configuration )
% function set_calseries( pn_float_dir, pn_float_name, po_system_configuration )
%
% Annie Wong, September 2008
% Breck Owens, October 2006
%
% load data ---
lo_float_source_data = load( strcat( po_system_configuration.FLOAT_SOURCE_DIRECTORY, pn_float_dir, pn_float_name, po_system_configuration.FLOAT_SOURCE_POSTFIX)) ;
PROFILE_NO = lo_float_source_data.PROFILE_NO;
n=length(PROFILE_NO);
ls_calseries_filename = strcat(po_system_configuration.FLOAT_CALIB_DIRECTORY, pn_float_dir, po_system_configuration.FLOAT_CALSERIES_PREFIX, pn_float_name, po_system_configuration.FLOAT_CALIB_POSTFIX);
% build default values ---
if exist(ls_calseries_filename,'file')
    load(ls_calseries_filename);
else
    breaks = [];
    max_breaks = 4;
    calseries = ones(1,n);
    calib_profile_no = PROFILE_NO;
    theta=eval(po_system_configuration.theta);
    pres=eval(po_system_configuration.pres);
    use_theta_lt=theta(1);
    use_theta_gt=theta(2);
    use_pres_lt=pres(1);
    use_pres_gt=pres(2);
end
% to enhance backward compatiability because I added a new variable "use_percent_gt" and changed 99999 to [] in Sep08 ---
if ~exist('use_percent_gt','var')
  use_percent_gt = 0.5;
end
if use_theta_gt == 99999; use_theta_gt = [];  end
if use_theta_lt == 99999; use_theta_lt = [];  end
if use_pres_gt == 99999; use_pres_gt = [];  end
if use_pres_lt == 99999; use_pres_lt = [];  end
% compare profile_number in source file and calseries file ----
[tr,missing_profile_index] = setdiff(PROFILE_NO,calib_profile_no);
for i=1:length(missing_profile_index)
   j = missing_profile_index(i);
   calib_profile_no = [calib_profile_no, PROFILE_NO(j)];
   calseries = [calseries, calseries(max(j-1,1))]; % same flag as previous profile
end
% sort the calseries file by profile_number ----
[calib_profile_no,ii]=sort(calib_profile_no);
calseries=calseries(ii);
% if SAL or TEMP or PRES = all NaNs, calseries = 0 -----
SAL = lo_float_source_data.SAL;
TEMP = lo_float_source_data.TEMP;
PRES = lo_float_source_data.PRES;
calseries(sum(~isnan(SAL),2)==0 | sum(~isnan(TEMP),2)==0 | sum(~isnan(PRES),2)==0)=0;
try
save( ls_calseries_filename, 'breaks', 'max_breaks', 'calseries', 'calib_profile_no', 'use_theta_lt', 'use_theta_gt', 'use_pres_gt', 'use_pres_lt', 'use_percent_gt' );
catch
    display('!chmod 777 /u01/rapps/argo_dm/data/float_calib/ow/*.*');
    cd('W:\argo_dm\calibration\');
end