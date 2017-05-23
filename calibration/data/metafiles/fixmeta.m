nc=netcdf.open('4900872_meta.nc','write');
netcdf.putvar(nc,netcdf.inqVarID(nc,'DEPLOY_PLATFORM'),netstr('CCGS John P Tully',32))
close(nc)
nc=netcdf.open('4900873_meta.nc','write');
netcdf.putvar(nc,netcdf.inqVarID(nc,'DEPLOY_PLATFORM'),netstr('CCGS John P Tully',32))
close(nc)
nc=netcdf.open('4900883_meta.nc','write');
lon=netcdf.getVar(nc,netcdf.inqVarID(nc,'LAUNCH_LONGITUDE'));
if lon<0
netcdf.putvar(nc,netcdf.inqVarID(nc,'LAUNCH_LONGITUDE'),-lon);
end
close(nc)
nc=netcdf.open('4900399_meta.nc','write');
lon=netcdf.getVar(nc,netcdf.inqVarID(nc,'LAUNCH_LONGITUDE'));
if lon<0
netcdf.putvar(nc,netcdf.inqVarID(nc,'LAUNCH_LONGITUDE'),-lon);
end
close(nc)