function copy_nc_redim(input,output,redimname,num)
%Creates a new file while increasing the dimension of "redimname" by "num"
f1=netcdf.open(input,'NOWRITE');
f2=netcdf.create(output,'CLOBBER');
[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(f1);
for i=1:ndims
    dimid=i-1;
    [dimname,dimlen]=netcdf.inqDim(f1,dimid);
    if strcmp(dimname,redimname)
        dimlen=dimlen+num;
        i_redim=dimid;
    end
    if dimid==unlimdimid
        nunlimdimid=dimlen;
        dimlen=netcdf.getConstant('NC_UNLIMITED');
    end
    netcdf.defDim(f2,dimname,dimlen);
end
for i=1:ngatts
    varid=netcdf.getConstant('GLOBAL');
    netcdf.copyAtt(f1,varid,netcdf.inqAttName(f1,varid,i-1),f2,varid);
end
for i=1:nvars
    varid=i-1;
    [varname,xtype,dimids,natts]=netcdf.inqVar(f1,varid);
    netcdf.defVar(f2,varname,xtype,dimids);
    for j=1:natts
        netcdf.copyAtt(f1,varid,netcdf.inqAttName(f1,varid,j-1),f2,varid);
    end
end
netcdf.endDef(f2);
for i=1:nvars
    varid=i-1;
    [varname,xtype,dimids,natts]=netcdf.inqVar(f2,varid);
    index=find(dimids==i_redim | dimids==unlimdimid);
    if isempty(index)
        netcdf.putVar(f2,varid,netcdf.getVar(f1,varid));
    else
        clear di dj
        for j=1:length(dimids)
            [tr,di(j)]=netcdf.inqDim(f2,dimids(j));
            dj(j)=1;
        end
        di(index)=1;
        if any(dimids==i_redim)
            ende=dj(j)+num;
        else
            ende=nunlimdimid;
        end
        for j=1:ende
            dj(index)=j;
            tempo=netcdf.getVar(f1,varid,dj-1,di);
            netcdf.putVar(f2,varid,dj-1,di,tempo);
        end
    end
end

netcdf.close(f1);
netcdf.close(f2);