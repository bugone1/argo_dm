%NOVEMBER 2009
%This was created to fix a problem signaled by John Gilson
lo_system_configuration = load_configuration('CONFIG_WJO.TXT'); %Decide whether you use WJO OR OW
local_config=load_configuration('local_WJO.txt');%Decide whether you use WJO OR OW


k=dir([local_config.DATA 'ingested' filesep '*509_029.nc']);
i=1;
f=netcdf([local_config.DATA 'ingested' filesep k(i).name],'r');
z=round(f{'TEMP'}(:)*100)/100;
ok4=z>=279 & z<=1349.1;
ok3=(z>=1399.4 & z<=1599.3) | z==998.3 | z==19.9 | z==359.3 | z==349.1;
qct=f{'TEMP_QC'}(:);
qct(ok4)='4';
qct(ok3)='3';
qcs=f{'PSAL_QC'}(:);
qcs(ok4)='4';
qcs(ok3)='3';
ncclose

copyfile([local_config.DATA 'ingested' filesep k(i).name],[local_config.OUT 'changed/' filesep k(i).name]) %create the new copy of the netCDF file
f = netcdf([local_config.OUT 'changed/' filesep k(i).name],'write'); % if you don't open f in write mode, you can't modify the dimensions.
if isempty(f), error('## Bad output file open operation.'), end;
nowe=now;temptime=nowe+(heuredete(nowe)/24);
DATE_UPDATE=sprintf('%4.4i%2.2i%2.2i%2.2i%2.2i%2.2i',round(datevec(temptime)));
f{'TEMP_QC'}(:)=qct;
f{'TEMP_ADJUSTED_QC'}(:)=qct;
tem=f{'TEMP_ADJUSTED'}(:);
tem(qct=='4')=99999;
f{'TEMP_ADJUSTED'}(:)=tem;
f{'PSAL_QC'}(:)=qcs;
f{'PSAL_ADJUSTED_QC'}(:)=qcs;
tem=f{'PSAL_ADJUSTED'}(:);
tem(qcs=='4')=99999;
f{'PSAL_ADJUSTED'}(:)=tem;
f{'DATE_UPDATE'}(:)=DATE_UPDATE;
f{'DATA_MODE'}(:)='D';

f{'TEMP_QC'}(:)=qct;
f{'TEMP_ADJUSTED_QC'}(:)=qct;
tem=f{'TEMP_ADJUSTED'}(:);
tem(qct=='4')=99999;
f{'TEMP_ADJUSTED'}(:)=tem;

f{'PSAL_QC'}(:)=qcs;
f{'PSAL_ADJUSTED_QC'}(:)=qcs;
tem=f{'PSAL_ADJUSTED'}(:);
tem(qcs=='4')=99999;
f{'PSAL_ADJUSTED'}(:)=tem;


parameter=f{'PARAMETER'}(:);
for k=1:size(parameter,2)
    shortname=squeeze(parameter(end,k))';
    adjornot='_ADJUSTED';
    if isempty(f{[shortname '_ADJUSTED']})
        adjornot='';
    end
    bigname=[shortname adjornot '_QC'];
    one=f{bigname}(:)=='1' | f{bigname}(:)=='2';
    percgood=sum(one)/length(one);
    if percgood==1                 profparmqc='A';
    elseif percgood>=.75            profparmqc='B';
    elseif percgood>=.5            profparmqc='C';
    elseif percgood>=.25          profparmqc='D';
    elseif percgood>0          profparmqc='E';
    else profparmqc='F';
    end
    f{['PROFILE_' shortname '_QC']}(:)=profparmqc;
end


N_HIST=f('N_HISTORY');

qctests=squeeze(f{'HISTORY_QCTEST'}(:));
actions=squeeze(f{'HISTORY_ACTION'}(:));

[tr,i]=intersect(actions,'QCP$','rows');
f{'HISTORY_DATE'}(i,1,:)=netstr(DATE_UPDATE,14);
f{'HISTORY_QCTEST'}(i,1,:)=netstr(dec2hex(bin2dec(char(or(dec2bin(hex2dec(deblank(qctests(i,:))),30)-48,dec2bin(hex2dec('020000'),30)-48)+48))),16);

