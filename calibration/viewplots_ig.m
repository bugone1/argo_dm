function viewplots_ig(lo_system_configuration,local_config,floatNum, adj_bfile, preserve_doxy_correction, force_doxy_data_mode)
% VIEWPLOTS Review results of OW calculations on Argo floats, choose
%   adjustment factors, and apply to the NetCDF files.
%   USAGE:
%       viewplots(lo_system_configuration,local_config,floatNum)
%   INPUTS:
%       lo_system_configuration - Structure of OW parameters
%       local_config - Structure of visual QC parameters
%       floatNum - Float number
%   OPTIONAL INPUTS:
%       adj_bfile - Set to 1 to write 'BD' files, otherwise leave as 'BR'
%       preserve_doxy_correction - Set to 1 to indicate a pre-adjusted
%           (typically) Aanderaa float, where we do not change the
%           DOXY_ADJUSTED
%       force_doxy_data_mode - Force the DOXY data mode if it's 'R'. Note
%           that this is a relatively uncommon state.
%   OUTPUTS:
%       None, but updated the NetCDF files
%   VERSION HISTORY:
%       May 2017: Current working version (changes not tracked)
%       13 Jun. 2017, Isabelle Gaboury: Commented out the saving of some
%           temp files
%       17 Jul. 2017, IG: Fixed a broken special character in the comment
%           for the PSAL calibration factor
%       3 Aug. 2017, IG: Renamed to viewplots_ig to make use of a fork of
%           the piaction_psal code. Modified the regular expression passed
%           to  getoldcoeffs to ignore files other than core-Argo files.
%       3 Nov. 2017, IG: Some tweaks to deal with DOXY files with
%           adjustment
%       28 Nov. 2017: Updates to how TNPD flags are handled to reflect
%           version 3.0 of the DMQC manual.
%       31 Jan. 2018: Added option to define a custom error for the
%           adjusted salinity
%       12 Feb. 2018: Fixed a bug in the indexing of the pressure
%           corrections
%       08 Mar. 2018: Added a special case for the comment for float
%           4900503
%       05 Apr. 2018: Expanded the applicability of custom comments
%       10 May 2018, IG: Added preserve_doxy_correction flag to generalize
%           the special case of R files with a valid DOXY correction.
%       12 Jun. 2018, IG: Added code to calculate max DOXY when some
%           profiles have no valid values; fixed dimension of tem.DOXY
%       04 Sep. 2018, IG: Further expanded cases where a custom comment may
%           be entered.
%       15 Jan. 2019, IG: Raw data now in float-specific subdirectories
%       17 May 2019, IG: Added force_doxy_data_mode option

if nargin<4, adj_bfile=0; end
if nargin<5, preserve_doxy_correction=0; end
if nargin<6, force_doxy_data_mode=0; end


conf.dbname=lo_system_configuration.DBNAME;
conf.swname=lo_system_configuration.SWNAME;
conf.swv=lo_system_configuration.SWV;
conf.m1=sprintf('%i/%i',[lo_system_configuration.MAPSCALE_LONGITUDE_LARGE lo_system_configuration.MAPSCALE_LONGITUDE_SMALL]);
conf.m2=sprintf('%i/%i',[lo_system_configuration.MAPSCALE_LATITUDE_LARGE lo_system_configuration.MAPSCALE_LATITUDE_SMALL]);
%READ OLD COEFFICIENTS------
%---------------
load([lo_system_configuration.FLOAT_CALIB_DIRECTORY 'calseries_' floatNum '.mat'],'calib_profile_no');
load([lo_system_configuration.FLOAT_CALIB_DIRECTORY 'cal_' floatNum '.mat'],'cal_COND','cal_SAL','cal_SAL_err','pcond_factor','pcond_factor_err');
load([local_config.RAWFLAGSPRES_DIR floatNum],'presscorrect','t');
load([lo_system_configuration.FLOAT_SOURCE_DIRECTORY floatNum '.mat'],'PRES','TEMP','SAL','PTMP','PROFILE_NO',...
    'DATES','LAT','LONG','CYCLE_NO');

