function RESULT = rewrite_nc(ingested_flnm,output_flnm,PRES,TEMP,CAL_SAL,CAL_SAL_FLAG,cal_SAL_err,condslope,condslope_err,CalDate,MIN_MAP_ERR,mode,gencomment,ocondslope,rawflags,presscorrect)

varnames=char('PRES','TEMP','PSAL','DOXY','TEMP_DOXY');
[trash,indexpsal]=intersect(varnames,'PSAL','rows');
ncclose
copyfile(ingested_flnm,output_flnm) %create the new copy of the netCDF file
f = netcdf(output_flnm,'write'); % if you don't open f in write mode, you can't modify the dimensions.
if isempty(f), error('## Bad output file open operation.'), end;

nowe=now;temptime=nowe+(heuredete(nowe)/24);
DATE_UPDATE=sprintf('%4.4i%2.2i%2.2i%2.2i%2.2i%2.2i',round(datevec(temptime)));
DATE_CAL=sprintf('%4.4i%2.2i%2.2i%2.2i%2.2i%2.2i',round(datevec(CalDate)));

VERSION=eval(f{'FORMAT_VERSION'}(:));
if VERSION==2.2;    PAR_LEN=16;
else    PAR_LEN=4;
end

a=f('N_LEVELS'); %necessary step if re-dimensioning: Feb. 2, 2004
levels=a(:);
di=levels-length(PRES);
if di>0 %Lenghten vectors if there are more levels
    PRES=[PRES; nan(di,1)];        TEMP=[TEMP; nan(di,1)];            CAL_SAL=[CAL_SAL; nan(di,1)];
    CAL_SAL_FLAG=[CAL_SAL_FLAG; nan(di,1)]; cal_SAL_err=[cal_SAL_err ;nan(di,1)];
end
PRES=PRES(1:levels); TEMP=TEMP(1:levels); CAL_SAL=CAL_SAL(1:levels); CAL_SAL_FLAG=CAL_SAL_FLAG(1:levels); cal_SAL_err=cal_SAL_err(1:levels);

%carry over raw flags


for i=1:size(varnames,1)
    varname=deblank(varnames(i,:));
    adj.(varname)=f{[varname '_ADJUSTED']}(:);
    adj.([varname '_QC'])=f{[varname '_ADJUSTED_QC']}(:);
end
if  ~isnan(condslope) % QC flag is kept as such, except 3 becomes 4 (DMQC-3)
    adj.PSAL_QC(CAL_SAL_FLAG=='3')='3';
    adj.PSAL=CAL_SAL;
else
    adj.PSAL_QC(adj.PSAL_QC=='3')='4';
end
ok=CAL_SAL_FLAG=='4';adj.PSAL_QC(ok)='4';adj.PSAL(ok)= 99999;
ok=isnan(TEMP);adj.TEMP_QC(ok)='4';adj.TEMP(ok) = 99999;adj.TEMP_ERROR=ones(size(adj.TEMP))*99999;

