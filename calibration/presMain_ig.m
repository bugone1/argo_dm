function presMain_ig(local_config,lo_system_configuration,floatname)
% PRESMAIN DMQC of Argo pressures
%   DESCRIPTION:
%       Load the surface pressures from the tech file, clean, despike, fit,
%       and plot. Depending on the user input, select either the cleaned
%       data or the fit as a surface pressure to use for adjusting the
%       float pressures. 
%   USAGE: 
%       presMain(local_config,lo_system_configuration,files,floatname)
%   INPUTS:
%       local_config - Structure of configuration data
%       lo_system_configuration - Structure of OW configuration data
%       floatname - Name of the float
%   OUTPUTS:
%       None, but results (MAT file and PNG) are saved to the directories
%       specified by the local_config structure. Among the fields saved is
%       presscorrect.tnpd:
%           0 non-TNPD
%           1 TNPD with serial # < 2324175 before or at the last positive pressure value
%           2 TNPD with serial # < 2324175 after the last positive pressure value
%           3 TNPD with serial # >=2324175 or launched in 2007 or after, before or at the last positive pressure value
%           4 TNPD with serial # >=2324175 or launched in 2007 or after, after the last positive pressure value
%   VERSION HISTORY:
%       May 2017: Current working version
%       3 Aug. 2017, Isabelle Gaboury: Added documentation, added some
%           default values to the prompts.
%       6 Nov. 2017, IG: Updating the TNPD criteria based on version 3.0 of
%           the DMQC manual. Some of the sub-criteria still need to be
%           updated, however.
%       7 Nov. 2017, IG: Fixed a bug relating to how dates are filled in
%           for missing cycles for APEX floats. Updated call to
%           presPerformqc to reflect this script having recently been made
%           a function.
%       28 Nov. 2017, IG: Finished (I think) updating the TNPD criteria
%           based on version 3.0 of the DMQC manual. 
%       31 Jan. 2018, IG: Further tweak to the TNPD criteria.
%       9 Apr. 2018, IG: Fixed minor bug with how a warning was being
%           displayed.
%       11 Jan. 2018, IG: Float data now being stored in float-specific
%           subdirectories.
%       11 Feb. 2019, IG: Corrected TNPD check for case where all values
%           are zero.
%       26 Feb. 2019, IG: Removed unused code to remove exceedance
%           pressure, removed "files" input parameter.

% Data directory, extended file name
%dire=[local_config.DATA findnameofsubdir(floatname,listdirs(local_config.DATA))];
dire=fullfile(local_config.DATA,floatname);
fname=[local_config.RAWFLAGSPRES_DIR floatname];

pres3=[];linfit=[];presscorrect.cyc=[];
%extract metadata info
pc=netcdf.open([local_config.METAFILES floatname '_meta.nc'],'nowrite');
p=netcdf.getVar(pc,netcdf.inqVarID(pc,'LAUNCH_DATE'))';
%zhimin ma yearlaunch seems can be retrieved from str2double(p(1:4));
yearlaunch=str2num(p(1:4));ser=netcdf.getVar(pc,netcdf.inqVarID(pc,'SENSOR_SERIAL_NO'))';netcdf.close(pc);
nc=netcdf.open([local_config.TECHFILES floatname '_tech.nc'],'nowrite');
names=lower(netcdf.getVar(nc,netcdf.inqVarID(nc,'TECHNICAL_PARAMETER_NAME')))';
ok=[]; tnpd=0; %tnpd=0; not a candidate or not a tnpd
if size(names,2)>34
    ok=strmatch(lower('PRES_SurfaceOffsetNotTruncated_dBAR'),names(:,1:35)); %apex
    if ~isempty(ok)
        offset=0;
        scalefactor=1;
        SPscale=1.0;
    end
    if isempty(ok) && size(names,2)>40
        ok=strmatch(lower('PRES_SurfaceOffsetTruncatedPlus5dbar_dBAR'),names(:,1:41)); %potential tnpd
        offset=5;
        scalefactor=1;
        tnpd=1;
        SPscale=1.0;
    end
    if isempty(ok) && size(names,2)>20
        ok=strmatch(lower('pressure_offset_dbar'),names(:,1:35)); %apex
        scalefactor=1;
        offset=0;
        SPscale=1.0;
    end
    if isempty(ok) && size(names,2)>20
        ok=strmatch(lower('pres_surfaceoffsetcorrectednotresetnegative_1cbarresolution_dbar'),...
            names(:,1:64)); %no need to adjust pressure according to argo technical xlsx file. 
        scalefactor=1;
        offset=0;
        SPscale=0.0;
    end
