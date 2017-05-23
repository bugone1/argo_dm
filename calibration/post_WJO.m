fid=fopen( 'write_log.txt','at');
float_count=0;
LL=length(netcdf_names);
for ii = 1:LL  %Run the number of files which were in local_config.NEW 
    display(['Running file #' num2str(ii) ' of ' num2str(LL)]);
    name_root=netcdf_names{ii}; %Files which were in local_config
    next_name=strtok(name_root(2:end),'_');
    ingested_flnm=[local_config.INGESTED name_root];
    name_root(1)=[];
    output_flnm=[local_config.OUT local_config.MODE name_root]; %use MODE=R unless the data are at least 6 month old
    if ~strcmp(next_name,'unusable')
        if float_count==0 || ~strcmp(next_name,float_names{float_count}) %float names must have been sorted so that each profile is grouped with the other profiles from a given float
            float_count=float_count+1;
            float_dirs{float_count}=local_config.PI;
            float_names{float_count}=next_name;
            load(char(strcat(lo_system_configuration.FLOAT_CALIB_DIRECTORY,float_dirs(float_count),lo_system_configuration.FLOAT_CALIB_PREFIX,float_names{float_count},'.mat')));
            load(char(strcat(lo_system_configuration.FLOAT_SOURCE_DIRECTORY,float_dirs(float_count),float_names{float_count},'.mat')));
            jj=size(cal_SAL,1);
            if N100>jj %in case N100 is increased
                [cal_SAL(jj:N100,:),cal_COND(jj:N100,:),cal_SAL_err(jj:N100,:),cal_COND_err(jj:N100,:)] = deal(NaN);
            end
            
            load(char(strcat(lo_system_configuration.FLOAT_CALIB_DIRECTORY,float_dirs(float_count),'calseries_',float_names{float_count},'.mat')));
            load(char(strcat(lo_system_configuration.FLOAT_CALIB_DIRECTORY,float_dirs(float_count),'cal_',float_names{float_count},'.mat')),'condslope','time_deriv_condslope','condslope_err','time_deriv_condslope_err','PROFILE_NO','cal_SAL','cal_COND','cal_COND_err','cal_SAL_err');
            Changed=0; %monitor for changes to the PI changeable parameters
            a = find(isnan(CellK)); %fill in unknown CellK's for review in ViewPlotsNew.m
            %CellK is stored in calseries_*.mat; it is created by the second AW program: set_calib_series
            if ~isempty(a) %fill in missing info for new profiles; if there are any NaNs in CellK, replace them with condslope values
                CellK(a)=condslope(a);
                min_err(a)=ones(size(a)).*str2num(local_config.MIN_MAP_ERR);
                % save calseries file ----
                save(char(strcat(lo_system_configuration.FLOAT_CALIB_DIRECTORY,float_dirs(float_count),'calseries_',float_names{float_count},'.mat')), 'calib_profile_no', 'running_const', 'cal_series_flags','CellK','min_err','comment' );
            end
            filldata=isnan(cal_SAL(:)) | cal_SAL(:)>local_config.minmaxSAL(2) | cal_SAL(:)<local_config.minmaxSAL(1); %convert fill from NaN, and bad salinities, to 99999 for writing netCDF files.
            [cal_SAL(filldata),cal_SAL_err(filldata)]=deal(99999.);
            cal_SAL_FLAG=ones(size(cal_SAL)); %if unmodified, the flag will be "1"; if modified, also "1" but the history record will show what was done
            cal_SAL_FLAG(filldata)=4; %these are 4="bad data. These flags are combined with the flags from PSAL_QC to make PSAL_ADJUSTED_QC."
            fillcond=find(isnan(condslope(:)) | condslope(:)>1.15 | condslope(:)<.85); %convert fill from NaN, and bad conductivities, to 99999.
            [condslope(fillcond),condslope_err(fillcond)]=deal(99999);
            time_deriv_condslope(fillcond)=99999;
            [m n]=size (cal_SAL);
        end
        CalFile = dir(char(strcat(lo_system_configuration.FLOAT_CALIB_DIRECTORY,float_dirs{float_count},'cal_',float_names{float_count},'.mat')));
        CalDate = datenum(CalFile.date);
        underscore=find(name_root=='_')+1; dott=find(name_root=='.')-1;
        jj=find(PROFILE_NO==str2num(name_root(underscore(1):dott(1))));
        criteria=abs(CellK-1)./max(condslope_err,min_err(jj)/40);
        if min_err(jj)>0 && criteria(jj)<=100; %setting MIN_MAX_ERR to 0 or -ve will force the profile to be adjusted
            crit_max=max(criteria); %if the float had ever been corrected using the current MIN_MAP_ERR, then it is fouled and will be corrected for this profile.
        else
            crit_max=999; %force correction if MIN_MAX_ERR not positive. If it is 0.0 then it is grey listed like 4900116.
        end
        ncclose
        result = ncprofile_write_OSAP(ingested_flnm,output_flnm,PRES(:,jj),TEMP(:,jj),cal_SAL(:,jj),cal_SAL_FLAG(:,jj),cal_SAL_err(:,jj),CellK(jj),condslope_err(jj),CalDate,min_err(jj),local_config.MODE,crit_max); %re-issue the delayed mode file
        ncclose
        %if n>3 %will not have done a fit if there are not enough profiles. Should update the newly fitted data occasionally because old calibrations will have changed slightly from their current values.
        %Save file in c:\z\argo_dm\calibration\output\ directory
      ncclose
      %RESULT=0 MEANS AN ERROR OCCURRED; RESULT=1 MEANS THAT THE PROFILE PASSED THE TEST AND WAS NOT MODIFIED; RESULT=2 MEANS THAT THE PROFILE WAS MODIFIED TO FIT CLIMATOLOGY
        dirToMove={['error' fileseparator],['unchanged' fileseparator],['changed' fileseparator]};
        if result>3 || result<1
            error(['Calibrated file not successfully handled: '  'ingested\' netcdf_names{ii}])
        else
            %move current file to c:\z\argo_dm\calibration\output\changed\
            %or unchanged or error
            %back them up in /all/
            system(['copy ' output_flnm ' '  local_config.OUT 'all' fileseparator  ]);
            system(['move ' output_flnm ' ' local_config.OUT dirToMove{result+1}]);
            nn=mod(result+1,3)+1;
            pn=mod(result+2,3)+1;
            if exist([local_config.OUT dirToMove{nn} 'd' name_root]);delete([local_config.OUT dirToMove{nn} 'd' name_root]);end
            if exist([local_config.OUT dirToMove{pn} 'd' name_root]);delete([local_config.OUT dirToMove{pn} 'd' name_root]);end
        end
        %end %n>3 Removed this if statement because the software is able to handle n < 3 conditions and still estimate the salinity correction
        fmtstring=[int2str(clock) ' , REDO_output has written ,' netcdf_names{ii} ',' next_name ', with result, %6.2f\n'];
        fprintf(fid,fmtstring,result);
    else
        fprintf(fid,'Encountered an unusable file which was sent to the do-not-process directory')
    end
    if ~isempty(dir([local_config.INGESTED netcdf_names{ii}]))
        system(['del ' local_config.NEW netcdf_names{ii}])
    end
end
fclose('all')
%!system(['xcopy ' local_config.DATA 'write_log.txt ' output_dir ' /D /M /Y']);
display('DONE');
datestr(now)
