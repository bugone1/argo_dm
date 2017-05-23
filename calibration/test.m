function rewrite_nc(flnm,tem,qc,err,CalDate,conf,scical)
varnames={'PRES','TEMP','PSAL','DOXY','TEMP_DOXY'};
adjornot={'_ADJUSTED',''};
copyfile(flnm.input,flnm.output); %create the new copy of the netCDF file
f=netcdf(flnm.output,'write'); % if you don't open f in write mode, you can't modify the dimensions.
fv1=f{'TEMP'}.FillValue_(:);
fv2=f{'SCIENTIFIC_CALIB_EQUATION'}.FillValue_(:);
%header stuff
if isempty(f), error('## Bad output file open operation.'), end;
nowe=now;temptime=nowe+(heuredete(nowe)/24);
DATE_CAL=sprintf('%4.4i%2.2i%2.2i%2.2i%2.2i%2.2i',round(datevec(CalDate)));
VERSION=f{'FORMAT_VERSION'}(:);
if VERSION==2.2;    PAR_LEN=16;
else    PAR_LEN=4;
end
f{'DATE_UPDATE'}(:)=sprintf('%4.4i%2.2i%2.2i%2.2i%2.2i%2.2i',round(datevec(temptime)));
f{'DATA_STATE_INDICATOR'}(:)=netstr('2C+',4);
if datenum(CalDate)-f{'JULD'}(:)-datenum(1950,1,0)>180 %more than 6 months
    f{'DATA_MODE'}(:)='D';
else
    f{'DATA_MODE'}(:)='A';
end;
D = f('N_CALIB'); % increase the number of calibrations and fill new fields
if isempty(D)
    D(:)=1;
else    tempor=D(:);    D(:)=tempor+1;
end
N_HIST=f('N_HISTORY');

%necessary step if re-dimensioning: Feb. 2, 2004
a=f('N_LEVELS');
levels=a(:);
di=levels-length(tem.PRES);
if di>0 %Lenghten vectors if there are more levels
    temfn=fieldnames(tem);
    for i=1:length(temfn)
        tem.(temfn{i})=[tem.(temfn{i}); nan(di,1)];
        tem.(temfn{i})=tem.(temfn{i})(1:levels);
    end
    temfn=fieldnames(qc);
    for i=1:length(temfn)
        qc.(temfn{i}).ADJ=[qc.(temfn{i}).ADJ; ones(di,1)*'4'];
        qc.(temfn{i}).ADJ=char(qc.(temfn{i}).ADJ(1:levels));
        qc.(temfn{i}).RAW=[qc.(temfn{i}).RAW; ones(di,1)*'4'];
        qc.(temfn{i}).RAW=char(qc.(temfn{i}).RAW(1:levels));
    end
    temfn=fieldnames(err);
    for i=1:length(temfn)
        err.(temfn{i})=[err.(temfn{i}); nan(di,1)];
        err.(temfn{i})=err.(temfn{i})(1:levels);
    end
end
%get flags
fc=[];
%go from tem/qc/err objects to raw/adj objects
for i=1:length(varnames) %keep same fields unless they are provided in the structure "tem"
    %VALUES
    varname=varnames{i};
    checkif=f{varname};
    if ~isempty(checkif)
        raw.(varname)=f{varname}(:)';
        if ~isfield(tem,varname)
            adj.(varname)=f{[varname '_ADJUSTED']}(:)';
        else
            adj.(varname)=tem.(varname);
        end
        %FLAGS
        %-raw
        oldrawflags=f{[varname '_QC']}(:);
        raw.([varname '_QC'])=oldrawflags; %take original raw flags
        if isfield(qc,varname)
            tfc=find(qc.(varname).RAW~=oldrawflags); %find which raw flags changed
            if ~isempty(tfc)
                raw.([varname '_QC'])(tfc)=qc.(varname).RAW(tfc); %update changed raw flags
                fc.(varname).pres=tem.PRES(tfc); %create this fc struct for history records later
                fc.(varname).oldflag=oldrawflags(tfc);
            end
            %-adj
            if isfield(qc,varname) && isfield(qc.(varname),'ADJ')
                adj.([varname '_QC'])=qc.(varname).ADJ;
            else
                adj.([varname '_QC'])=f{[varname '_ADJUSTED_QC']}(:);
            end
            %ERR
            adj.([varname '_ERR'])=err.(varname);
        end
    end