if(strcmp(floatNum,'4901733')==1)  % zhimin ma hardwired.
    LAT(87)=t(87).latitude;
    LONG(87)=t(87).longitude;
end
if(strcmp(floatNum,'4901734')==1)  % zhimin ma hardwired.
    LAT(26)=t(26).latitude;
    LONG(26)=t(26).longitude;
end
%------
CalFile=dir([lo_system_configuration.FLOAT_CALIB_DIRECTORY 'cal_' floatNum '.mat']);
CalDate=datestr(CalFile.datenum,'yyyymmddHHMMSS');
%-----
min_err=str2num(local_config.MIN_MAP_ERR)*ones(size(pcond_factor));

% Get old coefficients from both D and R files
% FIXME: As with the old version of the code, we assume here that the D
% files occur before the R files, which may not always be correct (e.g.,
% sometimes R files arrive late). This should only affect the plot of old
% vs. new coefficients, however, and so is not critical.
%oldcoeff=getoldcoeffs([local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep 'D' floatNum '*.nc']);
%oldcoeff=[oldcoeff; getoldcoeffs([local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep 'R' floatNum '*.nc'])];
oldcoeff=getoldcoeffs(fullfile(local_config.DATA,floatNum,['D' floatNum '*.nc']));
oldcoeff=[oldcoeff; getoldcoeffs(fullfile(local_config.DATA,floatNum,['R' floatNum '*.nc']))];
% TODO: Disabled because this currently doesn't work due to a setup issue;
% not terribly important, so come back to it later.
% displaygraphs_fun(lo_system_configuration.FLOAT_PLOTS_DIRECTORY,floatNum,-1);
% The load/save lines for piaction can optionally be used to restore previous results and skip the 
% call to piaction_psal. The file piaction.mat is not used outside this routine.
% load piaction CellK slope offset start ende psalflag adjpsalflag
% disp('WARNING: Skipping piaction_psal')
%[CellK,slope,offset,start,ende,psalflag,adjpsalflag]=piaction_psal_ig(PROFILE_NO,pcond_factor,oldcoeff);
[CellK,slope,offset,start,ende,psalflag,adjpsalflag]=piaction_psal_gui(PROFILE_NO,pcond_factor,oldcoeff);
if isnan(CellK)
    warning('Adjustment process quit before completion');
    return;
end
save piaction CellK slope offset start ende psalflag adjpsalflag

% If we have a DOXY file, ask the user how to handle the DOXY
if isfield(t,'doxy')
    adj_bfile=input('Create BD files? (1/0, default  is 0) ');
    if isempty(adj_bfile), adj_bfile=0; end
    if adj_bfile==1 && isfield(t,'doxy_adjusted')
        preserve_doxy_correction=input('Preserve existing DOXY correction? (1/0, default is 0) ');
        if isempty(preserve_doxy_correction), preserve_doxy_correction=0; end
        if preserve_doxy_correction==1
            scical.DOXY.comment=input('DOXY calibration comment: ','s');
            scical.DOXY.equation=input('DOXY calibration equation: ','s');
            scical.DOXY.coefficient=input('DOXY calibration coefficient: ','s');
        end
    end
end

beg=piaction_pres(lo_system_configuration,floatNum);




presscorrect.tnpd(presscorrect.cyc>beg)=5;
try
    CellK(CellK>40*100*min_err)=nan;
catch
end
% TODO: Still working on generalizing these cases
custom_comment_start_index=-1;
if all(CellK==1) || adjpsalflag(end)>='1'
    ba=input('Provide custom comment (comment, or blank to skip)?','s');
    if ~strcmpi(ba,'')
        scical.PSAL.comment=ba;
        custom_comment_start_index = input('Starting index for custom comment?');
    else
        scical.PSAL.comment='No conductivity adjustment was judged needed because no significant sensor drift was detected.';
    end
    ocomment2 = scical.PSAL.comment;
