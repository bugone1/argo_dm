function S=getClimGTSPP_new(LON,LAT,month,var)
%S=getClim(LON,LAT,sprintf('%2.2i',nmonth),'psal')
%or
%S=getClim(fxd,'psal')
%----2020-9-25 zhimin ma, fixing a bug in converting temp,psal to real
%value existed in old code
th=[.5 .2]; %thresholds set for temp and psal values resp table 3.4 GTSPP manual
if isstruct(LON)
    if isfield(LON,'FXD')
        LON=LON.FXD;
    end
    fxd=LON;
    var=LAT;
    month=fxd.OBS_MONTH;
    LON=-fxd.LONGITUDE;
    LAT=fxd.LATITUDE;
else
    if isnumeric(month)
        month=sprintf('%2.2i',month);
    end
end
var=upper(var);

if ispc
    pathe0='C:\Users\maz\Desktop\MEDS Project\ooi\ISAS13\';
    pathe='C:\Users\maz\Desktop\MEDS Project\ooi\ISAS13\';
else
    pathe='/u01/rapps/ooi/isas_v5/confstd/climref/';
end
if ~exist([pathe 'ISAS13FD_m' month '_' var '.nc'],'file')
    try
        copyfile([pathe0 'ISAS13FD_m' month '_' var '.nc'],[pathe 'ISAS13FD_m' month '_' var '.nc']);
    catch
        mkdir(pathe);
        copyfile([pathe0 'ISAS13FD_m' month '_' var '.nc'],[pathe 'ISAS13FD_m' month '_' var '.nc']);
    end
end


ncid=netcdf.open([pathe 'ISAS13FD_m' month '_' var '.nc'],'nowrite');
lat=netcdf.getVar(ncid,netcdf.inqVarID(ncid,'latitude'));
lon=netcdf.getVar(ncid,netcdf.inqVarID(ncid,'longitude'));
[tr1,dx]=min(abs(lon-LON));
[tr2,dy]=min(abs(lat-LAT));

if tr1<mean(diff(lon)) && tr2<mean(diff(lat))    
%     if ~exist([pathe 'ISAS13_CLIM_ann_STD_' var '.nc'],'file')
%         copyfile([pathe0 'ISAS13_CLIM_ann_STD_' var '.nc'],[pathe 'ISAS13_CLIM_ann_STD_' var '.nc']);
%     end
%     nc=netcdf.open([pathe 'ISAS13_CLIM_ann_STD_' var '.nc'],'nowrite');
     varid=netcdf.inqVarID(ncid,var);
    [varname,xtype,dimids]=netcdf.inqVar(ncid,varid);
    clear ii ij i
    for j=1:length(dimids)
        [dimname,dimlen]=netcdf.inqDim(ncid,dimids(j));
        i.(dimname).pos=dimids(j)+1;
        i.(dimname).len=dimlen;
        ii(j)=0;
        ij(j)=dimlen;
    end
    ii(i.longitude.pos)=dx-2;
    ii(i.latitude.pos)=dy-2;
    ij(i.longitude.pos)=3;
    ij(i.latitude.pos)=3;
%     stde=squeeze(netcdf.getVar(nc,varid,ii,ij,'double'));
%     stde=stde.*netcdf.getAtt(nc,varid,'scale_factor')+netcdf.getAtt(nc,varid,'add_offset');
%      netcdf.close(nc)
    
%     varid=netcdf.inqVarID(ncid,var);
    temp1=squeeze(netcdf.getVar(ncid,varid,ii,ij,'double'));
%     ok=temp1~=netcdf.getAtt(ncid,varid,'_FillValue');
    temp1(temp1==netcdf.getAtt(ncid,varid,'_FillValue'))=NaN;
%     temp1=temp1.*netcdf.getAtt(ncid,varid,'scale_factor')+netcdf.getAtt(ncid,varid,'add_offset');
    tmp1=reshape(temp1,9,[]);
    temp=mean(tmp1,1,'omitnan');
    stde=std(tmp1,1,'omitnan');
    
    varid=netcdf.inqVarID(ncid,'depth');
    depth1=squeeze(netcdf.getVar(ncid,varid,'double'));
    pres=gsw_p_from_z(-depth1,LAT);
    netcdf.close(ncid);
    
    if strcmp(var,'TEMP')
        ts=1;
    elseif strcmp(var,'PSAL')
        ts=2;
    else
%         var
        error('unknown prof type');
    end
    tok=temp(~isnan(temp));
    
    del=stde(~isnan(temp));
%     del(del<th(ts))=th(ts);    
    S.temp=[tok-del tok(end:-1:1)+del];
    pok=pres(~isnan(temp));
    S.pres=pok([1:end end:-1:1]);
else
    S.temp=[];
    S.pres=[];
end