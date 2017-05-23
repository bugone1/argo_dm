%function checkincomefiles.m
%Make sure there isn't a coexistence of R and D files with same float number and cycle
local_config=load_configuration('local_WJO.txt');
ALLFiles = dir([local_config.NEW '*.nc']);
allnames=lower(char(ALLFiles.name));
[sorted,index]=sortrows(allnames(:,2:end));
ok=find(sum(abs(diff(sorted(:,2:end),1,1)),2)==0);
fid=fopen('report.csv','w');
for i=1:length(ok)
    fprintf(fid,[deblank(allnames(index(ok(i)),:)) ',' deblank(allnames(index(ok(i)+1),:)) 13 10])
    if allnames(index(ok(i)),1)=='r'
        system(['move ' local_config.NEW allnames(index(ok(i)),:) ' ' local_config.DNP allnames(index(ok(i)),:)]);
    else
        system(['move ' local_config.NEW allnames(index(ok(i)+1),:) ' ' local_config.DNP allnames(index(ok(i)+1),:)]);
    end
end
fclose(fid)


clear j
a=dir([local_config.NEW 'r*.nc']);
for i=1:length(a)
    [i length(a)]
    try
        nc=netcdf.open([local_config.NEW a(i).name],'NOWRITE');
        psaladjusted=netcdf.getVar(nc,netcdf.inqVarID(nc,'PSAL_ADJUSTED'));
        if ~isempty(psaladjusted)
            psaladjusted(psaladjusted==99999)=nan;
            j(i)=nansum(abs(psaladjusted));
        end 
        r(i)=netcdf.getVar(nc,netcdf.inqVarID(nc,'DATA_MODE'));
        netcdf.close(nc);
    catch
        j(i)=nan;
    end
end
save rfiles j r a
ok=find(j>0 & r=='R');
for i=1:length(ok)
        nc=netcdf.open([local_config.NEW a(ok(i)).name],'NOWRITE');
        psaladjusted=netcdf.getVar(nc,netcdf.inqVarID(nc,'PSAL_ADJUSTED'));
        psal=netcdf.getVar(nc,netcdf.inqVarID(nc,'PSAL'));
        dif(i)=sum(abs(psal-psaladjusted));
        netcdf.close(nc);
end
    
clear j r a
a=dir([local_config.NEW 'd*.nc']);
for i=1:length(a)
    [i length(a)]
    nc=netcdf.open([local_config.NEW a(i).name],'NOWRITE');
    psalqc=netcdf.getVar(nc,netcdf.inqVarID(nc,'PSAL_QC'));
    psaladjusted=netcdf.getVar(nc,netcdf.inqVarID(nc,'PSAL_ADJUSTED'));
    netcdf.close(nc);
    if ~isempty(psalqc)
        r(i)=char(min(psalqc));   
    else
        r(i)=nan;
    end
    if ~isempty(psaladjusted)
        psaladjusted(psaladjusted==99999)=nan;
        j(i)=nansum(abs(psaladjusted));
    else
        j(i)=nan;
    end 
end

save dfiles j r a