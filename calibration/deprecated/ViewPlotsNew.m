function ViewPlotsNew
%Loads : C:\z\argo_dm\data\float_calib\freeland\calseries_*.mat
%        C:\z\argo_dm\data\float_calib\freeland\cal_*.mat
%        C:\z\argo_dm\data\float_source\freeland\*.mat
%Saves : C:\z\argo_dm\data\float_calib\freeland\calseries_*.mat
%        *.nc files
%Calls:  load_configuration.m
%        apply_greylist.m
%        processcycle.m        

%This program examines plots made through the Wong, Johnson, Owens (WJO)
%processing. The idea is to look at the plots and decide whether the
%current profile has been dealt with properly using the default values for
%statistical uncertainty and instrument precision.
%Upon due deliberation on the plots, the PI or designate can force the
%profile to be corrected to climatology, force the profile to be tagged
%as bad, or raise the default tolerance when the profile is judged to be accurate regardless of
%disagreement with the reference database to reflect oceanographic
%factors such as eddy noise or deep convection or coastal anomalies.

%It is possible to view a linear fit of condslope and to manually choose a
%value different from the WJO condslope. This facility may need more work.

%These judgement calls are recorded in the calseries_xxxxx.mat files for each float. When it is judged
%that the automated processing has not done the right thing, the affected profiles
%are re-cycled through the output stage with the new parameters using
%"ncprofile_write.m"
%Bad profiles can be treated in isolation in the WJO process by giving them a
%unique cal_series_flag number, manually, in cal_series.mat.

%If the data is considered to be bad, then PSAL_ADJUSTED must be replaced by
%PSAL and PSAL_ADJUSTED_ERROR by FillValue, PSAL_ADJUSTED_QC=4. No. This
%changed in April, 2005 - keep PSAL_ADJUSTED with QC=4.
%
clear;clc;
lo_system_configuration=load_configuration('CONFIG_WJO.TXT');
local_config=load_configuration('local_WJO.txt');
cd(local_config.BASE);
if ispc    file_separator='\'; else      file_separator='/'; end

[GREY,PARAMETER,START_DATE,END_DATE,QC,COMMENT,DAC]=textread([lo_system_configuration.FLOAT_SOURCE_DIRECTORY '../ar_greylist.txt'],'%s %s %s %s %f %s %s','headerlines',1,'delimiter',',');
start_date=char(START_DATE);end_date=char(START_DATE);
if size(start_date,2)~=8 || size(end_date,2)~=8; error('Unknown date format'); end
tempo=start_date;START_DAY=datenum(str2num(tempo(:,1:4)),str2num(tempo(:,5:6)),str2num(tempo(:,7:8)));
tempo=end_date;END_DAY=datenum(str2num(tempo(:,1:4)),str2num(tempo(:,5:6)),str2num(tempo(:,7:8)));

%strip out the backslash out of PI_name
PI_name=lower(local_config.PI(local_config.PI~=file_separator));
N100=eval(local_config.MAX_DATA);

sel_data{1}=input('File dates can be how many days old (default=365)?');if isempty(sel_data{1})
    sel_data{1}=365; end
sel_data{2}=input('All or Enter WMO Number','s'); if isempty(sel_data{2})
    sel_data{2}='all'; end

%figure out which files to do : only recent files, specific files, only
%files in changed/unchanged, or all files which have plots-------------
filesp=dir([lo_system_configuration.FLOAT_PLOTS_DIRECTORY local_config.PI '*_4.png']); %all files for which there is a graph
if ~strcmp(sel_data{2}(1:3),'all') 
    names=char(filesp.name);
    [tr,i]=intersect(names(:,1:7),sel_data{2},'rows');
    filesp=filesp(i:end);
end
ok=(now-fix(datenum(char(filesp.date))))<=sel_data{1}; filesp=filesp(ok); %only recent files