wmo=f{'WMO_INST_TYPE'}(:);
sbe=sum(str2num(wmo')==[841 846 851 856])>0;
if sbe&& ~all(adj.PRES==99999)    adj.TEMP_ERROR=.002; %wmo codes for floats with sbe sensors
else    adj.TEMP_ERROR=99999;
end
ok=isnan(PRES); adj.PRES_QC(ok)='4';adj.PRES(ok) = 99999;adj.PRES_ERROR=ones(size(adj.PRES))*99999;
if  sbe
    adj.PRES_ERROR=2.4;
else    adj.PRES_ERROR=99999;
end

for i=1:size(varnames,1)
    varname=deblank(varnames(i,:));
    f{[varname '_ADJUSTED']}(:)= adj.(varname); % Put these back into the net CDF file
    f{[varname '_ADJUSTED_QC']}(:)= adj.([varname '_QC']); % Put these back into the net CDF file
end

f{'TEMP_ADJUSTED_ERROR'}(:)=adj.TEMP_ERROR;
f{'PRES_ADJUSTED_ERROR'}(:)=adj.PRES_ERROR;

f{'DATE_UPDATE'}(:)=DATE_UPDATE;
f{'DATA_STATE_INDICATOR'}(:)=netstr('2C+',4);
if upper(mode)=='D';
    f{'DATA_MODE'}(:)='D';
elseif condslope~=1
    f{'DATA_MODE'}(:)='A';
else
    f{'DATA_MODE'}(:)='R';
end;
D = f('N_CALIB'); % increase the number of calibrations and fill new fields
if isempty(D)
    D(:)=1;
else    tem=D(:);    D(:)=tem+1;
end

for j=1:size(f{'PARAMETER'},2)
    for i=1:size(f{'PARAMETER'},3)
        parameter=f{'PARAMETER'}(1,j,i,:);
        if all(parameter==32) %Fill parameter field
            fid=fopen('foranh.txt','a');
            ingested_flnm(ingested_flnm=='\' | ingested_flnm=='/')=' ';
            fprintf(fid,[ingested_flnm 13 10]);
            fclose(fid)
            f{'PARAMETER'}(1,j,i,:)=netstr(deblank(varnames(i,:)),size(f{'PARAMETER'},4));
        end
    end
end

parameter=f{'PARAMETER'}(:);
for i=1:size(parameter,2)
    index=strmatch(squeeze(parameter(end,i,1:9))',varnames(:,1:9),'exact');
    f{'PARAMETER'}(1,D(:),index,:)=netstr(parameter(end,i,:), PAR_LEN);
    if strcmp('PSAL',parameter)
        f{'SCIENTIFIC_CALIB_EQUATION'}(1,D(:),index,:)=netstr('PSAL_ADJUSTED is calculated from a conductivity multiplicative adjustment term r.', 256);
    elseif strcmp('TEMP',parameter)
        %if ~all(adj.(parameter)==99999)
        %            f{'SCIENTIFIC_CALIB_EQUATION'}(1,D(:),index,:)=netstr([parameter '_ADJUSTED=' parameter], 256);
        %            f{'SCIENTIFIC_CALIB_COMMENT'}(1,D(:),index,:)=netstr(['Calibration error is manufacturers specified ' parameter ' accuracy at time of lab calibration'], 256);
        %end
        f{'SCIENTIFIC_CALIB_EQUATION'}(1,D(:),index,:)=f{'SCIENTIFIC_CALIB_EQUATION'}(1,1,index,:);
        f{'SCIENTIFIC_CALIB_COMMENT'}(1,D(:),index,:)=f{'SCIENTIFIC_CALIB_COMMENT'}(1,1,index,:);
    elseif strcmp('PRES',parameter)
        f{'SCIENTIFIC_CALIB_EQUATION'}(1,D(:),index,:)=netstr('PRES_ADJUSTED(cycle)=PRES(cycle i)-PRES(cycle i+1)',256);
        f{'SCIENTIFIC_CALIB_COMMENT'}(1,D(:),index,:)=netstr(['PRES_ADJUSTED is calculated following the 3.2.1 procedure in the Argo Quality Control Manual version 2.4. No significant pressure drift was detected.' presscorrect.comment], 256);
    end
end
for k=1:size(parameter,2)
    shortname=squeeze(parameter(end,k,1:4))';
    adjornot='_ADJUSTED';
    if isempty(f{[shortname '_ADJUSTED']})
        adjornot='';
    end
    bigname=[shortname adjornot '_QC'];
    one=f{bigname}(:)=='1' | f{bigname}(:)=='2';
    nonqced=f{bigname}(:)=='0';
    percgood=sum(one)/length(one);
    percnon=sum(nonqced)/length(one);
    if percnon==1
        profparmqc=' ';
    else
        if percgood==1                 profparmqc='A';
        elseif percgood>=.75            profparmqc='B';
        elseif percgood>=.5            profparmqc='C';
        elseif percgood>=.25          profparmqc='D';
        elseif percgood>0          profparmqc='E';
        else profparmqc='F';
        end
    end
    f{['PROFILE_' shortname '_QC']}(:)=profparmqc;
    if percnon>0 && percgood>0
        error('Mixed of QCED/Non-QCED in same profile!')
    end
end
if (condslope/MIN_MAP_ERR/40)>100
    CAL_SAL_FLAG(:) = 4;
    f{'PROFILE_PSAL_QC'}(:)='B';
end
f{'PSAL_ADJUSTED_ERROR'}(:)=max(cal_SAL_err,.01); %DMQC3 : .01 is minimum error. When we compute the THERMAL_CELL_ERR, have to update this
f{'PRES_ADJUSTED_ERROR'}(:)=cal_SAL_err*0+2.4; %DMQC3 : 2.4-dbar is the recommended error to quote, with 2.4-dbar being the manufacturer quoted accuracy of the pressure sensor

N_HIST=f('N_HISTORY');
NEXT_REC=N_HIST(:)+1;
f{'HISTORY_DATE'}(NEXT_REC,1,:)=netstr(DATE_CAL,14);
f{'HISTORY_INSTITUTION'}(NEXT_REC,1,:)=netstr('ME', 4);
f{'HISTORY_PARAMETER'}(NEXT_REC,1,:)=netstr('PRES', PAR_LEN);
f{'HISTORY_REFERENCE'}(NEXT_REC,1,:)=netstr(['Argo QC manual v2.5'], 64);
f{'HISTORY_SOFTWARE'}(NEXT_REC,1,:)=netstr('none', 4);
f{'HISTORY_SOFTWARE_RELEASE'}(NEXT_REC,1,:)=netstr('none', 4);
f{'HISTORY_STEP'}(NEXT_REC,1,:)=netstr('ARSQ', 4);
f{'HISTORY_STEP_RELEASE'}(NEXT_REC,1,:)=netstr('OCT9', 4); %DEC3 MEANS DECEMBER, 2003 RELEASE OF ANNIE'S CODE AND DATABASE
[f{'HISTORY_START_PRESSURE'}(NEXT_REC,1),f{'HISTORY_STOP_PRESSURE'}(NEXT_REC,1),f{'HISTORY_PREVIOUS_VALUE'}(NEXT_REC,1)]=deal(99999.);

NEXT_REC=N_HIST(:)+1;
f{'HISTORY_DATE'}(NEXT_REC,1,:)=netstr(DATE_CAL,14);
f{'HISTORY_INSTITUTION'}(NEXT_REC,1,:)=netstr('ME', 4);
f{'HISTORY_PARAMETER'}(NEXT_REC,1,:)=netstr('PSAL', PAR_LEN);
f{'HISTORY_REFERENCE'}(NEXT_REC,1,:)=netstr(['Coriolis/V2010 WITH MIN_MAP_ERR = ' num2str(MIN_MAP_ERR)], 64);
f{'HISTORY_SOFTWARE'}(NEXT_REC,1,:)=netstr('WJO', 4);
f{'HISTORY_SOFTWARE_RELEASE'}(NEXT_REC,1,:)=netstr('2.0b', 4);
f{'HISTORY_STEP'}(NEXT_REC,1,:)=netstr('ARSQ', 4);
f{'HISTORY_STEP_RELEASE'}(NEXT_REC,1,:)=netstr('MAR4', 4); %DEC3 MEANS DECEMBER, 2003 RELEASE OF ANNIE'S CODE AND DATABASE
[f{'HISTORY_START_PRESSURE'}(NEXT_REC,1),f{'HISTORY_STOP_PRESSURE'}(NEXT_REC,1),f{'HISTORY_PREVIOUS_VALUE'}(NEXT_REC,1)]=deal(99999.);
for i=1:size(f{'PARAMETER'},3)
    f{'CALIBRATION_DATE'}(1,D(:),i,:)=netstr(DATE_CAL,14);
end
if isnan(condslope) || condslope~=1
    f{'SCIENTIFIC_CALIB_COEFFICIENT'}(1,D(:),indexpsal,:)=netstr(['COEFFICIENT r FOR CONDUCTIVITY IS ' num2str(condslope,7) ', +/- ' num2str(condslope_err,7)], 256);
    f{'HISTORY_ACTION'}(NEXT_REC,1,:)=netstr('QCCV', 4); %means "Quality Control; Change Value"
    RESULT = 2;
else
    f{'SCIENTIFIC_CALIB_COEFFICIENT'}(1,D(:),indexpsal,:)=netstr('CONDUCTIVITY WAS NOT ADJUSTED. COEFFICIENT r FOR CONDUCTIVITY IS 1.0', 256);
    history_action=squeeze((f{'HISTORY_ACTION'}(:,1,:)));
    ok9=strmatch('QCP$',history_action);
    if length(ok9)==2
        f{'HISTORY_ACTION'}(ok9(2),1,:)=netstr('CR', 4); 
        f{'HISTORY_QCTEST'}(ok9(2),1,:)=netstr(' ', 16); 
        ok9=ok9(1);
    else
        f{'HISTORY_ACTION'}(NEXT_REC,1,:)=netstr('CR', 4); 
    end
    oldcode=f{'HISTORY_QCTEST'}(ok9,1,:)';
    a1=dec2bin(hex2dec('60000'),25)-48; %conversion from char hex to logical binary
    a2=dec2bin(hex2dec(oldcode),25)-48; %conversion from char hex to logical binary
    newhex=dec2hex(bin2dec(char((a1 | a2)+48)),16); %or and conversion from logical binary to char hex again
    f{'HISTORY_QCTEST'}(ok9,1,:)=netstr(newhex,16);%means "Wong et al. Correction and Visual QC performed by PI"
    RESULT = 1;
end

if presscorrect.pres>.001
    f{'SCIENTIFIC_CALIB_COEFFICIENT'}(1,D(:),indexpres,:)=netstr([num2str(presscorrect.pres) ' db'],256);
else
    f{'SCIENTIFIC_CALIB_COEFFICIENT'}(1,D(:),indexpres,:)=netstr(['NO PRESSURE ADJUSTMENT WAS JUDGED NECESSARY'],256);
end
%['Correction factor for pressure is ' num2str(presscorrect.pres) ' db, a drift less or equal than ' presscorrect.']
% ['COEFFICIENT r FOR CONDUCTIVITY IS ' num2str(condslope,7) ', +/- ' num2str(condslope_err,7)], 256);
if ocondslope~=condslope
    f{'SCIENTIFIC_CALIB_COMMENT'}(1,D(:),indexpsal,:)=netstr([gencomment ' The DMQC software initially suggested r=' num2str(ocondslope,7) ' for this cycle.'], 256);
else
    f{'SCIENTIFIC_CALIB_COMMENT'}(1,D(:),indexpsal,:)=netstr(gencomment, 256);
end
ncclose