%REVIEW_WORK
%A)Checks UNCHANGED directory to see whether all files have 'PARAMETER' field;
%if not, then assign PRES, TEMP, PSAL, DOXY andTEMP_DOXY
%B)Adjusts PROFILE_TEMP_QC or PROFILE_PSAL_QC flags
%C)Checks if any file has 'SCIENTIFIC_CALIB_COMMENT' field with "linear
%fit" comment; if so, replace for "No salinity adjustment was judged
%needed". This is the unchanged directory !

clear
clc
varnames=char('PRES','TEMP','PSAL','DOXY','TEMP_DOXY');
a=dir('E:\RApps\argo_DM\Calibration\output\unchanged\*.nc');
for i=1:length(a)
    ncclose;
    %    clc
    nc=netcdf(['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name],'read');
    a(i).name
    if size(nc{'PARAMETER'},2)<1
        stop
    end
    if size(nc{'SCIENTIFIC_CALIB_COMMENT'},2)>5
        stop
    end
    for j=1:size(nc{'PARAMETER'},2)

        parameter=nc{'PARAMETER'}(:,j,:,:);
        if all(parameter==32)
            close(nc);
            copyfile(['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name],'temp.nc');
            pc=netcdf('temp.nc','write');
            for k=1:size(nc{'PARAMETER'},3)
                pc{'PARAMETER'}(1,j,k,1:16)=netstr(deblank(varnames(k,:)),16);
            end
            close(pc);
            copyfile('temp.nc',['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name]);
            delete('temp.nc');
            nc=netcdf(['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name],'read');
        end

        comment=nc{'SCIENTIFIC_CALIB_COMMENT'}(:,j,3,:)';
        if ~isempty(findstr(comment,'Visual piecewise linear fit done upon inspection of profiles'))
            close(nc)
            copyfile(['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name],'temp.nc');
            pc=netcdf('temp.nc','write');
            pc{'SCIENTIFIC_CALIB_COMMENT'}(:,j,3,:)=netstr('No salinity adjustment was judged needed after visual inspection of DMQC software diagnostic.',256);
            close(pc)
            copyfile('temp.nc',['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name]);
            delete('temp.nc');
            nc=netcdf(['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name],'read');
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
        if length(one)>0
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
        [nc{['PROFILE_' shortname '_QC']}(:) profparmqc]
        if nc{['PROFILE_' shortname '_QC']}(:)~=profparmqc
            close(nc)
            copyfile(['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name],'temp.nc');
            pc=netcdf('temp.nc','write');
            nc{['PROFILE_' shortname '_QC']}(:)=profparmqc;
            close(pc)
            copyfile('temp.nc',['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name]);
            delete('temp.nc');
            nc=netcdf(['E:\RApps\argo_DM\Calibration\output\unchanged\' a(i).name],'read');
        end
    end
end