ii=0;tic
while ii < length(netcdf_names)
    ii=ii+1;
    time_elapsed=toc;
    display(['Running file #' num2str(ii) ' out of ' num2str(length(netcdf_names)) ', ' num2str(round(time_elapsed/60)) 'm elapsed since last file']);
    next_name=strtok(netcdf_names{ii},'_');
    next_name=next_name(2:end);
    [LATnew,LONGnew,DATESnew,PRESnew,SALnew,TEMPnew,PTMPnew,PROFILE_NOnew,PI_NAMEnew,WMO_IDnew,DC_REFERENCEnew] = ncprofile_read_OSAP([curdir netcdf_names{ii}]);
    %<mo> assign output to strmatch and then only search latest instance of listing in matchin strings
    whichisgrey=strmatch(next_name,GREY);
    if ~isempty(whichisgrey) %greylisted data come through with qc=3 but they are bad.
        kk=sum(isnan(DATESnew) | (DATESnew > START_DAY(whichisgrey)/365.25 & DATESnew < END_DAY(whichisgrey)/365.25)); %DATESnew comes as decimal year
        greylisted=logical(kk>0);
    else
        greylisted=false;
    end
    if greylisted;SALnew(:) = nan;end
    if (float_count==0 || ~strcmp(next_name,float_names{float_count})) %float names were sorted above so that each profile is grouped with the other profiles from a given float
        float_count=float_count+1;
        if float_count>Num_Floats_To_Run; ii=ii-1;break;end
        float_dirs{float_count}=[];%local_config.PI;
        float_names{float_count}=next_name;
    end
    if ~(isempty(PTMPnew) || length(PRESnew)>N100 || PROFILE_NOnew>=9000) % & [strfind(lower(PI_NAMEnew),lower(PI_name)) strfind(lower(PI_NAMEnew),'radhakrishnan') strfind(lower(PI_NAMEnew),'rojas')]  %catch all the unusable files. Ricardo Rojas runs the Chilean program.
        %Range checks
        flagPres=PRESnew(:,1)>limPRES(2) | PRESnew(:,1)<limPRES(1) | isnan(PRESnew(:,1));
        flagTemp=TEMPnew(:,1)>limTEMP(2) | TEMPnew(:,1)<limTEMP(1) | isnan(TEMPnew(:,1)); % To pick up fill values of 99999. This data is already QC'ed at MEDS.
        flagSal=SALnew(:,1)>limSAL(2) | SALnew(:,1)<limSAL(1);
        tempOrPres=flagTemp|flagPres;
        SALnew(flagSal | tempOrPres,1)=nan;
        [TEMPnew(tempOrPres,1),PTMPnew(tempOrPres,1)]=deal(nan);
        PRESnew(flagPres)=nan;
        if sum(tempOrPres | flagSal)>0
            char('Failed pressure range check:',[repmat(char(netcdf_names{ii}),sum(flagPres),1) ones(sum(flagPres),1)*32 num2str(find(flagPres))])
            char('Failed temperature range check:',[repmat(char(netcdf_names{ii}),sum(flagTemp),1) ones(sum(flagTemp),1)*32 num2str(find(flagTemp))])
            char('Failed salinity range check:',[repmat(char(netcdf_names{ii}),sum(flagSal),1) ones(sum(flagSal),1)*32 num2str(find(flagSal))])
        end
        %End range checks
        [PRESnew(end+1:N100,1),TEMPnew(end+1:N100,1),SALnew(end+1:N100,1),PTMPnew(end+1:N100,1)]=deal(nan);
        old_flnm=flnm;
        flnm=strcat(lo_system_configuration.FLOAT_SOURCE_DIRECTORY,float_dirs{float_count},float_names{float_count},'.mat');
        if ~strcmp(flnm,old_flnm) %we have a new float
            if ~isempty(old_flnm)
                if EditData
                    [n,start,SAL,TEMP,PTMP,PRES,REJECT_SAL]=gredit_confirm(SAL,TEMP,PTMP,PRES,REJECT_SAL,PROFILE_NO,old_flnm);
                    %Re-interpolate old profiles. Don't need this if we re-run all the files.
                    if n > start %save the changes and re-interpolate if changes have been made
                        save(old_flnm, 'DATES', 'LAT', 'LONG', 'PRES', 'TEMP', 'SAL', 'PTMP', 'PROFILE_NO','REJECT_SAL');
                        lo_float_source_data=load(old_flnm);
                    end %if n > nstart
                end %if EditData
                % sort by profile_number ----
                [y,Ir]=sort(PROFILE_NO);
                if ~isempty(unique(diff(Ir))) && Ir(1)~=1
                    PROFILE_NO=PROFILE_NO(Ir);
                    DATES=DATES(Ir);
                    LAT=LAT(Ir);
                    LONG=LONG(Ir);
                    PTMP=PTMP(:,Ir);
                    SAL=SAL(:,Ir);
                    TEMP=TEMP(:,Ir);
                    PRES=PRES(:,Ir);
                end
                save(old_flnm, 'DATES', 'LAT', 'LONG', 'PRES', 'TEMP', 'SAL', 'PTMP', 'PROFILE_NO','REJECT_SAL');
            end %~isempty(old_flnm)
            if exist(flnm)
                REJECT_SAL=[];
                load(flnm,'REJECT_SAL','TEMP','PRES','SAL','PTMP','PROFILE_NO','DATES','LAT','LONG');
                jj=size(PRES,1);
                if N100>jj %in case N100 is increased
                    [PRES(jj:N100,:),TEMP(jj:N100,:),SAL(jj:N100,:),PTMP(jj:N100,:)] = deal(NaN);
                end
                SAL(isnan(TEMP) | isnan(PRES))=NaN; %make sure no bad temperatures /PRES have been used.
                if isempty(find(PROFILE_NO==PROFILE_NOnew,1)) %do not replace profiles already in the source data and edited
                    DATES = [DATES DATESnew];
                    LAT = [LAT LATnew];
                    LONG = [LONG LONGnew];
                    PRES = [PRES PRESnew];
                    TEMP = [TEMP TEMPnew];
                    SAL = [SAL SALnew];
                    PTMP = [PTMP PTMPnew];
                    PROFILE_NO = [PROFILE_NO PROFILE_NOnew];
                end %isempty(find(PROFILE_NO==PROFILE_NOnew))
            else %~exist(flnm)
                DATES = DATESnew;
                LAT = LATnew;
                LONG = LONGnew;
                PRES = PRESnew;
                TEMP = TEMPnew;
                SAL = SALnew;
                PTMP = PTMPnew;
                PROFILE_NO = PROFILE_NOnew;
                REJECT_SAL=[];
            end %exist(flnm)
        else %~strcmp(flnm,old_flnm) -STILL USING THE OLD FLOAT FILE
            if isempty(find(PROFILE_NO==PROFILE_NOnew,1)) %do not replace profiles already in the source data and edited
                DATES = [DATES DATESnew];
                LAT = [LAT LATnew];
                LONG = [LONG LONGnew];
                PRES = [PRES PRESnew];
                TEMP = [TEMP TEMPnew];
                SAL = [SAL SALnew];
                PTMP = [PTMP PTMPnew];
                PROFILE_NO = [PROFILE_NO PROFILE_NOnew];
            end
        end %if ~strcmp(flnm,old_flnm)
         movefile([curdir netcdf_names{ii}],local_config.INGESTED);
    else % we get here if the profile has the wrong PI or if the PTMP (potential temperature) was not calculated (missing salinity data)
        system(['move ' curdir netcdf_names{ii} ' ' local_config.DNP]);
        netcdf_names=netcdf_names([1:ii-1 ii+1:end]);
    end %if (~isempty(PTMPnew) & (strfind(lower(PI_NAMEnew),PI_name) | strfind(PI_NAMEnew,'NO_NAME')) & length(PRESnew) <= N100 & (PROFILE_NOnew < 9000))
