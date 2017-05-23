function [ll,sdn,I]=getll_argo(f)
for i=1:length(f)
    nc=netcdf.open(f(i).name,'NOWRITE');
    f(i).name
    ll(i,:)=[netcdf.getVar(nc,netcdf.inqVarID(nc,'LONGITUDE')) netcdf.getVar(nc,netcdf.inqVarID(nc,'LATITUDE'))];
    sdn(i)=netcdf.getVar(nc,netcdf.inqVarID(nc,'JULD'))+datenum(1950,1,1);
    und=find(f(i).name=='_');
    I(i)=str2num(f(i).name(und+1:und+3));
    netcdf.close(nc)
end
[sdn,i]=sort(sdn);
ll=ll(i,:);
I=I(i);

