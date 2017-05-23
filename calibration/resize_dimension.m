function resize_dimension(ndimname,ndimleng,fname1)
%function resize_dimension(ndimname,ndimleng,fname1)
%Copies a file while editing one dimension
%Crops all variables in the dimension which is being lowered
%Program not written for multi dimension or augmenting dimensions but could
%be modified to do so
ncid_in=netcdf.open(fname1,'NOWRITE');
fname2=char(round(rand(1,15)*26+65));
ncid_out=netcdf.create(fname2,'WRITE');
[ndims,nvars,ngatts]=netcdf.inq(ncid_in);
dimid=-1;
for i=1:ndims
    [dimname,dimlen]=netcdf.inqDim(ncid_in,i-1);
    if strcmp(dimname,ndimname)
        netcdf.defDim(ncid_out,dimname,ndimleng);
        dimid=i-1;
    else
        netcdf.defDim(ncid_out,dimname,dimlen);
    end
end

for j=1:nvars
    varid=j-1;
    [varname,xtype,dimids] = netcdf.inqVar(ncid_in,varid);
    netcdf.defVar(ncid_out,varname,xtype,dimids);
    [tr,tr,dimids,natts] = netcdf.inqVar(ncid_in,varid);
    for i=1:natts
        attname = netcdf.inqAttName(ncid_in,varid,i-1);
        netcdf.copyAtt(ncid_in,varid,attname,ncid_out,varid);
    end
end
for i=1:ngatts
    val=netcdf.getConstant('NC_GLOBAL');
    attname = netcdf.inqAttName(ncid_in,val,i-1);
    netcdf.copyAtt(ncid_in,val,attname,ncid_out,val);
end
netcdf.endDef(ncid_out);

for j=1:nvars    
    varid=j-1;
    data = netcdf.getVar(ncid_in,varid);
    [varname,xtype,dimids] = netcdf.inqVar(ncid_in,varid);
    ok=find(dimids==dimid);
    if isempty(ok)
        ok=0;
    end
    ndims=length(dimids);
    if ndims==1 && ok==1
        data=data(1:ndimleng);
    elseif ndims==2 && ok==1
        data=data(1:ndimleng,:);
    elseif ndims==2 && ok==2
        data=data(:,1:ndimleng);
    elseif ndims==3 && ok==1
        data=data(1:ndimleng,:,:);
    elseif ndims==3 && ok==2
        data=data(:,1:ndimleng,:);
    elseif ndims==3 && ok==3
        data=data(:,:,1:ndimleng);
    elseif ok~=0
        error('Unknown case');
    end
    netcdf.putVar(ncid_out,varid,data);
end
netcdf.close(ncid_in);
netcdf.close(ncid_out);
copyfile(fname2,fname1);
delete(fname2);