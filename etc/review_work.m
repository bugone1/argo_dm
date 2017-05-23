%Go throuh unchanged dir, output last calib equations, qc flags, adjusted errors and comments
clear
cd('E:\RApps\argo_DM\Calibration\output')
a=dir('unchanged\*.nc')
for i=1:length(a)
    nc=netcdf(['\unchanged\' a(i).name]);
    a(i).name
    N_HIST=f('N_HISTORY');
    nc{'PARAMETER'}(:,D,:,:)
    nc{'SCIENTIFIC_CALIB_EQUATION')(:,:,3,:)
    nc{'SCIENTIFIC_CALIB_COMMENT')(:,:,3,:)
    nc{'PROFILE_PSAL_QC'}(:)
    f{'PSAL_ADJUSTED_ERROR'}(:)
    pause
    ncclose
end
