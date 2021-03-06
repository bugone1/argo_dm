function fname=rewrite_nc(flnm,tem,qc,err,CalDate,conf,scical,PRES,output_data_mode,force_output_data_mode)
% REWRITE_NC Create an output Argo NetCDF file from an input file and parameters
%   DESCRIPTION:
%       Given an input NetCDF file and parameters arising from DMQC, copy
%       the input NetCDF file and adjust the variables to reflect DMQC
%   INPUTS:
%       flnm - Filenames, including fields "input" and "output"
%       tem - Data structure containing variables that have been adjusted
%           (usually only PSAL and PRES)
%       qc - Structure of QC flags, as generated by viewplots.m
%       err - Structure of error values, as generated by viewplots.m
%       CalDate - Calibration date
%       conf - Configuration data structure, as generated by viewplots.m
%       scical - Calibration data structure, as generated by viewplots.m
%       PRES - Raw pressure, used for sorting, as generated by viewplots.m
%       output_data_mode - One of 'R' (only update flags), 'A' (adjust), or
%           'D' (create D files). Note that this only causes files to
%           advance in status from R to A to D, so D files will not be
%           converted to A/R or A to R. Setting to 'R' thus has the same
%           effect as the old qc_flags_only keyword
%   OUTPUTS:
%       fname - Name of the output file; identical to flnm.output
%   VERSION HISTORY:
%       23 May 2017: Working version (changes not tracked)
%       13 Jun. 2017, Isabelle Gaboury: Fixed a minor bug in the call to
%           netcdf.inqdim to ensure compatibility with older versions of
%           Matlab.
%       2 Aug. 2017, IG: Modifications to handle b-files. Added
%           documentation.
%       21 Aug. 2017, IG: Allow option to leave b-files as BR
%       6 Oct. 2017, IG: Added MOLAR_DOXY
%       3 Nov. 2017, IG: Changed default behaviour with respect to N_CALIB
%           so that previous calibrations are now stored.
%       6 Nov. 2017, IG: Added option to only update QC flags.
%       25 Apr. 2018, IG: Added a temporary "if" clause to try and sort out
%           issues arising when sorting the pressures; when encountering
%           the case that was causing issues the code goes to the keyboard.
%       15 May 2018, IG: Fixed issue with setting of PARAMETER_DATA_MODE in
%           B-files; modified the handling of the scientific calibration
%           information for the DOXY variable
%       8 Jun. 2018, IG: Fixed a bug causing only flag updates on the first
%           variable edited to be recorded in the history.
%       12 Jun. 2018, IG: Fixed bug with padding vectors for DOXY
%       12 Nov. 2018, IG: Replaced adj_bfile and qc_flags_only with
%           output_data_mode
%       14 Jan. 2019, IG: Adjusting how output_data_mode is interpreted
%       17 May 2019, IG: Added option to force the output_data_mode

if nargin<10, force_output_data_mode=0; end
if nargin < 9, output_data_mode = 'D'; end


ovarnames={'PRES','TEMP','PSAL','DOXY','TEMP_DOXY','BPHASE_DOXY','PHASE_DELAY_DOXY','MOLAR_DOXY'};
adjornot={'_ADJUSTED',''};
fe=netcdf.open(flnm.input,'NOWRITE');
% [foo,N_CALIB] = netcdf.inqDim(fe,netcdf.inqDimID(fe,'N_CALIB')); % N_CALIB never seems to be used  
clear foo;
scc=netcdf.getVar(fe,netcdf.inqVarID(fe,'SCIENTIFIC_CALIB_COMMENT'));
netcdf.close(fe);
ok=find(flnm.output==filesep);
if flnm.output(ok(end)+1)=='B'
    is_bfile=1;
    if strcmpi(output_data_mode,'D')
        flnm.output(ok(end)+2)='D'; 
    else
        ok_in=find(flnm.input==filesep);
        flnm.output(ok(end)+2)=flnm.input(ok_in(end)+2);
    end