end
if any(CellK(~isnan(CellK))~=1)    
    if max(abs(diff(CellK)))>=.001
        sucyc=sprintf('%i',cat(1,t(1+find((abs(diff(CellK)))>.001,1)).cycle_number));
        scical.PSAL.comment=['Sudden drift in sensor detected at cycle ' sucyc '. Adjusted salinity to ' conf.swname ' statistical recommendation with ' conf.dbname ' as reference database. Mapping scales used are ' conf.m1 ' (lon) ' conf.m2 ' (lat). Visual piecewise linear fit done upon inspection of profiles ' num2str(PROFILE_NO(1)) ' to ' num2str(PROFILE_NO(end)) '. ' num2str(length(unique(ende))) ' breakpoints.'];
    else
        scical.PSAL.comment=['Sensor drift/offset detected. Adjusted salinity to ' conf.swname ' statistical recommendation with ' conf.dbname ' as reference database. Mapping scales used are ' conf.m1 ' (lon) ' conf.m2 ' (lat). Visual piecewise linear fit done upon inspection of profiles ' num2str(PROFILE_NO(1)) ' to ' num2str(PROFILE_NO(end)) '. ' num2str(length(unique(ende))) ' breakpoints.'];
    end
else
    scical.PSAL.comment='No conductivity adjustment was judged needed.';
end
ocomment=scical.PSAL.comment;
anomaliesornot='The float showed no major T/S anomalies thus far.';
% save dump

% Custom code to add the error for a set of floats where Anh had previously
% applied a correction. There's also some corresponding code below.
if adj_bfile && preserve_doxy_correction
    max_doxy = 0;
    for i=1:length(PROFILE_NO)
        ok = t(i).doxy_qc=='1';
        if any(ok), max_doxy = max(max_doxy, max(t(i).doxy(ok))); end
    end
    doxy_err = max_doxy*0.01;   % For the method applied, the error is 1% of the DOXY value       
end

% Custom error for profiles with adjusted salinity flagged as bad
% TODO: Do we want to automate the selection of this value, and/or provide
% similar options for the other variables?
ok=find(adjpsalflag>='2');
if ~isempty(ok)
    ba=input('Custom error for adjusted salinity profiles flagged as bad (value, HO for half the offset, or blank if none)? ','s');
    if ~isempty(ba)
        if strcmp(ba,'HO')
            temp_err = repmat(abs(rond((cal_SAL(1,ok)-SAL(1,ok))/2,3)),size(cal_SAL_err,1),1);
            cal_SAL_err(:,ok) = max(cal_SAL_err(:,ok), temp_err);
        else
            cal_SAL_err(:,ok) = max(cal_SAL_err(:,ok),str2double(ba));
        end
    end
end

% Leave some files as R
leave_as_R=input('Cycles to leave in A-mode (empty to convert all to D)?');