end %for ii = 1:length(NewFiles);

% SAVE THE LAST FILE
if EditData
    [n,start,SAL,TEMP,PTMP,PRES,REJECT_SAL]=gredit_confirm(SAL,TEMP,PTMP,PRES,REJECT_SAL,PROFILE_NO,flnm);
end %if EditData
% sort by profile_number ----
[y,Ir]=sort(PROFILE_NO);
if ~isempty(unique(diff(Ir))) && Ir(1)~=1
    PROFILE_NO=PROFILE_NO(Ir);
    DATES=DATES(Ir);
    LAT=LAT(Ir);
    LONG=LONG(Ir);
    PTMP=PTMP(:,Ir);
    SAL=SAL(:,Ir);
    TEMP=TEMP(:,Ir);
    PRES=PRES(:,Ir);
end
save(flnm, 'DATES', 'LAT', 'LONG', 'PRES', 'TEMP', 'SAL', 'PTMP', 'PROFILE_NO','REJECT_SAL');
%keep the float list from the latest run
save([local_config.BASE 'CurrentFloats.mat'], 'float_dirs', 'float_names'); %keep this in case a re-run is necessary

%start the mapping, fitting and plotting procedures using Annie's program.
%I modified the program to weed out any database entries where the pressure
%was not within 75 dbar or the salinity was not within .5 ppt to get rid of outliers. The loss of
%a small amount of data should not have a great effect.
cd(local_config.BASE);
temporary=char(netcdf_names{1:ii})';temporary(end+1,:)=32;
display(['Ready to start argo_calibration on the following new files: ' temporary(:)']);

load(fullfile(lo_system_configuration.CONFIG_DIRECTORY,lo_system_configuration.CONFIG_WMO_BOXES),'la_wmo_boxes');
a.data_types={'ctd','bot','argo'};
%Enter WMO#s to exclude
a.exclude.ctd=[];
a.exclude.bot=[]; %-1 to exclude all
a.exclude.argo=[];   %-1 to exclude all
for i=1:3
    a.floats=dir(fullfile(lo_system_configuration.HISTORICAL_DIRECTORY,['historical_' a.data_types{i}],'*.mat'));
    a.fnames=char(a.floats.name);
    a.underscore=find(a.fnames(1,:)=='_');
    a.wmo_boxes=str2num(a.fnames(:,a.underscore+1:end-4));
    [a.tr,a.ok]=intersect(la_wmo_boxes(:,1),a.wmo_boxes);
    la_wmo_boxes(:,i+1)=0;
    if isempty(a.exclude.(a.data_types{i})) || a.data_types{i}(1)~=-1
        a.ok=setdiff(a.ok,a.exclude.(a.data_types{i}));
        la_wmo_boxes(a.ok,i+1)=1;
    end
end
save(fullfile(lo_system_configuration.CONFIG_DIRECTORY,lo_system_configuration.CONFIG_WMO_BOXES),'la_wmo_boxes');
clear a