else
    is_bfile=0;
    if strcmpi(output_data_mode,'D')
        flnm.output(ok(end)+1)='D';
    else
        ok_in=find(flnm.input==filesep);
        flnm.output(ok(end)+1)=flnm.input(ok_in(end)+1);
    end
end

% Copy the netCDF file and redimension N_CALIB
% First we check if the last SCIENTIFIC_CALIB_COMMENT contains only the
% comment 'n/a', indicating the float hasn't been calibrated before. 
% TODO: Earlier versions of the code checked all comments and counted up
% the number of 'n/a' entries, but this could lead to blanking of valid
% comments. For now I'm assuming there will be no more than one 'n/a'
% entry, but may need to add code to handle multiple such entries if these
% regularly occur.
if strcmpi(output_data_mode,'R')
    copyfile(flnm.input, flnm.output);
else
    uscc=unique(lower(scc(:,:,end)));
    if all(uscc=='a' | uscc=='n' | uscc=='/' | uscc==' ')
        redim_num=0;  % This just blanks the last comment
    else redim_num=1;
    end
    copy_nc_redim(flnm.input,flnm.output,'N_CALIB',redim_num);
    %zhimin ma add one dimensiona to N-history, otherwise there is a bug
    %seems, not sure how this was done beofore.
%     copy_nc_redim(flnm.input,flnm.output,'N_HISTORY',redim_num);
end

%open file in write mode
f=netcdf.open(flnm.output,'WRITE');
if is_bfile %&& ~strcmpi(output_data_mode,'R')
	try
	    % Rename 'OTMP' variable to 'TEMP_DOXY'
	    netcdf.inqVarID(f,'OTMP');
	    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP'),'TEMP_DOXY');
	    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP_QC'),'TEMP_DOXY_QC');
	    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP_ADJUSTED'),'TEMP_DOXY_ADJUSTED');
	    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP_ADJUSTED_QC'),'TEMP_DOXY_ADJUSTED_QC');
	    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP_ADJUSTED_ERROR'),'TEMP_DOXY_ADJUSTED_ERROR');    
	catch
	    % There doesn't seem to be a netcdf function that will inquire whether
	    % or not the variable exists, so this quiet catch happens when the file
	    % does not contain the variable OTMP
	end
end

if is_bfile
    fv1=netcdf.getAtt(f,netcdf.inqVarID(f,'PRES'),'_FillValue');
else
    fv1=netcdf.getAtt(f,netcdf.inqVarID(f,'TEMP'),'_FillValue');
