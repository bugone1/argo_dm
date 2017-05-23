function checkfilesfeb2009
ncclose
pa='E:\RApps\argo_DM\Calibration\output\unchanged\';
dire=dir([pa '*.nc']);
for i=1:length(dire)
    subcheckfilesfeb2009([pa dire(i).name])
    system(['ren temp.nc ' dire(i).name])
end

function subcheckfilesfeb2009(ingested_flnm)
ok=find(ingested_flnm=='\');
pa='E:\RApps\argo_DM\Calibration\data\ingested\';
dire=dir([pa '*' ingested_flnm(ok(end)+2:end)]);
nc=netcdf([pa dire(1).name],'read');
output_flnm='temp.nc';
varnames=char('PRES','TEMP','PSAL','DOXY','TEMP_DOXY');
ncclose
copyfile(ingested_flnm,output_flnm) %create the new copy of the netCDF file
f = netcdf(output_flnm,'write'); % if you don't open f in write mode, you can't modify the dimensions.
if isempty(f), error('## Bad output file open operation.'), end;

wmo=f{'WMO_INST_TYPE'}(:);
sbe=sum(str2num(wmo')==[841 846 851 856])>0;
adj.PRES=f{'PRES_ADJUSTED'}(:);
PRES=f{'PRES'}(:);
ok=isnan(PRES); adj.PRES_QC(ok)='4';adj.PRES(ok) = 99999;adj.PRES_ERROR=ones(size(adj.PRES))*99999;
if  sbe
    adj.PRES_ERROR=2.4;
else    adj.PRES_ERROR=99999;
end
f{'PRES_ADJUSTED_ERROR'}(:)=adj.PRES_ERROR;

parameter=f{'PARAMETER'}(:,:,:);
for j=1:size(parameter,1)
    for i=1:size(parameter,2)
        if all(parameter(j,i,:)==32) %Fill parameter field
            fid=fopen('foranh.txt','a');
            ingested_flnm(ingested_flnm=='\' | ingested_flnm=='/')=' ';
            fprintf(fid,[ingested_flnm 13 10]);
            fclose(fid)
            f{'PARAMETER'}(1,j,i,1:16)=netstr(deblank(varnames(i,:)),16);
        end
    end
end
for i=1:size(parameter,2)
    for j=1:size(parameter,1)
        shortname=squeeze(parameter(end,i,1:4))';
        if strcmp('PRES',shortname) || strcmp('TEMP',shortname)
            f{'SCIENTIFIC_CALIB_EQUATION'}(1,j,i,:)=nc{'SCIENTIFIC_CALIB_EQUATION'}(1,1,i,:);
            f{'SCIENTIFIC_CALIB_COMMENT'}(1,j,i,:)=nc{'SCIENTIFIC_CALIB_COMMENT'}(1,1,i,:);
        end
    end
end
ncclose