cd(local_config.BASE);
for ii=1:length(filesp); %loop on files selected
    %READ OLD COEFFICIENTS------
    ingested_flnm=dir([local_config.INGESTED '*' filesp(ii).name(1:7) '*.nc']);
    oldcoeff=zeros(size(ingested_flnm));
    for j=1:length(ingested_flnm)
        input_flnm=[local_config.INGESTED ingested_flnm(j).name];
        nc=netcdf(input_flnm,'read');
        n_calib(j)=size(nc{'SCIENTIFIC_CALIB_COEFFICIENT'},2);
        comm=deblank(nc{'SCIENTIFIC_CALIB_COEFFICIENT'}(end,end,3,:)');
        if isempty(comm)
            oldcoeff(j)=nan;
        else
            keyw='conductivity is';
            if isempty(findstr(lower(comm),keyw))
                keyw='r=';
            end
            virgule=find(comm==',');
            if isempty(virgule)
                virgule=length(comm);
            end
            oldcoeff(j)=str2num(comm((findstr(lower(comm),keyw)+length(keyw):virgule-1)));
        end
        ncclose
    end
    if sum(diff(n_calib)>1)>0
        error('Some cycles have been calibrated more often than others');
    end
    %---------------
    flnm=filesp(ii).name;
    [floatNum,name_root]=deal(strtok(flnm,'tb_'));
    load([lo_system_configuration.FLOAT_CALIB_DIRECTORY local_config.PI 'calseries_' floatNum '.mat'],'calib_profile_no',...
        'cal_series_flags','CellK','comment','min_err');
        if exist('comment','var') && ischar(comment);comment=cellstr(comment);end
    load([lo_system_configuration.FLOAT_CALIB_DIRECTORY local_config.PI 'cal_' floatNum '.mat'],'running_const','condslope',...
        'time_deriv_condslope','condslope_err','time_deriv_condslope_err','cal_COND','cal_SAL','cal_COND_err','cal_SAL_err');
    ocondslope=condslope;
    CalFile=dir(char([lo_system_configuration.FLOAT_CALIB_DIRECTORY local_config.PI 'cal_' floatNum '.mat']));
    CalDate=CalFile.date;
    load([lo_system_configuration.FLOAT_SOURCE_DIRECTORY local_config.PI floatNum '.mat'],'PRES','TEMP','SAL','PTMP','PROFILE_NO','DATES',...
        'LAT','LONG');

%    apply_greylist;

    if ~exist('CellK','var');CellK=condslope;end
    if ~exist('comment','var');comment{length(CellK)}=' ';end
    if ~exist('min_err','var');min_err=str2num(local_config.MIN_MAP_ERR)*ones(size(CellK));end
    filldata=find(isnan(cal_SAL(:)) | cal_SAL(:)>38 | cal_SAL(:)<20); %convert fill from NaN, and bad salinities, to 99999.
    [cal_SAL(filldata),cal_SAL_err(filldata)]=deal(99999);
    cal_SAL_FLAG=ones(size(cal_SAL)); %if unmodified, the flag will be "1"; if modified, also "1" but the history record will show what was done
    cal_SAL_FLAG(filldata)=4; %these are 4="bad data. These flags are combined with the flags from PSAL_QC to make PSAL_ADJUSTED_QC."
    fillcond=isnan(condslope(:)) | condslope(:)>1.15 | condslope(:)<.85; %convert fill from NaN, and bad conductivities, to 99999.
    [condslope(fillcond),condslope_err(fillcond),time_deriv_condslope(fillcond)]=deal(99999);
    FigNo=4;
    while ~isempty(FigNo) && FigNo<10 && FigNo>0 %examine figures to come to an opinion about the conductivity cell calibration
        flnm=[lo_system_configuration.FLOAT_PLOTS_DIRECTORY floatNum '_' num2str(FigNo,'%1d') '.png'];
        ['New Plot: ' flnm ' Date: ' filesp(ii).date]
        system(flnm);
        FigNo=input('Which Figure; 1-9? (other: calibrate, -1: next float)');
    end
    [prf,prfmax]=deal(length(PROFILE_NO));
    NewComment={'No Reason'};
    if FigNo~=-1
        close all;
        processcycle;
    end
end %next float
cd(local_config.BASE);
'DONE ViewPlotsnew; RUN Real2DelayedMode now'