end
% if(floatname=='4902406')
%     ok(106)=[];
%     ok(127)=[];
% end
if isempty(ok)
    error('Can''t find pressure');
end
oldf=dir([fname '.mat']);
yn='y';
if ~isempty(oldf)
    temp=load(fname);
    if isfield(temp,'presscorrect')
        if length(temp.presscorrect.cyc)>=length(ok)
            yn=lower(input('No new pressure values since last time. Continue anyway ? (default=n)','s'));
            if isempty(yn), yn='n'; end
        end
    end
    clear temp
end
if yn(1)=='y'
    oktime=strmatch('clock_satellite_yyyymmdd',names(:,1:24));
    if ~isempty(oktime)
        apex=true;
    else
        apex=false;
        okhour=strmatch('clock_enddescentprofile_decimalhour',names);
        if isempty(okhour)
            okhour=strmatch('clock_enddescentprofile_hours',names);
        end
        okdate=strmatch('clock_startdescenttopark_yyyymmdd',names);
    end
    
    if numel(ok)>0
        % Get the technical parameter values and cycle numbers
        values=lower(netcdf.getVar(nc,netcdf.inqVarID(nc,'TECHNICAL_PARAMETER_VALUE')))';
        lok=length(ok);
        [pres,sdn]=deal(nan(lok,1));
        if apex, med_cyc_dur = median(diff(datenum(values(oktime,1:8),'yyyymmdd'))); end
        cyc_all=netcdf.getVar(nc,netcdf.inqVarID(nc,'CYCLE_NUMBER'));
        cyc=cyc_all(ok); macyc=max(cyc_all);
        loktime = numel(oktime);
        netcdf.close(nc);
        for j=1:lok
            pres(j)=str2double(values(ok(j),:))*SPscale;% add SPscale to zero if no need for pressure adjust
            if apex
                % The "ok" and "oktime" vectors may not match, as there can
                % be cycles without one of the pressure or the satellite
                % time.
                if j <= loktime && cyc_all(oktime(j)) == cyc_all(ok(j))
                    sdn(j)=datenum(values(oktime(j),:),'yyyymmdd');
                else
                    j_temp = find(cyc_all(oktime(j:end))==cyc_all(ok(j)),1,'first');
                    if ~isempty(j_temp)
                        sdn(j)=datenum(values(oktime(j+j_temp-1),:),'yyyymmdd');
                    else
                        sdn(j)=sdn(j-1)+(cyc(j)-cyc(j-1))*med_cyc_dur;
                    end
                end
            else
                if(isempty(okhour)&&isempty(okdate))
                    sdn(j)=j;
                else
%                     sdn(j)=datenum(values(okhour(j),:),'hh')+datenum(values(okdate(j),:),'yyyymmdd');
%                    zhimin ma 
                      int_hour=floor(str2double(values(okhour(j),:)));
                      resid=str2double(values(okhour(j),:))-int_hour;
                      int_min=floor(resid*60);