end
%make sure that there are no NaNs, only fillvalues. Then that
%corresponding flags to fillvalues are 4. Then that all flags of 4 have
%corresponding fillvalues  !!
%go from raw/adj objects to NetCDF file
for i=1:length(varnames)
    varname=varnames{i};
    checkif=f{varname};
    if ~isempty(checkif)
        ok1=isnan(adj.(varname)); ok2=adj.([varname '_QC'])=='4'; ok3=adj.(varname)==fv1; ok=(ok1|ok2|ok3);
        adj.([varname '_QC'])(ok)='4';adj.(varname)(ok)= fv1;adj.([varname '_ERROR'])(ok)=fv1;
        f{[varname '_ADJUSTED']}(:)=adj.(varname);    %adj value
        f{[varname '_ADJUSTED_QC']}(:)=adj.([varname '_QC']);     %adj flags
        f{[varname '_QC']}(:)=raw.([varname '_QC']); %raw flags
        f{[varname '_ADJUSTED_ERROR']}(:)=adj.([varname '_ERROR']);
    end
end
%Populate PARAMETER and update list of files which do not conform (foranh)
for j=1:size(f{'PARAMETER'},2)
    for i=1:size(f{'PARAMETER'},3)
        parameter=f{'PARAMETER'}(1,j,i,:);
        if all(parameter==32) %Fill parameter field
            fid=fopen('foranh.txt','a');
            flnm.input(flnm.input=='\' | flnm.input=='/')='_';
            fprintf(fid,[flnm.input 13 10]);
            fclose(fid)
            f{'PARAMETER'}(1,j,i,:)=netstr(varnames{i},size(f{'PARAMETER'},4));
        end
    end
end
parameter=f{'PARAMETER'}(:);
parameter=squeeze(parameter(end,:,:));
parameter(parameter==0)=32;
parameter=char(parameter);
%SCIENTIFIC_CALIB_*
for i=1:size(parameter,1)
    avarnames=char(varnames);
    index=strmatch(parameter(i,1:9),avarnames(:,1:9),'exact');
    parm=deblank(parameter(i,:));
    f{'PARAMETER'}(1,D(:),index,:)=netstr(parameter(i,:), PAR_LEN);
    if strcmp('PSAL',parm) || strcmp('PRES',parm)
        if isfield(parm,'equation')
            f{'SCIENTIFIC_CALIB_EQUATION'}(1,D(:),index,:)=netstr(scical.(parm).equation,256);
            f{'SCIENTIFIC_CALIB_COEFFICIENT'}(1,D(:),index,:)=netstr(scical.(parm).coefficient,256);
        else
            f{'SCIENTIFIC_CALIB_EQUATION'}(1,D(:),index,:)=fv2;
            f{'SCIENTIFIC_CALIB_COEFFICIENT'}(1,D(:),index,:)=fv2;
        end
        f{'SCIENTIFIC_CALIB_COMMENT'}(1,D(:),index,:)=netstr(scical.(parm).comment,256);
    else
        f{'SCIENTIFIC_CALIB_COMMENT'}(1,D(:),index,:)=netstr(['No approved method for delayed-mode qc on ' parm ' is available'], 256);
        f{'SCIENTIFIC_CALIB_EQUATION'}(1,D(:),index,:)=f{'SCIENTIFIC_CALIB_EQUATION'}.FillValue_(:);
        f{'SCIENTIFIC_CALIB_COEFFICIENT'}(1,D(:),index,:)=f{'SCIENTIFIC_CALIB_COEFFICIENT'}.FillValue_(:);
    end
    f{'CALIBRATION_DATE'}(1,D(:),index,:)=netstr(DATE_CAL,14);
end
%PERC GOOD
for k=1:size(parameter,1)
    shortname=deblank(parameter(k,:));
    bigname=[shortname adjornot{isempty(f{[shortname '_ADJUSTED']})+1} '_QC'];
    one=f{bigname}(:)=='1' | f{bigname}(:)=='2';
    nonqced=f{bigname}(:)=='0';
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
    f{['PROFILE_' shortname '_QC']}(:)=profparmqc;
    if sum(nonqced)>0 && percgood>0
        error('Mix of QCED/Non-QCED in same profile!')
    end
end

%HISTORY_*
%5.3 Recording QC Tests Performed and Failed : update QCP$ FOR raw VISual QC
history_action=squeeze((f{'HISTORY_ACTION'}(:,1,:)));
qcp=strmatch('QCP$',history_action);
oldcode=f{'HISTORY_QCTEST'}(qcp,1,:)';
f{'HISTORY_QCTEST'}(qcp,1,:)=netstr(decplushex2hex(131072,oldcode),16);%means "Wong et al. Correction and Visual QC performed by PI"
f{'HISTORY_DATE'}(qcp,1,:)=netstr(DATE_CAL,14);
if ~isempty(fc) %only if visual failed/>0 raw flag(s) were changed
    %5.3 Recording QC Tests Performed and Failed : update QCF$ FOR raw VISual QC
    history_action=squeeze((f{'HISTORY_ACTION'}(:,1,:)));
    qcp=strmatch('QCF$',history_action);
    oldcode=f{'HISTORY_QCTEST'}(qcp,1,:)';
    f{'HISTORY_QCTEST'}(qcp,1,:)=netstr(decplushex2hex(131072,oldcode),16);
    f{'HISTORY_DATE'}(qcp,1,:)=netstr(DATE_CAL,14);
    %(5.4 Recording changes in values: record change of raw flags
    varswithcf=fieldnames(fc);
    for i=1:size(varswithcf,2)
        varr=varswithcf{i};
        for j=1:length(fc.(varr).pres)
            NEXT_REC=N_HIST(:)+1;
            f{'HISTORY_INSTITUTION'}(NEXT_REC,1,:)=netstr('ME', 4);
            f{'HISTORY_STEP'}(NEXT_REC,1,:)=netstr('ARGQ', 4);
            f{'HISTORY_DATE'}(NEXT_REC,1,:)=netstr(DATE_CAL,14);
            f{'HISTORY_ACTION'}(NEXT_REC,1,:)=netstr('CF',4);
            f{'HISTORY_PARAMETER'}(NEXT_REC,1,:)=netstr(varr,16);
            f{'HISTORY_START_PRES'}(NEXT_REC,1)=fc.(varr).pres(j);
            f{'HISTORY_STOP_PRES'}(NEXT_REC,1)=fc.(varr).pres(j);
            f{'HISTORY_PREVIOUS_VALUE'}(NEXT_REC,1)=fc.(varr).oldflag(j);
        end
    end
end
%5.1 Recording information about the Delayed Mode QC process
%NEXT_REC=N_HIST(:)+1;
%f{'HISTORY_INSTITUTION'}(NEXT_REC,1,:)=netstr('ME', 4);
%f{'HISTORY_STEP'}(NEXT_REC,1,:)=netstr('ARSQ', 4);
%f{'HISTORY_SOFTWARE'}(NEXT_REC,1,:)=netstr(conf.swname,4);
%f{'HISTORY_SOFTWARE_RELEASE'}(NEXT_REC,1,:)=netstr(conf.swv, 4);
%f{'HISTORY_REFERENCE'}(NEXT_REC,1,:)=netstr(conf.dbname,64);
%f{'HISTORY_DATE'}(NEXT_REC,1,:)=netstr(DATE_CAL,14);
%f{'HISTORY_ACTION'}(NEXT_REC,1,:)=netstr('QCCV', 4);
end

function newhex=decplushex2hex(dec,hex)
a1=dec2bin(dec,25)-48; %conversion from char hex to logical binary
a2=dec2bin(hex2dec(hex),25)-48; %conversion from char hex to logical binary
temphex=dec2hex(bin2dec(char((a1 | a2)+48)),8); %or and conversion from logical binary to char hex again
ok1=(hex~=32 & hex~=0);
ok2=(temphex~=32);
newhex=hex;
newhex(ok1)=temphex(ok2);