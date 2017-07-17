function copy_nc_redim(input,output,redimname,num)
% COPY_NC_REDIM - Copy a NetCDF file, changing a dimension in the process
%   USAGE: copy_nc_redim(input,output,redimname,num)
%   INPUTS:
%       input - Input NetCDF file name
%       output - Output NetCDF file name
%       redimname - Name of the dimension to change
%       num - Number by which to increase the dimension or 'unlimited' to
%           make it unlimited.
%   VERSION HISTORY:
%       Before May 2017: Changes not tracked
%       12 July 2017, Isabelle Gaboury: Added the 'unlimited' option for
%           num

% Special case for making a variable unlimited in size
if ischar(num)
    if strcmp(num,'unlimited'), make_unlim = 1;
    else error('num must be either numeric or ''unlimited''');
    end
else make_unlim = 0;
end

%Creates a new file while increasing the dimension of "redimname" by "num"
f1=netcdf.open(input,'NOWRITE');
f2=netcdf.create(output,'CLOBBER');
[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(f1);
for i=1:ndims
    dimid=i-1;
    [dimname,dimlen]=netcdf.inqDim(f1,dimid);
    if strcmp(dimname,redimname)
        if make_unlim
            if unlimdimid>-1 && dimid~=unlimdimid
                error('An unlimited dimension is already specified in the NetCDF file');
            else unlimdimid = dimid;
            end
            i_redim=-1;
        else
        dimlen=dimlen+num;
        i_redim=dimid;
    end
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