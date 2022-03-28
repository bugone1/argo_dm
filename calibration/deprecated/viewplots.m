function viewplots(lo_system_configuration,local_config,floatNum)
% VIEWPLOTS Review results of OW calculations on Argo floats, choose
%   adjustment factors, and apply to the NetCDF files.
%   USAGE:
%       viewplots(lo_system_configuration,local_config,floatNum)
%   INPUTS:
%       lo_system_configuration - Structure of OW parameters
%       local_config - Structure of visual QC parameters
%       floatNum - Float number
%   OUTPUTS:
%       None, but updated the NetCDF files
%   VERSION HISTORY:
%       May 2017: Current working version (changes not tracked)
%       13 Jun. 2017, Isabelle Gaboury: Commented out the saving of some
%           temp files
%       17 Jul. 2017, IG: Fixed a broken special character in the comment
%           for the PSAL calibration factor
%       3 Aug. 2017, IG: Modify the regular expression passed to
%           getoldcoeffs to ignore files other than core-Argo files.

conf.dbname=lo_system_configuration.DBNAME;
conf.swname=lo_system_configuration.SWNAME;
conf.swv=lo_system_configuration.SWV;
conf.m1=sprintf('%i/%i',[lo_system_configuration.MAPSCALE_LONGITUDE_LARGE lo_system_configuration.MAPSCALE_LONGITUDE_SMALL]);
conf.m2=sprintf('%i/%i',[lo_system_configuration.MAPSCALE_LATITUDE_LARGE lo_system_configuration.MAPSCALE_LATITUDE_SMALL]);
%READ OLD COEFFICIENTS------
%---------------
load([lo_system_configuration.FLOAT_CALIB_DIRECTORY 'calseries_' floatNum '.mat'],'calib_profile_no');
load([lo_system_configuration.FLOAT_CALIB_DIRECTORY 'cal_' floatNum '.mat'],'cal_COND','cal_SAL','cal_COND_err','cal_SAL_err','pcond_factor','pcond_factor_err');
load([local_config.RAWFLAGSPRES_DIR floatNum],'presscorrect','t');
load([lo_system_configuration.FLOAT_SOURCE_DIRECTORY floatNum '.mat'],'PRES','TEMP','SAL','PTMP','PROFILE_NO',...
    'DATES','LAT','LONG');
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
oldcoeff=getoldcoeffs([local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep 'D' floatNum '*.nc']);
oldcoeff=[oldcoeff, getoldcoeffs([local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep 'R' floatNum '*.nc'])];
displaygraphs;
% The load/save lines for piaction can optionally be used to restore previous results and skip the 
% call to piaction_psal. The file piaction.mat is not used outside this routine.
% load piaction CellK slope offset start ende psalflag adjpsalflag
[CellK,slope,offset,start,ende,psalflag,adjpsalflag]=piaction_psal(PROFILE_NO,pcond_factor,oldcoeff);
% save piaction CellK slope offset start ende psalflag adjpsalflag

beg=piaction_pres(lo_system_configuration,floatNum);
presscorrect.tnpd(presscorrect.cyc>beg)=5;
try
    CellK(CellK>40*100*min_err)=nan;
catch
end
if all(CellK==1)
    scical.PSAL.comment='No conductivity adjustment was judged needed because no significant sensor drift was detected.';