end
%header stuff
nowe=now;temptime=nowe+(heuredete(nowe)/24);
DATE_CAL=CalDate;
% PAR_LEN=4+12*double(str2num(netcdf.getVar(f,netcdf.inqVarID(f,'FORMAT_VERSION'))')==2.2);
netcdf.putVar(f,netcdf.inqVarID(f,'DATE_UPDATE'),datestr(temptime,'yyyymmddHHMMSS'));

% Get the list of station parameters and some dimensions
oparms=netcdf.getVar(f,netcdf.inqVarID(f,'STATION_PARAMETERS'))';
[trash,N_HISTORY]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_HISTORY'));
[trash,N_LEVELS]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_LEVELS'));
[trash,N_PARAM]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_PARAM'));
if strcmpi(output_data_mode,'D')
    netcdf.putVar(f,netcdf.inqVarID(f,'DATA_MODE'),'D');
    netcdf.putVar(f,netcdf.inqVarID(f,'DATA_STATE_INDICATOR'),netstr('2C+',4));
else
    % If we are specifying R or A mode then we can do this PROVIDED the
    % data are not already in a more advanced state.
    if force_output_data_mode==1 || ~(strcmpi(netcdf.getVar(f,netcdf.inqVarID(f,'DATA_MODE')),'D') || ...
            (strcmpi(output_data_mode,'R') && strcmpi(netcdf.getVar(f,netcdf.inqVarID(f,'DATA_MODE')),'A')))
        netcdf.putVar(f,netcdf.inqVarID(f,'DATA_MODE'), output_data_mode);
        netcdf.putVar(f,netcdf.inqVarID(f,'DATA_STATE_INDICATOR'),netstr('2B+',4));
    end
end
if is_bfile && ~strcmpi(output_data_mode,'R')
    % Currently leaving the intermediate DOXY values as raw, as I don't have an error for them.
    temp_str = repmat('R',1,N_PARAM);
    ii_doxy=strmatch('DOXY',oparms(:,1:4));
    if ~isempty(ii_doxy)
        if strcmpi(output_data_mode,'D')
            temp_str(ii_doxy)='D'; 
        else
            temp_data_mode = netcdf.getVar(f,netcdf.inqVarID(f,'PARAMETER_DATA_MODE'));
            if force_output_data_mode==1 || ~(strcmpi(temp_data_mode(ii_doxy),'D') || ...
                    (strcmpi(output_data_mode,'R') && strcmpi(netcdf.getVar(f,netcdf.inqVarID(f,'DATA_MODE')),'A')))
                temp_str(ii_doxy)=output_data_mode; 
            end
        end
    end
    netcdf.putVar(f,netcdf.inqVarID(f,'PARAMETER_DATA_MODE'),temp_str);
end

% TODO: I'm currently seeing if maybe this is needed for all output data
% modes, but need to keep working with this a bit.
%if ~strcmpi(output_data_mode,'R')
di=N_LEVELS-length(tem.PRES);
if di>0 %Lenghten vectors if there are more levels
    temfn=fieldnames(tem);
    for i=1:length(temfn)
        tem.(temfn{i})=[tem.(temfn{i}); nan(di,1)];
        tem.(temfn{i})=tem.(temfn{i})(1:N_LEVELS);
    end
    temfn=fieldnames(qc);
    for i=1:length(temfn)
        qc.(temfn{i}).RAW=[qc.(temfn{i}).RAW(:); ones(di,1)*'4'];
        qc.(temfn{i}).RAW=char(qc.(temfn{i}).RAW(1:N_LEVELS));
        if isfield(qc.(temfn{i}),'ADJ')
            qc.(temfn{i}).ADJ=[qc.(temfn{i}).ADJ(:); ones(di,1)*'4'];
            qc.(temfn{i}).ADJ=char(qc.(temfn{i}).ADJ(1:N_LEVELS));
        end
    end
    temfn=fieldnames(err);
    for i=1:length(temfn)
        err.(temfn{i})=[err.(temfn{i}); nan(di,1)];
        err.(temfn{i})=err.(temfn{i})(1:N_LEVELS);
    end
end
%end
fc=[];
%Only keep vars that are present in file
[ndims,nvars] = netcdf.inq(f);
for i=1:nvars
    varnamesf{i}=netcdf.inqVar(f,i-1);
end
varnames=intersect(ovarnames,varnamesf);
% If dealing with a b-file, the pressure is only for information; we don't
% store QC flags. 
if is_bfile
    % varnames=setdiff(varnames,'PRES');
    varid=netcdf.inqVarID(f,'PRES');
    raw.PRES=netcdf.getVar(f,varid)';
    adj.PRES=raw.PRES; % This just keeps things from crashing below, but is not used for anything
end
for i=1:length(varnames) %keep same fields unless they are provided in the structure "tem"
    varname=varnames{i};
    if is_bfile && strcmp(varname,'PRES'), continue; end  % We don't need to do anything with PRES for b-files
    varid=netcdf.inqVarID(f,varname);
    checkif=netcdf.getVar(f,varid);
    if ~isempty(checkif)
        tempo=netcdf.getVar(f,varid);
        ok=find(abs(tempo)>1e30);
        if ~isempty(ok)
            tempo(ok)=fv1;
            netcdf.putVar(f,varid,tempo);
            display('changed >1e30 to fill value');
        end
        raw.(varname)=netcdf.getVar(f,varid)';
        if ~isfield(tem,varname)
            % TODO: Still testing what to do here
            %if strcmpi(output_data_mode,'R')
                % In this case we reuse whatever is there already
%                 adj.(varname)=netcdf.getVar(f,netcdf.inqVarID(f,[varname '_ADJUSTED']))';
%             else
            adj.(varname)=netcdf.getVar(f,varid)';
%             end
        else
            adj.(varname)=tem.(varname);
        end
        %FLAGS
        %-raw
        oldrawflags=netcdf.getVar(f,netcdf.inqVarID(f,[varname '_QC']));
        raw.([varname '_QC'])=oldrawflags; %take original raw flags
        if isfield(qc,varname)
            tfc=find(qc.(varname).RAW(:)~=oldrawflags(:)); %find which raw flags changed
            if ~isempty(tfc)
                raw.([varname '_QC'])(tfc)=qc.(varname).RAW(tfc); %update changed raw flags
                fc.(varname).pres=raw.PRES(tfc); %create this fc struct for history records later
                fc.(varname).oldflag=oldrawflags(tfc);
            end
            %-adj
            if isfield(qc,varname) && isfield(qc.(varname),'ADJ')
                adj.([varname '_QC'])=qc.(varname).ADJ;
            else
                adj.([varname '_QC'])=netcdf.getVar(f,netcdf.inqVarID(f, [varname '_ADJUSTED_QC']));
            end
            %ERR
            if is_bfile && ~isfield(err,varname)
                adj.([varname '_ERR'])=ones(size(raw.(varname)))*fv1;
            elseif ~strcmpi(output_data_mode,'D')
                % In this case we reuse whatever was there before
                adj.([varname '_ERR'])=netcdf.getVar(f,netcdf.inqVarID(f,[varname '_ADJUSTED_ERROR']));
                ii_temp = find(adj.([varname '_ERR'])==fv1 & adj.([varname '_QC'])' < '4');
                if ~isempty(ii_temp)
                    ii_temp_2 = find(adj.([varname '_ERR'])~=fv1,1,'first');
                    if isempty(ii_temp_2)
                        %TODO: I previously had this as an error, but I
                        %don't think it needs to be (at least not for R
                        %files?)
                        warning('No valid err values found')
                    else
                        adj.([varname '_ERR'])(ii_temp) = adj.([varname '_ERR'])(ii_temp_2);
                    end
                end
            else
                adj.([varname '_ERR'])=err.(varname);
            end
        else
            adj.([varname '_QC'])=oldrawflags;
            adj.([varname '_ERR'])=netcdf.getVar(f,netcdf.inqVarID(f,[varname '_ADJUSTED_ERROR']));
        end
    end
end

%make sure that there are no NaNs, only fillvalues. Then that
%corresponding flags to fillvalues are 4. Then that all flags of 4 have
%corresponding fillvalues  !!
%go from raw/adj objects to NetCDF file
%Re-sort according to RAW pres %nov 11
[tr,i,j]=intersect(rond(str2num(num2str(PRES)),2),rond(str2num(num2str(raw.PRES)),2));
ok1=setdiff(1:length(raw.PRES),j);
ok2=setdiff(1:length(adj.PRES),i);
[~,name,~] = fileparts(flnm.input);
if (strcmp(name(2:8),'4900525'))
else
   if ~isempty(ok1) && ~isempty(ok2) && any(ok1~=ok2) && all(raw.PRES(ok1)==raw.PRES(ok2))
    % IG, 25 Apr. 2018: This came up when dealing with duplicate pressures
    % where the deeper pressur was marked as bad (as recommended in the QC
    % manual); the normal adjustment below was inverting the flags. For
    % float 4900528 it seemed to be enough to just skip the "else" clause
    % below, but should continue to keep an eye on these cases. If this
    % doesn't come up again then this if statement can be removed.
    disp('Seem to have duplicate pressures, currently need to deal with this manually')
    keyboard
   else
    fn=fieldnames(adj);
    for k=1:length(fn)
        clear t
        t(ok1)=adj.(fn{k})(ok2);    % Elements of adj.PRES that are not in raw.PRES
        t(j)=adj.(fn{k})(i);        % Elements in common, ordered by raw.PRES
        adj.(fn{k})=t;
    end
   end
end
%write adjusted value to the output;
for i=1:length(varnames)
    varname=varnames{i};
    if is_bfile && strcmp(varname,'PRES'), continue; end % We don't do anything with PRES for b-files
    checkif=netcdf.getVar(f,netcdf.inqVarID(f,varname));
    if ~isempty(checkif)
        ok1=isnan(adj.(varname)(:)); ok2=adj.([varname '_QC'])(:)=='4'; ok3=adj.(varname)(:)==fv1;
        ok=(ok1|ok2|ok3);
        adj.([varname '_QC'])(ok')='4';adj.(varname)(ok)= fv1;adj.([varname '_ERR'])(ok)=fv1;
        netcdf.putVar(f,netcdf.inqVarID(f,[varname '_QC']),raw.([varname '_QC'])); %raw flags
        %if ~strcmpi(output_data_mode,'R') && (~is_bfile || strcmp(varname,'DOXY'))  % TODO: Expand to i-variables?
        if ~is_bfile || (strcmp(varname,'DOXY') && ~strcmpi(output_data_mode,'R')) % TODO: Expand to i-variables? TODO: Revisit case where we write adjusted DOXY, could change
            netcdf.putVar(f,netcdf.inqVarID(f,[varname '_ADJUSTED']),adj.(varname));
            netcdf.putVar(f,netcdf.inqVarID(f,[varname '_ADJUSTED_QC']),adj.([varname '_QC']));     %adj flags
            netcdf.putVar(f,netcdf.inqVarID(f,[varname '_ADJUSTED_ERROR']),adj.([varname '_ERR']));
        end
    end
end

%Populate PARAMETER columns for new N_CALIB
parameterid=netcdf.inqVarID(f,'PARAMETER');
[varname,xtype,dimids]=netcdf.inqVar(f,parameterid);
clear di dj
for i=1:length(dimids)
    [dimname,di(i)]=netcdf.inqDim(f,dimids(i));
    if strcmp(dimname,'N_CALIB')
        i_calib=i;
    elseif strcmp(dimname,'N_PARAM')
        i_param=i;
    elseif strcmp(dimname,'N_PROF')
        i_prof=i;
    else
        i_parlen=i;
    end
end
dj=di*0;
ndi=di;ndj=dj;
%first make sure first iteration is filled
ndi(i_calib)=1;
parms=netcdf.getVar(f,parameterid,dj,ndi);
if ~strcmpi(output_data_mode,'R') && isempty(strtrim(parms(:)))
    netcdf.putVar(f,parameterid,dj,ndi,oparms');
end
%then fill next ones
% IG note: As of 1 Nov., this has been changed, we now just need to fill in
% the last item
% for j=2:di(i_calib)
%     parms=netcdf.getVar(f,parameterid,dj,ndi);
%     ndj(i_calib)=j-1;
%     netcdf.putVar(f,parameterid,ndj,ndi,parms);
% end
ndj(i_calib)=di(i_calib)-1;
if ~strcmpi(output_data_mode,'R'), netcdf.putVar(f,parameterid,ndj,ndi,parms); end
PAR_LEN=size(deblank(parms'),2);
%Populate SCIENTIFIC_CALIB_* columns for new N_CALIB
%SCIENTIFIC_CALIB_*
dj(i_calib)=di(i_calib)-1;
di(i_calib)=1;
for i=1:N_PARAM
    dj(i_param)=i-1;
    di(i_parlen)=PAR_LEN;
    di(i_param)=1;
    % Get the parameter name. If N_CALIB>1 then we just need to fetch one
    % copy of the name
    parm=netcdf.getVar(f,parameterid,dj,di);
    if any(char(max(parm,[],3))~=parm(:,:,1)), error('Error reading in the parameters'); end
    parm=deblank(parm(:,:,1)');  
    if ~strcmp(parm,'OTMP') && ~strcmp(parm,'BPHA')
        if ~(is_bfile && strcmp(parm,'PRES'))
            %PERC GOOD
            if is_bfile && (strcmpi(output_data_mode,'R') || ~strcmp(parm,'DOXY'))  % TODO: Reconsider treatment of intermediate variables
                bigname=[parm '_QC'];
            else
                bigname=[parm adjornot{isempty(netcdf.getVar(f,netcdf.inqVarID(f,[parm '_ADJUSTED'])))+1} '_QC'];
            end
            fbigname=netcdf.getVar(f,netcdf.inqVarID(f,bigname));
            one=fbigname=='1' | fbigname=='2'; nonqced=fbigname=='0';
            percgood=sum(one)/length(one);
            if sum(nonqced)==length(one)
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
            netcdf.putVar(f,netcdf.inqVarID(f,['PROFILE_' parm '_QC']),profparmqc);
            if sum(nonqced)>0 && percgood>0
                error('Mix of QCED/Non-QCED in same profile!')
            end
            di(i_parlen)=256;
        end
        if ~strcmpi(output_data_mode,'R') && ~isempty(scical)
            if strcmp('PSAL',parm(1:4)) || (~is_bfile && strcmp('PRES',parm(1:4))) || (strcmp('DOXY', parm(1:4)) && isfield(scical,'DOXY'))
                netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COMMENT'),dj,di,netstr(scical.(parm).comment,256));
                if isfield(scical.(parm),'equation')
                    netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_EQUATION'),dj,di,netstr(scical.(parm).equation,256));
                    netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COEFFICIENT'),dj,di,netstr(scical.(parm).coefficient,256));
                end
            elseif ~(is_bfile && strcmp('PRES',parm(1:4)))
                netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COMMENT'),dj,di,netstr(['No approved method for delayed-mode qc on ' parm ' is available'], 256));
                netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_EQUATION'),dj,di,netstr(netcdf.getAtt(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_EQUATION'),'_FillValue'),256));
                netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COEFFICIENT'),dj,di,netstr(netcdf.getAtt(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COEFFICIENT'),'_FillValue'),256));
            end
            di(i_parlen)=14;
            try
                netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_DATE'),dj,di,netstr(DATE_CAL,14));
            catch
                netcdf.putVar(f,netcdf.inqVarID(f,'CALIBRATION_DATE'),dj,di,netstr(DATE_CAL,14));
            end
        end
    end
