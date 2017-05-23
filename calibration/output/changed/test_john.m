%test_john
t=dir('*.nc');
for i=1:length(t)
nc=netcdf.open(t(i).name,'NOWRITE');

if any(unique(netcdf.getVar(nc,netcdf.inqVarID(nc,'PRES_ADJUSTED_QC'))))<49  || any(unique(netcdf.getVar(nc,netcdf.inqVarID(nc,'TEMP_ADJUSTED_QC'))))<49 || any(unique(netcdf.getVar(nc,netcdf.inqVarID(nc,'PSAL_ADJUSTED_QC'))))<49    
error('ADJUSTED_QC error');
elseif 
    
    
netcdf.close(nc)
end