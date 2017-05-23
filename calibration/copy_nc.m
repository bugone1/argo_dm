function resize_dimension(ncid_in,ndimname,ndimleng,varnames)
[ndims,nvars,ngatts,unlimdimid]=netcdf.inq(ncid_in);
ncid_out=netcdf.open('temp.nc','WRITE')
dimid=-1;
for i=1:length(ndims)
    [dimname,dimlen]=netcdf.inqDim(ncid_in,i-1);
    if strcmp(dimname,ndimname)
        netcdf.defDim(nc,dimname,ndimlen);
        dimid=i-1;
    else
        netcdf.defDim(nc,dimname,dimlen);
    end
end

if dimid>=0
    for j=1:nvars
        [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_in,varid);
        data = netcdf.getVar(ncid_in,varid);        
        if ~isempty(strmatch(varname,varnames,'exact'))
            ok=find(dimids==dimid);
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
            else error('Unknown case');
            end            
            varid_out = netcdf.defVar(ncid_out,varname,xtype,dimids);
            netcdf.putVar(ncid_out,varid_out,data);
        end        
        for i=1:natts
            attname = netcdf.inqAttName(ncid,varid,i-1);
            netcdf.copyAtt(ncid_in,varid_in,attname,ncid_out,varid_out);
        end        
    end
    for i=1:ngatts
        attname = netcdf.inqAttName(ncid,'NC_GLOBAL',i-1);
        netcdf.copyAtt(ncid_in,'NC_GLOBAL',attname,ncid_out,'NC_GLOBAL');
    end
end     