end

%HISTORY_*
%5.3 Recording QC Tests Performed and Failed : update QCP$ FOR raw VISual QC
historyactionid=netcdf.inqVarID(f,'HISTORY_ACTION');
[varname,xtype,dimids]=netcdf.inqVar(f,historyactionid);
clear di dj
for i=1:length(dimids)
    [tr,di(i)]=netcdf.inqDim(f,dimids(i));
    if strcmp(tr,'N_HISTORY')
        i_history=i;
    elseif strcmp(tr,'N_PROF')
        i_prof=i;
    else
        i_parlen=i;
    end
end
dj=di*0;
history_action=squeeze((netcdf.getVar(f,historyactionid)))';
qcp=strmatch('QCP$',history_action(:,1:4));
qcf=strmatch('QCF$',history_action(:,1:4));
di(i_parlen)=16;
if length(qcf)>1 || length(qcp)>1 %MORE THAN ONE QCP/QCF
    warning('More than one QCF$ or/and QCF$');
    pause;
    for ii=1:length(qcp)
        dj(i_history)=qcp(ii)-1;
        di(i_history)=1;
        QCP{ii}=squeeze((netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),dj,di)))';
    end
    for ii=1:length(qcf)
        dj(i_history)=qcf(ii)-1;
        di(i_history)=1;
        QCF{ii}=squeeze((netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),dj,di)))';
    end
    uqcp=unique(QCP);
    uqcf=unique(QCF);
    if length(uqcp)>1 || length(uqcf)>1
        dbstop if error
        error('More than one different QCP/QCF');
    end