for i=1:length(PROFILE_NO)
    ok_t=find(cat(1,t.cycle_number)==CYCLE_NO(i)&cat(1,t.latitude)==LAT(i));
    
    if(isempty(ok_t)&&isnan(LAT(i)))% case with location NAN;
        ok_t=find(cat(1,t.latitude)==99999);
        if(isempty(ok_t))
            ok_t=find(cat(1,t.cycle_number)==CYCLE_NO(i));
        end
    end
    % The surface pressure is recorded at the end of the ascent, and is
    % stored with the next cycle in the trajectory file. Hence we use the
    % surface pressure from the next cycle. 
    ok_p=find(cat(1,presscorrect.cyc)==PROFILE_NO(i)+1);
    if presscorrect.cyc(end)<PROFILE_NO(i)+1
        ok_p=length(presscorrect.cyc);
    end
    if i>length(CellK)
        CellK(i)=CellK(i-1);
        pcond_factor(i)=pcond_factor(i-1);
        pcond_factor_err(i)=pcond_factor_err(i-1);
    end
    if ~isnan(CellK(i)) && (CellK(i)>.99 && CellK(i)<1.01) && all(t(ok_t).psal_qc=='1') && all(t(ok_t).temp_qc=='1') && psalflag(i)=='1'
    else
        anomaliesornot='';
    end
    %PRESSURE
    scical.PRES.equation='PRES_ADJUSTED=PRES + coefficient (see procedure 3.2 in Argo DMQC manual v3.3)';
    if presscorrect.tnpd(ok_p)==1
        scical.PRES.comment=['TNPD: APEX float that truncated negative pressure drift. ' anomaliesornot ' At least one positive surface pressure value was reported after this profile was sampled.'];
    elseif presscorrect.tnpd(ok_p)==2
        scical.PRES.comment=['TNPD: APEX float that truncated negative pressure drift. ' anomaliesornot ' No positive surface pressure value were reported after this profile was sampled.'];
    elseif presscorrect.tnpd(ok_p)==3
        oo=['TNPD: APEX float that truncated negative pressure drift. ' anomaliesornot ' At least one positive surface pressure value was reported after this profile was sampled.'];
        scical.PRES.comment=[oo 'This float has a 30%% probability to have microleak problems.'];
        if length(scical.PRES.comment)>256
            scical.PRES.comment=oo;
        end
    elseif presscorrect.tnpd(ok_p)==4
        oo=['TNPD: APEX float that truncated negative pressure drift. ' anomaliesornot ' No positive surface pressure value were reported after this profile was sampled.'];
        scical.PRES.comment=[oo ' This float has a 30%% probability to have microleak problems.'];
        if length(scical.PRES.comment)>256
            scical.PRES.comment=oo;
        end
    elseif presscorrect.tnpd(ok_p)==5
        if strcmpi(floatNum,'4900633')
            scical.PRES.comment='TNPD: APEX float that truncated negative pressure drift. The float showed severe T/S anomalies.';
        else
            scical.PRES.comment='TNPD: APEX float that truncated negative pressure drift. The float showed severe T/S anomalies and has possibly a microleak problem.';
        end
    elseif presscorrect.tnpd(ok_p)==0
        if abs(presscorrect.slope)<0.1 && sum(presscorrect.pres)~=0
            scical.PRES.comment=['PRES_ADJUSTED is calculated following the 3.2 procedure in the Argo Quality Control Manual version 3.3. No significant pressure drift was detected.' presscorrect.comment];
        elseif abs(presscorrect.slope)>=0.1 && sum(presscorrect.pres)~=0
            scical.PRES.comment=['PRES_ADJUSTED is calculated following the 3.2 procedure in the Argo Quality Control Manual version 3.3. A pressure drift of ' ...
                sprintf('%4.2f ',presscorrect.slope) presscorrect.slope_units ' was detected.' presscorrect.comment];
        elseif sum(presscorrect.pres)==0
            scical.PRES.comment=['PRES_ADJUSTED is not needed following the 3.2 procedure in the Argo Quality Control Manual version 3.3.' presscorrect.comment];
            scical.PRES.equation='';
        end
    end
    addcoeff=round(-presscorrect.pres(ok_p)*1e3)/1e3;
    if isempty(addcoeff) || isnan(addcoeff)
        addcoeff=0;
    end
    if sum(presscorrect.pres)~=0
         scical.PRES.coefficient=['ADDITIVE COEFFICIENT FOR PRESSURE ADJUSTMENT IS ' num2str(addcoeff) ' dbar'];
    else
        scical.PRES.coefficient='';
    end
    %SALINITY
    if custom_comment_start_index>=0 && PROFILE_NO(i)>=custom_comment_start_index
        scical.PSAL.comment = ocomment2;
    elseif ~isnan(CellK(i)) && any(CellK(1:i)~=1)
        %scical.PSAL.coefficient=['r=' num2str(CellK(i),7) ', � ' num2str(pcond_factor_err(i),7)];
        scical.PSAL.coefficient=['r=' num2str(CellK(i),7) ', +/- ' num2str(pcond_factor_err(i),7)];
        scical.PSAL.equation='PSAL_ADJUSTED is calculated from a potential conductivity (ref to 0 dbar) multiplicative adjustment term r.';
        if pcond_factor(i)~=CellK(i)
            scical.PSAL.comment=[ocomment ' The DMQC software initially suggested r=' num2str(pcond_factor(i),7) ' for this cycle.'];
        end
    elseif CellK(i)==1
        scical.PSAL.comment='No adjustment is needed on this parameter because no significant sensor drift has been detected.';        
    elseif isnan(CellK(i))
        scical.PSAL.comment='No adjustment was performed on this parameter because it seemed beyond correction by actual methods.';
    end
    dots=find(scical.PSAL.comment=='.');
    while length(scical.PSAL.comment)>256 && length(dots)>1
        scical.PSAL.comment=scical.PSAL.comment(1:dots(end-1));
        dots=find(scical.PSAL.comment=='.');
    end
    %---------
