function fname=rewrite_nc(flnm,tem,qc,err,CalDate,conf,scical,PRES)
ovarnames={'PRES','TEMP','PSAL','DOXY','TEMP_DOXY','BPHASE_DOXY'};
adjornot={'_ADJUSTED',''};
fe=netcdf.open(flnm.input,'NOWRITE');
[foo,N_CALIB] = netcdf.inqDim(fe,netcdf.inqDimID(fe,'N_CALIB'));
clear foo;
scc=netcdf.getVar(fe,netcdf.inqVarID(fe,'SCIENTIFIC_CALIB_COMMENT'));
netcdf.close(fe);
ok=find(flnm.output==filesep);
flnm.output(ok(end)+1)='D';
%copy the netCDF file and redimension N_CALIB; if been calibrated before

dec=0;
for i=1:size(scc,3)
    uscc=unique(lower(scc(:,:,i)));
    if all(uscc=='a' | uscc=='n' | uscc=='/' | uscc==' ')
        dec=dec+1;
    end
end
if N_CALIB==dec
    dec=N_CALIB-1;
end
copy_nc_redim(flnm.input,flnm.output,'N_CALIB',-dec);

%open file in write mode
f=netcdf.open(flnm.output,'WRITE');
try
    netcdf.inqVarID(f,'OTMP')
    'OTMP'
    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP'),'TEMP_DOXY');
    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP_QC'),'TEMP_DOXY_QC');
    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP_ADJUSTED'),'TEMP_DOXY_ADJUSTED');
    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP_ADJUSTED_QC'),'TEMP_DOXY_ADJUSTED_QC');
    netcdf.renameVar(f,netcdf.inqVarID(f,'OTMP_ADJUSTED_ERROR'),'TEMP_DOXY_ADJUSTED_ERROR');    
catch
end