[tr,j]=intersect(actions,'QCF$','rows');
f{'HISTORY_QCTEST'}(j,1,:)=netstr(dec2hex(bin2dec(char(or(dec2bin(hex2dec(deblank(qctests(j,:))),30)-48,dec2bin(hex2dec('020000'),30)-48)+48))),16);
f{'HISTORY_DATE'}(j,1,:)=netstr(DATE_UPDATE,14);

i=N_HIST(:)+1;
f{'HISTORY_DATE'}(i,1,:)=netstr(DATE_UPDATE,14);
f{'HISTORY_ACTION'}(i,1,:)=netstr('QC',4);
f{'HISTORY_STEP'}(i,1,:)=netstr('ARSQ',4);
f{'HISTORY_INSTITUTION'}(i,1,:)=netstr('ME',4);
f{'HISTORY_PARAMETER'}(i,1,:)=netstr('TEMP',16);

i=N_HIST(:)+1;
f{'HISTORY_DATE'}(i,1,:)=netstr(DATE_UPDATE,14);
f{'HISTORY_ACTION'}(i,1,:)=netstr('CF',4);
f{'HISTORY_STEP'}(i,1,:)=netstr('ARSQ',4);
f{'HISTORY_INSTITUTION'}(i,1,:)=netstr('ME',4);
f{'HISTORY_PARAMETER'}(i,1,:)=netstr('TEMP',16);
f{'HISTORY_START_PRES'}(i,1,:)=19.9;
f{'HISTORY_STOP_PRES'}(i,1,:)=1599.3;
f{'HISTORY_PREVIOUS_VALUE'}(i,1,:)=1;

i=N_HIST(:)+1;
f{'HISTORY_DATE'}(i,1,:)=netstr(DATE_UPDATE,14);
f{'HISTORY_ACTION'}(i,1,:)=netstr('UP',4);
f{'HISTORY_STEP'}(i,1,:)=netstr('ARDU',4);
f{'HISTORY_INSTITUTION'}(i,1,:)=netstr('ME',4);
ncclose







if 0
    %1-plotting
    close all
    k=dir([local_config.DATA 'ingested' filesep '*509_02*.f']);
    col='rbgmy';
    for i=1:length(k)
        f=netcdf([local_config.DATA 'ingested' filesep k(i).name],'r');
        tem=f{'PSAL_ADJUSTED'}(:);
        tem(tem==99999)=nan;
        z=sw_ptmp(f{'PSAL_ADJUSTED'}(:),f{'TEMP'}(:),f{'PRES'}(:),0);
        diff=abs(z-3.3);
        [pres(i),ok]=min(diff);
        psal(i)=sw_cndr(tem(ok),f{'TEMP'}(ok),f{'PRES'}(ok));
        figure(1)
        plot(f{'PRES'}(:),tem,'k')
        figure(2)
        plot(f{'TEMP'}(:),f{'PSAL'}(:),'k')
        figure(3)
        plot(f{'PRES'}(:),f{'TEMP'},'k')
        fclose
    end



    %2-Enforce special error message for this case
    k=dir([local_config.OUT 'changed' filesep '*234*.f']);
    for i=1:length(k)
        f=netcdf([local_config.OUT 'changed' filesep k(i).name],'w');
        ok=f{'PSAL_QC'}(:)~='4';
        tem=f{'PSAL_ADJUSTED_QC'}(:);
        tem(ok)='3';
        ok=f{'PSAL_ADJUSTED'}(:)==99999;
        tem(ok)='4';
        f{'PSAL_ADJUSTED_QC'}(:)=tem;
        f{'PSAL_QC'}(:)=tem;
        ok=tem=='4';
        tem=f{'PSAL_ADJUSTED'}(:);
        tem(ok)=99999;
        f{'PSAL_ADJUSTED'}(:)=tem;
        tem=f{'PSAL_ADJUSTED_ERROR'}(:);
        newerr=f{'PRES_ADJUSTED'}(:)*(-0.518+0.144)/2000+.518;
        f{'PSAL_ADJUSTED_ERROR'}(:)=tem;
        f{'SCIENTIFIC_CALIB_COMMENT'}(1,end,3,:)=netstr(['Correction applied to conductivity was based on theta=3.3ºC but is the result of an abrupt change. The correction is suspiciously high. Error on adjusted salinity has been assessed by a acomparison with nearby profiles. Interpret with caution.'],256);
        fclose
    end
end