%     flnmp=[floatNum '_' num2str(PROFILE_NO(i),'%03d') '.nc'];
    lastnan=find(diff(isnan([PRES(:,i);nan]))>0);
    if ~isempty(lastnan)
        x=1:lastnan(end);
    else
        x=1:length(t(ok_t).pres);
    end
    %CREATE DTOs
    %ingested_flnm=dir([local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep '*' flnmp]); 
     dir_flnm=dir([local_config.DATA floatNum filesep '*.nc']);
     for k=1:length(dir_flnm)
         nc_tmp=netcdf.open([dir_flnm(k).folder filesep dir_flnm(k).name],'NC_NOWRITE');
         var_tmp=netcdf.inqVarID(nc_tmp,'LATITUDE');
         var1_tmp=netcdf.inqVarID(nc_tmp,'LONGITUDE');
         lat_tmp=netcdf.getVar(nc_tmp,var_tmp);
         lon_tmp=netcdf.getVar(nc_tmp,var1_tmp);
         var2_tmp=netcdf.inqVarID(nc_tmp,'CYCLE_NUMBER');
         cycle_tmp=netcdf.getVar(nc_tmp,var2_tmp);
         if(lon_tmp>180)
             lon_tmp=lon_tmp-360;
         end
         if(LONG(i)>180)
             LONG(i)=LONG(i)-360;
         end
         if(lat_tmp==LAT(i)&&(lon_tmp==LONG(i))&&~isnan(LAT(i))&&cycle_tmp==CYCLE_NO(i))
             netcdf.close(nc_tmp);
             ingested_flnm=dir_flnm(k).name;
             break;
         elseif (isnan(LAT(i))&& lat_tmp==99999)&&(cycle_tmp==CYCLE_NO(i))
             netcdf.close(nc_tmp);
             ingested_flnm=dir_flnm(k).name;
             break;
         end
          netcdf.close(nc_tmp)
       end
    clear flnm flnm_b
    if length(ingested_flnm)==2
        if strfind(ingested_flnm(1).name,'B')==1
            %flnm.input=[local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep ingested_flnm(2).name];
            %flnm_b.input=[local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep ingested_flnm(1).name];
            flnm.input=[local_config.DATA floatNum filesep ingested_flnm(2).name];
            flnm_b.input=[local_config.DATA floatNum filesep ingested_flnm(1).name];
        else error('Possible problem with file names');
        end
    else
        %flnm.input=[local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep ingested_flnm(1).name];
        flnm.input=[local_config.DATA floatNum filesep ingested_flnm];
        flnm_b.input=[];
    end
    %VALUES
    if CellK(i)~=1 && ~isnan(CellK(i)) %% zhiminma this has to GSW function later change
        tem.PSAL=sw_salt(cal_COND(x,i)*CellK(i)/pcond_factor(i)/sw_c3515,PTMP(x,i),0*SAL(x,i)); 
    else
        tem.PSAL=SAL(x,i);
    end
    %    if CellK(i)~=1 || presscorrect.pres(ok)~=0 || presscorrect.tnpd(ok)>0
    %        %            uc='changed';
    %    else
    %        %            uc='unchanged';
    %    end
    uc='changed';
    % We assume R files here, but this will be fixed up by rewrite_nc
    flnm.output=[local_config.OUT uc filesep 'R' ingested_flnm(2:end)];
    if ~isempty(flnm_b.input)
        flnm_b.output=[local_config.OUT uc filesep 'BR' flnmp];
    else
        flnm_b.output=[];
    end
    tem.PRES=PRES(x,i);
    %FLAGS
    [qc.PRES.ADJ,qc.PRES.RAW]=deal(char(t(ok_t).pres_qc(x)));
    [qc.TEMP.ADJ,qc.TEMP.RAW]=deal(char(t(ok_t).temp_qc(x)));
    [qc.PSAL.ADJ,qc.PSAL.RAW]=deal(char(t(ok_t).psal_qc(x)));
    if (abs(presscorrect.pres(ok_p))>=5) %significant pressure adjustment, flag pressure to '2'
        qc.PRES.ADJ(qc.PRES.ADJ<'2')='2';
    end
    qc.PRES.ADJ(tem.PRES(:)<0 & qc.PRES.ADJ(:)<'3')='3'; %negative adjusted value ?! flag pressure to '3';
    % As of version 3.0 of the manual, we only flag the data as bad once
    % the data become TNPD (i.e., once the values go to zero and stay at
    % zero).
    if presscorrect.tnpd(ok_p)==2 ||  presscorrect.tnpd(ok_p)==4 %if this is a TNPD without T/S symptoms
        qc.PRES.ADJ(qc.PRES.ADJ<'2')='2';
        qc.TEMP.ADJ(qc.TEMP.ADJ<'2')='2';
        qc.PSAL.ADJ(qc.PSAL.ADJ<'2')='2';
    elseif presscorrect.tnpd(ok_p)==5 %this is a TNPD with severe symptoms
        qc.PRES.ADJ(qc.PRES.ADJ<'4')='4';
        qc.TEMP.ADJ(qc.TEMP.ADJ<'4')='4';
        qc.PSAL.ADJ(qc.PSAL.ADJ<'4')='4';
    end
    if isnan(CellK(i))
        qc.PSAL.ADJ(:)='4';
        qc.PSAL.RAW(:)='4';
    end
    %ERROR
    err.PRES=2.4*ones(length(x),1);
    if presscorrect.tnpd(ok_p)==4 || presscorrect.tnpd(ok_p)==3
        err.PRES(:)=20; %following DMQC 4, changed feb2010 email list
    end
    try
        err.PSAL=max(cal_SAL_err(x,i),.01);
    catch
        err.PSAL=str2num(local_config.MIN_MAP_ERR)*ones(length(x),1);
    end
    err.PSAL=max(err.PSAL,str2num(local_config.MIN_MAP_ERR));
    err.TEMP=.002*ones(length(x),1);
    % DOXY-related fields. 
