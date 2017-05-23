%REVIEW_CHANGED
%A)Checks CHANGED directory to see whether all files have 'PARAMETER' field
%if not, then assign PRES, TEMP, PSAL, DOXY andTEMP_DOXY
%B)Checks if all files have less than 5 SCIENTIFIC_CALIB_COMMENT
%C)Extract SCIENTIFIC_CALIB_COEFFICIENT and store it in coeff (3D)
%D)If PARAMETER field is empty, fill it
%E)Adjusts PROFILE_TEMP_QC or PROFILE_PSAL_QC flags

clear
clc
varnames=char('PRES','TEMP','PSAL','DOXY','TEMP_DOXY');
a=dir('E:\RApps\argo_DM\Calibration\output\changed\*.nc');
floats=char(a.name);floats=floats(:,2:8);
ufloats=unique(floats,'rows');
coeff=nan(size(ufloats,1),200,2);
for i=1:length(a)
    [tr,I]=intersect(ufloats,a(i).name(2:8),'rows');
    J=str2num(a(i).name(10:12));
    ncclose;
    clc
    size(coeff)
    nc=netcdf(['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name],'read');
    a(i).name
    if size(nc{'PARAMETER'},2)<1
        stop
    end
    if size(nc{'SCIENTIFIC_CALIB_COMMENT'},2)>5
        stop
    end
    for j=1:size(nc{'PARAMETER'},2)
        comm=deblank(nc{'SCIENTIFIC_CALIB_COEFFICIENT'}(end,j,3,:)');
        if isempty(comm)
            coeff(I,J,j)=0;
        else
            keyw='conductivity is';
            if isempty(findstr(lower(comm),keyw))
                keyw='r=';
            end
            virgule=find(comm==',');
            if isempty(virgule)
                virgule=length(comm);
            end
            coeff(I,J,j)=str2num(comm((findstr(lower(comm),keyw)+length(keyw):virgule-1)));
        end
        parameter=nc{'PARAMETER'}(:,j,:,:);
        if all(parameter==32)
            close(nc);
            copyfile(['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name],'temp.nc');
            pc=netcdf('temp.nc','write');
            for k=1:size(nc{'PARAMETER'},3)
                pc{'PARAMETER'}(1,j,k,1:16)=netstr(deblank(varnames(k,:)),16);
            end
            close(pc);
            copyfile('temp.nc',['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name]);
            delete('temp.nc');
            nc=netcdf(['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name],'read');
        end
        nc{'SCIENTIFIC_CALIB_EQUATION'}(:,j,3,:)'
        nc{'SCIENTIFIC_CALIB_COEFFICIENT'}(:,j,3,:)'
        comment=nc{'SCIENTIFIC_CALIB_COMMENT'}(:,j,3,:)'
        if ~isempty(strfind(comment,'1 breakpoint'))
            newcomment=['Correction factor adjusted from visual inspection of DMQC software diagnostics. '  comment(findstr(comment,'RMS'):end)];
            linearinterpolat=findstr(newcomment,'linear interpolat');
            newstr='visual adjustment';
            newcomment(linearinterpolat+[0:length(newstr)-1])=newstr;
            newcomment=newcomment([1:linearinterpolat+length(newstr)-1 linearinterpolat+length(newstr)+3:end]);
            close(nc)
            copyfile(['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name],'temp.nc');
            pc=netcdf('temp.nc','write');
            pc{'SCIENTIFIC_CALIB_COMMENT'}(:,j,3,:)=' ';
            pc{'SCIENTIFIC_CALIB_COMMENT'}(:,j,3,1:length(newcomment))=newcomment';
            close(pc)
            copyfile('temp.nc',['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name]);
            delete('temp.nc');
            nc=netcdf(['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name],'read');
        end
    end
    for k=1:size(parameter,1)
        shortname=parameter(k,1:4);
        adjornot='_ADJUSTED';
        if isempty(nc{[shortname '_ADJUSTED']})     adjornot='';
        end
        bigname=[shortname adjornot '_QC'];
        one=nc{bigname}(:)=='1' | nc{bigname}(:)=='2';
        percgood=sum(one)/length(one);
        if ~isempty(one)
            if percgood==1                 profparmqc='A';
            elseif percgood>=.75            profparmqc='B';
            elseif percgood>=.5            profparmqc='C';
            elseif percgood>=.25          profparmqc='D';
            elseif percgood>0          profparmqc='E';
            else profparmqc='F';
            end
        else
            profparmqc=' ';
        end
        if nc{['PROFILE_' shortname '_QC']}(:)~=profparmqc
            close(nc)
            copyfile(['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name],'temp.nc');
            pc=netcdf('temp.nc','write');
            nc{['PROFILE_' shortname '_QC']}(:)=profparmqc;
            close(pc)
            copyfile('temp.nc',['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name]);
            delete('temp.nc');
            nc=netcdf(['E:\RApps\argo_DM\Calibration\output\changed\' a(i).name],'read');
        end
    end
end
save coeff coeff ufloats