end
di(i_history)=1;
if ~isempty(qcp)
    dj(i_history)=qcp(1)-1;
    oldcode=deblank(netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),dj,di)');
else %case when this is the first time we calculate a QCP
    dj(i_history)=0;
    oldcode='0';
end
if ~strcmpi(output_data_mode,'R')
    % TODO: Confirm with Anh that it's OK to leave this out
    netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),dj,di,netstr(decplushex2hex(131072,oldcode),16)'); %means "Wong et al. Correction and Visual QC performed by PI"
    di(i_parlen)=14;
    netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_DATE'),dj,di,netstr(DATE_CAL,14)');
end
if ~isempty(fc) %only if visual failed/>0 raw flag(s) were changed
    %(5.4 Recording changes in values: record change of raw flags
    varswithcf=fieldnames(fc);
    for i=1:size(varswithcf,1)
        varr=varswithcf{i};
        for j=1:length(fc.(varr).pres)
            fc.(varr).oldflag(fc.(varr).oldflag==' ')='0';
            N_HISTORY=N_HISTORY+1;
            dj(i_history)=N_HISTORY-1;
            di(i_history)=1;
            di(i_parlen)=4;
            %zhimin ma has issue appending data to extra dimension.
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_INSTITUTION'),dj,di,netstr('ME',4));
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_STEP'),dj,di,netstr('ARGQ',4));
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'),dj,di,netstr('CF',4));
            di(i_parlen)=14;
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_DATE'),dj,di,netstr(DATE_CAL,di(i_parlen)));
            di(i_parlen)=16;
            try
                netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_PARAMETER'),dj,di,netstr(varr,di(i_parlen)));
            catch
                di(i_parlen)=4;
                netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_PARAMETER'),dj,di,netstr(varr,di(i_parlen)));
            end
            ok=[i_prof i_history];
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_START_PRES'),dj(ok),di(ok),single(round(fc.(varr).pres(j)*1000)/1000));
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_STOP_PRES'),dj(ok),di(ok),single(round(fc.(varr).pres(j)*1000)/1000));
            if fc.(varr).oldflag(j)==32 || fc.(varr).oldflag(j)==0
                fc.(varr).oldflag(j)='1';
                warning('Set missing old qc parm to 1');
            end
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_PREVIOUS_VALUE'),dj(ok),di(ok),single(str2num(fc.(varr).oldflag(j))));
        end
    end
end

%5.1 Recording information about the Delayed Mode QC process
if ~strcmpi(output_data_mode,'R')
    N_HISTORY=N_HISTORY+1;
    dj(i_history)=N_HISTORY-1;
    di(i_history)=1;
    di(i_parlen)=4;
    netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_INSTITUTION'),dj,di,netstr('ME',4));
    netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_STEP'),dj,di,netstr('ARSQ',4));
    if strcmpi(output_data_mode,'R') || isempty(conf)
        netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_SOFTWARE'),dj,di,netstr('',4));
        netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_SOFTWARE_RELEASE'),dj,di,netstr('',4));
    else
        netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_SOFTWARE'),dj,di,netstr(conf.swname,4));
        netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_SOFTWARE_RELEASE'),dj,di,netstr(conf.swv,4));
    end
    netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'),dj,di,netstr('QCCV',4));
    di(i_parlen)=14;
    netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_DATE'),dj,di,netstr(DATE_CAL,14));
    di(i_parlen)=64;
    if strcmpi(output_data_mode,'R') || isempty(conf)
        netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_REFERENCE'),dj,di,netstr('',64));
    else
        netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_REFERENCE'),dj,di,netstr(conf.dbname,64));
    end
end

adj.PRES(adj.PRES==fv1)=nan;
raw.PRES(raw.PRES==fv1)=nan;
ok=rond(adj.PRES(:)-raw.PRES(:),3);
ok=ok(~isnan(ok));
if ~strcmpi(output_data_mode,'R') && length(unique(ok))>1 && max(diff(unique(ok)))>.0011
    unique(ok)
    dbstop if error
    error('Unconstant Pressure Adjustment');
end
netcdf.close(f);
fname=flnm.output;

function newhex=decplushex2hex(dec,hex)
	l(1)=length(dec2bin(dec));
	l(2)=length(dec2bin(hex2dec(hex)));
	a1=dec2bin(dec,max(l))-48; %conversion from char hex to logical binary
	a2=dec2bin(hex2dec(hex),max(l))-48; %conversion from char hex to logical binary
	newhex=dec2hex(bin2dec(char((a1 | a2)+48)),8); %or and conversion from logical binary to char hex again