%     if isfield(t(ok_t),'doxy')
%         %[qc.DOXY.ADJ,qc.DOXY.RAW]=deal(char(t(ok_t).doxy_qc(x)));
%         qc.DOXY.RAW = char(t(ok_t).doxy_qc(x));
% %         tem.DOXY = calc_doxy(floatNum,tem.PRES',t(i).temp,tem.PSAL',t(i).temp_doxy,t(i).phase_delay_doxy);
%     end
%     % TODO: Currently only adjusting DOXY, add similar lines below if ever
%     % these might be adjusted.
%     if isfield(t(ok_t),'doxy_adjusted') && any(t(ok_t).doxy_adjusted<10000)
%         qc.DOXY.ADJ = char(t(ok_t).doxy_qc(x));
%         if adj_bfile && preserve_doxy_correction
%             tem.DOXY = t(ok_t).doxy_adjusted(x)';
%             err.DOXY = doxy_err*ones(length(x),1);
%         end
%     end
%     if isfield(t(ok_t),'temp_doxy')
%         %[qc.TEMP_DOXY.ADJ,qc.TEMP_DOXY.RAW]=deal(char(t(ok_t).temp_doxy_qc(x)));
%         qc.TEMP_DOXY.RAW = char(t(ok_t).temp_doxy_qc(x));
%     end
%     if isfield(t(ok_t),'phase_delay_doxy')
%         %[qc.PHASE_DELAY_DOXY.ADJ,qc.PHASE_DELAY_DOXY.RAW]=deal(char(t(ok_t).phase_delay_doxy_qc(x)));
%         qc.PHASE_DELAY_DOXY.RAW = char(t(ok_t).phase_delay_doxy_qc(x));
%     end
%     if isfield(t(ok_t),'molar_doxy')
%         %[qc.PHASE_DELAY_DOXY.ADJ,qc.PHASE_DELAY_DOXY.RAW]=deal(char(t(ok_t).phase_delay_doxy_qc(x)));
%         qc.MOLAR_DOXY.RAW = char(t(ok_t).molar_doxy_qc(x));
%     end
    flnm.input
