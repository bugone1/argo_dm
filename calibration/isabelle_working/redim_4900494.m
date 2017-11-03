function redim_4900494

float_num = '4900494';
indir = '/u01/rapps/argo_dm/calibration/output/changed/';
outdir = '/u01/rapps/argo_dm/calibration/output/changed/4900494_working/';

infiles = dir([indir 'BD*' float_num '*.nc']);

for ii_file = 1:length(infiles)
    copy_nc_redim([indir infiles(ii_file).name], [outdir infiles(ii_file).name], 'N_CALIB', -1);
end

movefile([outdir '*'], indir)

end