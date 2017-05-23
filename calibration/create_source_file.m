function create_source_files(local_config,lo_system_configuration,t,presscorrect)
if ~isempty(presscorrect.sdn)
    for i=1:length(t)
        t(i).cndc=sw_cndr(t(i).psal,t(i).temp,t(i).pres);
        ok=find(t(i).cycle_number+1==presscorrect.cyc);
        t(i).pres=t(i).pres-presscorrect.pres(ok);
        t(i).psal=sw_salt(t(i).cndc,t(i).temp,t(i).pres);
    end
end
DATES=cat(1,t.dates);
LAT=cat(1,t.latitude);
LONG=cat(1,t.longitude);
PRES=cat(2,t.pres);
TEMP=cat(2,t.temp);
SAL=cat(2,t.psal);

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