%     if findstr('4901189',flnm.input)
%         if PROFILE_NO(i)>15
%             ep=t(ok).pres*.35;
%             err.PRES=max(err.PRES,ep');
%             qc.PRES.ADJ(:)='4';
%             qc.PRES.RAW(:)='4';
%             qc.PSAL.RAW(:)='4';
%             qc.PSAL.ADJ(:)='4';
%             qc.TEMP.RAW(:)='3';
%             qc.TEMP.ADJ(:)='3';
%             scical.TEMP.comment='Temperature is compromised because pressure sensor is unreliable';
%             scical.PSAL.comment='Salinity is compromised because pressure sensor is unreliable. The conductivity sensor also appears to be defective.';
%             scical.PRES.comment='The pressure sensor appears defective in a way that can''t be corrected with the approved methods.';
%         end
%     elseif findstr('4900632',flnm.input)
%         ep=(double(PROFILE_NO(i))-60)*2.75*ones(length(x),1);
%         err.PRES=max(err.PRES,ep);
%     elseif findstr('4901132',flnm.input)
%         ep=abs(addcoeff(:));
%         err.PRES=max(err.PRES,ep);
%     end
%     % IG temp
%     if findstr('4901188',flnm.input) && PROFILE_NO(i)>55
%         qc.PSAL.ADJ(qc.PSAL.ADJ=='3')='2';
%     end
%     % IG temp - end
%     if any(qc.PSAL.RAW~='1') && adjpsalflag(i)=='2'
%         stop=1;
%     end
    qc.PSAL.RAW(qc.PSAL.RAW<psalflag(i))=psalflag(i);
    qc.PSAL.ADJ(qc.PSAL.ADJ<=adjpsalflag(i))=adjpsalflag(i);
    if adjpsalflag(i)=='0'
        qc.PSAL.ADJ(qc.PSAL.ADJ=='3')='4'; %(DMQC-3)
    end
    rawpress=tem.PRES-addcoeff; %raw pressure vector calculated this way for sorting purposes
    if any(leave_as_R==CYCLE_NO(i))
        rewrite_nc(flnm,tem,qc,err,CalDate,conf,scical,rawpress,'A');
    else
        %%
%check original D files to see if N_HISTORY is unlimited, if not, rewrite
%file with unlimited N_HISTORY 
%         if(ingested_flnm(1)=='D')
           Rechck_HISTORY(flnm,floatNum);
%         end
        rewrite_nc(flnm,tem,qc,err,CalDate,conf,scical,rawpress,'D');
    end
%     if ~isempty(flnm_b.input)
%         % TODO: I'm not entirely sure this will always work as desired
%         if adj_bfile==0 %&& preserve_doxy_correction==0
%             rewrite_nc(flnm_b,tem,qc,err,CalDate,[],scical,rawpress,'R',force_doxy_data_mode);
%         elseif adj_bfile==1
%             rewrite_nc(flnm_b,tem,qc,err,CalDate,[],scical,rawpress,'D');
%         end
%     end
end