fv1=netcdf.getAtt(f,netcdf.inqVarID(f,'TEMP'),'_FillValue');
%header stuff
nowe=now;temptime=nowe+(heuredete(nowe)/24);
DATE_CAL=CalDate;
PAR_LEN=4+12*double(str2num(netcdf.getVar(f,netcdf.inqVarID(f,'FORMAT_VERSION'))')==2.2);
netcdf.putVar(f,netcdf.inqVarID(f,'DATE_UPDATE'),datestr(temptime,'yyyymmddHHMMSS'));
netcdf.putVar(f,netcdf.inqVarID(f,'DATA_STATE_INDICATOR'),netstr('2C+',4));
netcdf.putVar(f,netcdf.inqVarID(f,'DATA_MODE'),'D');
[trash,N_HISTORY]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_HISTORY'));
[trash,N_CALIB]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_CALIB'));
[trash,N_LEVELS]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_LEVELS'));
[trash,N_PARAM]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_PARAM'));

di=N_LEVELS-length(tem.PRES);
if di>0 %Lenghten vectors if there are more levels
    temfn=fieldnames(tem);
    for i=1:length(temfn)
        tem.(temfn{i})=[tem.(temfn{i}); nan(di,1)];
        tem.(temfn{i})=tem.(temfn{i})(1:N_LEVELS);
    end
    temfn=fieldnames(qc);
    for i=1:length(temfn)
        qc.(temfn{i}).ADJ=[qc.(temfn{i}).ADJ(:); ones(di,1)*'4'];
        qc.(temfn{i}).ADJ=char(qc.(temfn{i}).ADJ(1:N_LEVELS));
        qc.(temfn{i}).RAW=[qc.(temfn{i}).RAW(:); ones(di,1)*'4'];
        qc.(temfn{i}).RAW=char(qc.(temfn{i}).RAW(1:N_LEVELS));
    end
    temfn=fieldnames(err);
    for i=1:length(temfn)
        err.(temfn{i})=[err.(temfn{i}); nan(di,1)];
        err.(temfn{i})=err.(temfn{i})(1:N_LEVELS);
    end
end
fc=[];
%Only keep vars that are present in file
[ndims,nvars] = netcdf.inq(f);
for i=1:nvars
    varnamesf{i}=netcdf.inqVar(f,i-1);
end
varnames=intersect(ovarnames,varnamesf);
for i=1:length(varnames) %keep same fields unless they are provided in the structure "tem"
    varname=varnames{i};
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
            adj.(varname)=netcdf.getVar(f,varid)';
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
                adj.([varname '_QC'])=netcdf.getVar(f,netcdf.inqVarID([varname '_ADJUSTED_QC']));
            end
            %ERR
            adj.([varname '_ERR'])=err.(varname);
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
fn=fieldnames(adj);
for k=1:length(fn)
    clear t
    t(ok1)=adj.(fn{k})(ok2);
    t(j)=adj.(fn{k})(i);
    adj.(fn{k})=t;
end
for i=1:length(varnames)
    varname=varnames{i};
    checkif=netcdf.getVar(f,netcdf.inqVarID(f,varname));
    if ~isempty(checkif)
        ok1=isnan(adj.(varname)(:)); ok2=adj.([varname '_QC'])(:)=='4'; ok3=adj.(varname)(:)==fv1;
        ok=(ok1|ok2|ok3);
        adj.([varname '_QC'])(ok')='4';adj.(varname)(ok)= fv1;adj.([varname '_ERR'])(ok)=fv1;
        netcdf.putVar(f,netcdf.inqVarID(f,[varname '_ADJUSTED']),adj.(varname));
        netcdf.putVar(f,netcdf.inqVarID(f,[varname '_ADJUSTED_QC']),adj.([varname '_QC']));     %adj flags
        netcdf.putVar(f,netcdf.inqVarID(f,[varname '_QC']),raw.([varname '_QC'])); %raw flags
        netcdf.putVar(f,netcdf.inqVarID(f,[varname '_ADJUSTED_ERROR']),adj.([varname '_ERR']));
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
oparms=netcdf.getVar(f,netcdf.inqVarID(f,'STATION_PARAMETERS'))';
ndi(i_calib)=1;
parms=netcdf.getVar(f,parameterid,dj,ndi);
if isempty(strtrim(parms(:)))
    netcdf.putVar(f,parameterid,dj,ndi,oparms');
end
%then fill next ones
for j=2:di(i_calib)
    parms=netcdf.getVar(f,parameterid,dj,ndi);
    ndj(i_calib)=j-1;
    netcdf.putVar(f,parameterid,ndj,ndi,parms);
end

%Populate SCIENTIFIC_CALIB_* columns for new N_CALIB
%SCIENTIFIC_CALIB_*
for i=1:N_PARAM
    dj(i_param)=i-1;
    di(i_parlen)=PAR_LEN;
    di(i_param)=1;
    parm=deblank(netcdf.getVar(f,parameterid,dj,di)');
    if ~strcmp(parm,'OTMP') && ~strcmp(parm,'BPHA')
        %PERC GOOD
        bigname=[parm adjornot{isempty(netcdf.getVar(f,netcdf.inqVarID(f,[parm '_ADJUSTED'])))+1} '_QC'];
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
        netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COMMENT'),dj,di,netstr(['No approved method for delayed-mode qc on ' parm ' is available'], 256));
        netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_EQUATION'),dj,di,netstr(netcdf.getAtt(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_EQUATION'),'_FillValue'),256));
        netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COEFFICIENT'),dj,di,netstr(netcdf.getAtt(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COEFFICIENT'),'_FillValue'),256));
        if strcmp('PSAL',parm(1:4)) || strcmp('PRES',parm(1:4))
            netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COMMENT'),dj,di,netstr(scical.(parm).comment,256));
            if isfield(scical.(parm),'equation')
                netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_EQUATION'),dj,di,netstr(scical.(parm).equation,256));
                netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COEFFICIENT'),dj,di,netstr(scical.(parm).coefficient,256));
            end
        end
        di(i_parlen)=14;
        try
            netcdf.putVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_DATE'),dj,di,netstr(DATE_CAL,14));
        catch
            netcdf.putVar(f,netcdf.inqVarID(f,'CALIBRATION_DATE'),dj,di,netstr(DATE_CAL,14));
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
netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),dj,di,netstr(decplushex2hex(131072,oldcode),16)'); %means "Wong et al. Correction and Visual QC performed by PI"
di(i_parlen)=14;
netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_DATE'),dj,di,netstr(DATE_CAL,14)');
if ~isempty(fc) %only if visual failed/>0 raw flag(s) were changed
    %(5.4 Recording changes in values: record change of raw flags
    varswithcf=fieldnames(fc);
    for i=1:size(varswithcf,2)
        varr=varswithcf{i};
        for j=1:length(fc.(varr).pres)
            fc.(varr).oldflag(fc.(varr).oldflag==' ')='0';
            N_HISTORY=N_HISTORY+1;
            dj(i_history)=N_HISTORY-1;
            di(i_history)=1;
            di(i_parlen)=4;
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
N_HISTORY=N_HISTORY+1;
dj(i_history)=N_HISTORY-1;
di(i_history)=1;

di(i_parlen)=4;
netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_INSTITUTION'),dj,di,netstr('ME',4));
netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_STEP'),dj,di,netstr('ARSQ',4));
netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_SOFTWARE'),dj,di,netstr(conf.swname,4));
netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_SOFTWARE_RELEASE'),dj,di,netstr(conf.swv,4));
netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'),dj,di,netstr('QCCV',4));
di(i_parlen)=14;
netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_DATE'),dj,di,netstr(DATE_CAL,14));
di(i_parlen)=64;
netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_REFERENCE'),dj,di,netstr(conf.dbname,64));

adj.PRES(adj.PRES==fv1)=nan;
raw.PRES(raw.PRES==fv1)=nan;
ok=rond(adj.PRES(:)-raw.PRES(:),3);
ok=ok(~isnan(ok));
if length(unique(ok))>1 && max(diff(unique(ok)))>.0011
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


%-------------------------------
%for j=1:length(f('N_CALIB')) %did this to help Anh for a while but I think
%it,s ok now
%    for i=1:size(parms,1)
%        tem=netcdf.getVar(f,netcdf,inqdimid(f,'SCIENTIFIC_CALIB_COEFFICIENT'),[1 j i 1]-1,[1 1 1 256]);
%        tem(tem==0)=32;
%        netcdf.putVar(f,netcdf,inqdimid(f,'SCIENTIFIC_CALIB_COEFFICIENT'),[1 j i 1]-1,[1 1 1 256],char(tem));
%        tem=netcdf.getVar(f,netcdf,inqdimid(f,'SCIENTIFIC_CALIB_COMMENT'),[1 j i 1]-1,[1 1 1 256]);
%        tem(tem==0)=32;
%        netcdf.putVar(f,netcdf,inqdimid(f,'SCIENTIFIC_CALIB_COMMENT'),[1 j i 1]-1,[1 1 1 256],char(tem));
%        tem=netcdf.getVar(f,netcdf,inqdimid(f,'SCIENTIFIC_CALIB_EQUATION'),[1 j i 1]-1,[1 1 1 256]);
%        tem(tem==0)=32;
%        netcdf.putVar(f,netcdf,inqdimid(f,'SCIENTIFIC_CALIB_EQUATION'),[1 j i 1]-1,[1 1 1 256],char(tem));
%    end
%end