elseif any(CellK(~isnan(CellK))~=1)    
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
for i=1:length(PROFILE_NO)
    ok=find(cat(1,t.cycle_number)==PROFILE_NO(i));
    if ok>length(presscorrect.tnpd)
        ok=length(presscorrect.tnpd);
    end
    if i>length(CellK)
        CellK(i)=CellK(i-1);
        pcond_factor(i)=pcond_factor(i-1);
        pcond_factor_err(i)=pcond_factor_err(i-1);
    end
    if ~isnan(CellK(i)) && (CellK(i)>.99 && CellK(i)<1.01) && all(t(ok).psal_qc=='1') && all(t(ok).temp_qc=='1') && psalflag(i)=='1'
    else
        anomaliesornot='';
    end
    %PRESSURE
    if presscorrect.tnpd(ok)==1
        scical.PRES.comment=['TNPD: APEX float that truncated negative pressure drift. ' anomaliesornot ' At least one positive surface pressure value was reported after this profile was sampled.'];
    elseif presscorrect.tnpd(ok)==2
        scical.PRES.comment=['TNPD: APEX float that truncated negative pressure drift. ' anomaliesornot ' No positive surface pressure value were reported after this profile was sampled.'];
    elseif presscorrect.tnpd(ok)==3
        oo=['TNPD: APEX float that truncated negative pressure drift. ' anomaliesornot ' At least one positive surface pressure value was reported after this profile was sampled.'];
        scical.PRES.comment=[oo 'This float has a 30%% probability to have microleak problems.'];
        if length(scical.PRES.comment)>256
            scical.PRES.comment=oo;
        end
    elseif presscorrect.tnpd(ok)==4
        oo=['TNPD: APEX float that truncated negative pressure drift. ' anomaliesornot ' No positive surface pressure value were reported after this profile was sampled.'];
        scical.PRES.comment=[oo ' This float has a 30%% probability to have microleak problems.'];
        if length(scical.PRES.comment)>256
            scical.PRES.comment=oo;
        end
    elseif presscorrect.tnpd(ok)==5
        scical.PRES.comment='TNPD: APEX float that truncated negative pressure drift. The float showed severe T/S anomalies and has possibly a microleak problem.';
    elseif presscorrect.tnpd(ok)==0
        if abs(presscorrect.slope)<0.1
            scical.PRES.comment=['PRES_ADJUSTED is calculated following the 3.2 procedure in the Argo Quality Control Manual version 3.0. No significant pressure drift was detected.' presscorrect.comment];
        else
            scical.PRES.comment=['PRES_ADJUSTED is calculated following the 3.2 procedure in the Argo Quality Control Manual version 3.0. A pressure drift of ' sprintf('%4.2f ',presscorrect.slope) presscorrect.slope_units ' was detected.' presscorrect.comment];
        end
    end
    ok2=find(cat(1,presscorrect.cyc)==PROFILE_NO(i)+1);
    if presscorrect.cyc(end)<PROFILE_NO(i)+1
        ok2=length(presscorrect.cyc);
    end
    scical.PRES.equation='PRES_ADJUSTED=PRES + coefficient (see procedure 3.2 in Argo DMQC manual v3.0)';
    addcoeff=round(-presscorrect.pres(ok2)*1e3)/1e3;
    if isempty(addcoeff) || isnan(addcoeff)
        addcoeff=0;
    end
    scical.PRES.coefficient=['ADDITIVE COEFFICIENT FOR PRESSURE ADJUSTMENT IS ' num2str(addcoeff) ' dbar'];
    %SALINITY
    if ~isnan(CellK(i)) && any(CellK(1:i)~=1)
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
    flnmp=[floatNum '_' num2str(PROFILE_NO(i),'%03d') '.nc'];
    output_flnm=['R' flnmp];
    lastnan=find(diff(isnan([PRES(:,i);nan]))>0);
    if ~isempty(lastnan)
        x=1:lastnan(end);
    else
        x=1:length(t(ok).pres);
    end
    %CREATE DTOs
    ingested_flnm=dir([local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep '*' flnmp]);
    clear flnm
    flnm.input=[local_config.DATA findnameofsubdir(floatNum,listdirs(local_config.DATA)) filesep ingested_flnm(1).name];
    %if all(isnan(PRES(x,i)))
    %    copyfile(input_flnm,[local_config.OUT 'error\' output_flnm]);
    %else
    %VALUES
    if CellK(i)~=1 && ~isnan(CellK(i))
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
    flnm.output=[local_config.OUT uc filesep output_flnm];
    tem.PRES=PRES(x,i);
    %FLAGS
    [qc.PRES.ADJ,qc.PRES.RAW]=deal(char(t(ok).pres_qc(x)));
    [qc.TEMP.ADJ,qc.TEMP.RAW]=deal(char(t(ok).temp_qc(x)));
    [qc.PSAL.ADJ,qc.PSAL.RAW]=deal(char(t(ok).psal_qc(x)));
    if (abs(presscorrect.pres(ok))>=5) %significant pressure adjustment, flag pressure to '2'
        qc.PRES.ADJ(qc.PRES.ADJ<'2')='2';
    end
    qc.PRES.ADJ(tem.PRES(:)<0 & qc.PRES.ADJ(:)<'3')='3'; %negative adjusted value ?! flag pressure to '3';
    if presscorrect.tnpd(ok)>0 &&  presscorrect.tnpd(ok)<=4 %if this is a TNPD without T/S symptoms
        qc.PRES.ADJ(qc.PRES.ADJ<'2')='2';
        qc.TEMP.ADJ(qc.TEMP.ADJ<'2')='2';
        qc.PSAL.ADJ(qc.PSAL.ADJ<'2')='2';
    elseif presscorrect.tnpd(ok)==5 %this is a TNPD with severe symptoms
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
    if presscorrect.tnpd(ok)==4 || presscorrect.tnpd(ok)==3
        err.PRES(:)=20; %following DMQC 4, changed feb2010 email list
    end
    try
        err.PSAL=max(cal_SAL_err(x,i),.01);
    catch
        err.PSAL=str2num(local_config.MIN_MAP_ERR)*ones(length(x),1);
    end
    err.PSAL=max(err.PSAL,str2num(local_config.MIN_MAP_ERR));
    err.TEMP=.002*ones(length(x),1);
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
    if any(qc.PSAL.RAW~='1') && adjpsalflag(i)=='2'
        stop=1;
    end
    qc.PSAL.RAW(qc.PSAL.RAW<psalflag(i))=psalflag(i);
    qc.PSAL.ADJ(qc.PSAL.ADJ<=adjpsalflag(i))=adjpsalflag(i);
    if adjpsalflag(i)=='0'
        qc.PSAL.ADJ(qc.PSAL.ADJ=='3')='4'; %(DMQC-3)
    end
    rawpress=tem.PRES-addcoeff; %raw pressure vector calculated this way for sorting purposes
    rewrite_nc(flnm,tem,qc,err,CalDate,conf,scical,rawpress);
end
22;