%                       resid_min=resid-
                     sdn(j)=datenum(str2double(values(okdate(j),1:4)),str2double(values(okdate(j),5:6)),...
                         str2double(values(okdate(j),7:8)),floor(str2double(values(okhour(j),:))),int_min,0);
                end
            end
        end
        pres(abs(pres)>1e30)=0.0;
        acyc=min(cyc):macyc;
        [tr,ok]=setdiff(acyc,cyc); %find missing cycles
        % zhimin if missing cycle is larger than 2, maybe it is not good
        % way to averaged the adjacent numbers. 
        for i=1:length(ok)
            cyc(end+1)=acyc(ok(i));
            ok1=[find(cyc==acyc(ok(i))-1); find(cyc==acyc(ok(i))+1)];
            sdn(end+1)=mean(sdn(ok1));
            pres(end+1)=mean(pres(ok1));
        end
        [sdn,j]=sort(sdn);
        pres=pres(j);
        cyc=cyc(j);
        pres3=presPerformqc_ig(pres,offset,scalefactor,apex);
        if tnpd  % At this stage, TNPD just means the truncated offset
            % Old criterion, stored here for reference
            %tnpd=(sum(pres3==0 | isnan(pres3))/length(pres3))>=.8; %it is a tnpd!
            % Criteria based on version 3.0 of the QC manual
            if sdn(end)-sdn(1) < 365/2
                % These data may need to be re-evaluated at the PI's
                % discretion
                warning('TNPD float with less than 6 months of data')
                tnpd = 0;
                %tnpd=(pres3(end)==0 || isnan(pres3)) && (sum(pres3==0 | isnan(pres3))/length(pres3))>=.8;
            elseif any(pres3<=0 | isnan(pres3))
                % According to version 3.0 of the QC manual, only data
                % sections longer than 6 months and that are not followd by
                % a section with positive values are considered TNPD. 
                if pres3(end)==0 || isnan(pres3(end))
                    if all(pres3==0) || sdn(end)-sdn(find(pres3>0 &  ~isnan(pres3),1,'last')) >= (365/2)
                        tnpd=1;
                    else
                        % Again, the PI may wish to reevaluate
                        disp('WARNING: TNPD float with a final zero-adjustment period <6mo in length');
                        tnpd = 0;
                    end
                else tnpd=0;
                end
            else
                % If all pressure adjustments are positive then the float
                % is not considered TNPD
                tnpd=0;
            end
        end
        linfit=polyfit(sdn,pres3,1);
        cyc(end+1)=cyc(end)+1; %extrapolate to "next" profile
        sdn(end+1)=2*sdn(end)-sdn(end-1);
        pres3(end+1)=2*pres3(end)-pres3(end-1);
    end
    if ~isempty(linfit)
        presscorrect.slope=linfit(1)*365.25;
        presscorrect.slope_units='dbar/year';
        presscorrect.cyc=cyc;
        presscorrect.sdn=sdn;
        presscorrect.pres=pres3;
        
    end
    presscorrect.comment=['Pressure evaluation done on ' datestr(now)];
    presscorrect.orig_pres=pres;
    presscorrect.tnpd=zeros(size(presscorrect.pres))+tnpd;
    if tnpd
        factor=(str2num(ser(1,:))>=2324175 | yearlaunch>=2007)*2;
        if isempty(factor)
            factor=0;
        end
        ok=find(presscorrect.pres>0); %find when float started reporting 0 as surface "forever"
        if isempty(ok)
            ok=1;
        end
        %tnpd of 1 of 3 means that the float reported some positive
        %surface values after the cycle
        presscorrect.tnpd(1:ok(end)-1)=1+factor;
        %tnpd of 3 of 4 means that the float reported no positive
        %surface values after the cycle
        presscorrect.tnpd(ok(end):end)=2+factor;
    end
       
    close all
    hold on
    a(1)=plot(presscorrect.sdn(1:length(presscorrect.orig_pres))-presscorrect.sdn(1),presscorrect.orig_pres,'.r');
    a(2)=plot(presscorrect.sdn-presscorrect.sdn(1),presscorrect.pres,'ob');
    
    xxx=presscorrect.sdn(1:length(presscorrect.orig_pres))-presscorrect.sdn(1);
    yyy=presscorrect.orig_pres;
    yyy(yyy<=-30)=nan;
    ok=~isnan(yyy);
    qp=polyfit(xxx(ok),yyy(ok),3);
    a(3)=plot(xxx,polyval(qp,xxx));
    
    legend(a,'Surface pressure in tech file, raw','Despiked and filtered','Cubic fit on raw');
    xlabel('Time (days)');
    ylabel('Pressure (dbar)');
    print('-dpng',[lo_system_configuration.FLOAT_PLOTS_DIRECTORY 'pres_' floatname '.png']);
    rorb=input('Blue circles (c) or blue line (l) ?','s');
    close
    if lower(rorb)=='l'
        xxx(end+1)=xxx(end)+10;
        presscorrect.pres=polyval(qp,xxx);
        linfit=polyfit(xxx(ok),yyy(ok),1);
        presscorrect.slope=linfit(1)*365.25;
    end
    if ~exist([fname '.mat'],'file')
        save(fname,'presscorrect');
    else
        tem=load(fname);
        if isfield(tem,'t')
            t=tem.t;
            save(fname,'presscorrect','t');
        else
            save(fname,'presscorrect');
        end
    end
end