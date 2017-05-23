clear 
tnpd
path1='e:\rapps\argo_dm\pres\techfiles'; %where all techfiles are
cd(path1)
donthave=[];
%if apex
d=dir('*_tech.nc');
for i=1:length(d)
    nc=netcdf(d(i).name,'r');
    names=lower(nc{'TECHNICAL_PARAMETER_NAME'}(:));
    if size(names,2)>40
        ok=strmatch(lower('PRES_SurfaceOffsetTruncatedPlus5dbar_dBAR'),names(:,1:41));
        if numel(ok)>0
            values=nc{'TECHNICAL_PARAMETER_VALUE'}(:);
            lok=length(ok);
            pres=nan(lok,1);
            for j=1:lok
                pres(j)=str2num(values(ok(j),:));
                ncclose all
            end
            performpresdmqc;
        else
            donthave=[donthave i];
        end
    else
        donthave=[donthave i];
    end
end