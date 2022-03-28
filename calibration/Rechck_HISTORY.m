function Rechck_HISTORY(flnm,floatNum)
     Unlim_name='N_HISTORY';
% file='C:/Users/maz/Desktop/MEDS Project/argo_dm/calibration/data/4901820\D4901820_001.nc';
     ncid=netcdf.open(flnm.input,'NOWRITE'); 
     [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid);
     if unlimdimid>0
         netcdf.close(ncid);
         return;
     else
        fname2=char(round(rand(1,15)*26+65));
        ncid_out=netcdf.create(fname2,'WRITE');
         dimid=-1;
        for i=1:ndims
            [dimname,dimlen]=netcdf.inqDim(ncid,i-1);
            if strcmp(dimname,Unlim_name)
                 dimid=i-1;
%                 if dimid==unlimdimid
                    netcdf.defDim(ncid_out,dimname,netcdf.getConstant('NC_UNLIMITED'));
%                 else
%                     netcdf.defDim(ncid_out,dimname,ndimleng);
%                 end
            else
                netcdf.defDim(ncid_out,dimname,dimlen);
            end
        end

        for j=1:nvars
            varid=j-1;
            [varname,xtype,dimids] = netcdf.inqVar(ncid,varid);
            netcdf.defVar(ncid_out,varname,xtype,dimids);
            [tr,tr,dimids,natts] = netcdf.inqVar(ncid,varid);
            for i=1:natts
                attname = netcdf.inqAttName(ncid,varid,i-1);
                netcdf.copyAtt(ncid,varid,attname,ncid_out,varid);
            end
        end
        for i=1:ngatts
            val=netcdf.getConstant('NC_GLOBAL');
            attname = netcdf.inqAttName(ncid,val,i-1);
            netcdf.copyAtt(ncid,val,attname,ncid_out,val);
        end
        netcdf.endDef(ncid_out);

        for j=1:nvars    
            varid=j-1;
            data = netcdf.getVar(ncid,varid);
             [varname,xtype,dimids,unlimdimids] = netcdf.inqVar(ncid,varid);
             ok=find(dimids==dimid);
%             if isempty(ok)
%                 ok=0;
%             end
             ndims=length(dimids);
%             if ndims==1 && ok==1
%                 data=data(1:ndimleng);
%             elseif ndims==2 && ok==1
%                 data=data(1:ndimleng,:);
%             elseif ndims==2 && ok==2
%                 data=data(:,1:ndimleng);
%             elseif ndims==3 && ok==1
%                 data=data(1:ndimleng,:,:);
%             elseif ndims==3 && ok==2
%                 data=data(:,1:ndimleng,:);
%             elseif ndims==3 && ok==3
%                 data=data(:,:,1:ndimleng);
%             elseif ok~=0
%                 error('Unknown case');
%             end

             if (~isempty(ok)&&ndims==3)
                    netcdf.putVar(ncid_out,varid,[0 0 0],size(data),data);                 
             elseif(~isempty(ok)&&ndims==2)
                     netcdf.putVar(ncid_out,varid,[0 0],size(data),data); 
             else
                     netcdf.putVar(ncid_out,varid,data);
             end
        end
        netcdf.close(ncid);
        netcdf.close(ncid_out);
         copyfile(fname2,flnm.input,'f');
         delete(fname2);
     end
end