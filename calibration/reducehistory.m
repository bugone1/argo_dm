function reducehistory(local_config,floatname)
pathe=[local_config.OUT 'changed' filesep ];
if ~iscell(floatname)
    fl{1}=floatname;
    floatname=fl;
end
for j=1:length(floatname)
    d=dir([pathe '*' floatname{j} '*.nc']);
    for i=1:length(d)
        reducehistory_i([pathe d(i).name]);
    end
end
end

function reducehistory_i(fname)
vals={'INSTITUTION','STEP','SOFTWARE','SOFTWARE_RELEASE','REFERENCE','DATE','ACTION','PARAMETER','PREVIOUS_VALUE','QCTEST','START_PRES','STOP_PRES'};
typ='ccccccccscss';
q=get_rows(fname,vals,typ,[1 3 2]);
[q,qparm,qdat,haschanged]=renameCVQCtoCF(q,vals);
clc
ok=false(size(q));
for i=1:length(q)
    ok(i)=strcmp(q{i}{7}(1:2),'CF');
end
if any(ok)
    haschanged=true;
    nq=getCondensedCFHistory(q(ok),qparm(ok),qdat(ok),vals,fname);
    q=q(~ok);
    for i=1:length(nq)
        le=length(q)+1;
        for j=1:size(nq{i},2)
            q{le}{j}=nq{i}{j};
        end
    end
end
if haschanged
    idate=strmatch('DATE',vals);
    for i=1:length(q)
        dat(i,:)=q{i}{idate};
    end
    [tr,i]=sortrows(dat);
    put_rows(fname,vals,typ,q(i));
end
end

function nq=getCondensedCFHistory(q,qparm,qdat,vals,fname)
nq=[];
nc=netcdf.open(fname,'NOWRITE');
ik=0;
uparm=unique(qparm);

%initialize table;
clear table; 
table(:,1)=round(netcdf.getVar(nc,netcdf.inqVarID(nc,'PRES'),'double')*10^4)/10^4; %create table of pres,parm_qc,qc_time1,qc_time2,..
%stable corresponds to q index
istart=strmatch('START_PRES',vals);
istop=strmatch('STOP_PRES',vals);
iprev=strmatch('PREVIOUS_VALUE',vals);
idate=strmatch('DATE',vals);
iparm=strmatch('PARAMETER',vals);
for k=1:length(uparm) %create parm specific table
    udat=unique(qdat);
    table=table(:,1);
    table(:,2)=netcdf.getVar(nc,netcdf.inqVarID(nc,[strtrim(uparm{k}) '_QC']))-'0';
    clear stable;
    for i=1:length(q)
        if strcmp(q{i}{iparm},uparm{k})
            clear z
            z(1)=str2num(q{i}{istart});
            z(2)=str2num(q{i}{istop});
            z=round(z*10^4)/10^4;
            kk=find(qdat(i)==udat);
            jj=table(:,1)>=z(1) & table(:,1)<=z(2);
            table(jj,kk+2)=deal(q{i}{iprev}-'0');
            stable(jj,kk+2)=i;
        end
    end
    for i=size(table,2):-1:4 %remove successive identical cfs
        for j=1:size(table,1)
            if table(j,i)==table(j,i-1)
                [table(j,i),stable(j,i)]=deal(0);
            end
        end
    end
    %remove last change of flags that are the same flag as now
    notdone=true;
    while notdone
        notdone=false;
        if size(table,2)>2
            for i=1:size(table,1)
                tok=find(table(i,3:end)>0);
                if ~isempty(tok)
                    if table(i,2+tok)==table(i,2)
                        [table(i,2+tok),stable(i,2+tok)]=deal(0);
                        notdone=true;
                    end
                end
            end
        end
    end
    tok=find(any(table(:,3:end)~=0));
    udat=udat(tok);table=table(:,[1 2 2+tok]);stable=stable(:,[1 2 2+tok]);
    for i=3:size(table,2)     %create new history groups
        z=table(:,i);
        dz=diff(z);
        ngroups=[0;find(dz~=0);length(z)];
        for j=1:length(ngroups)-1
            tok=1+(ngroups(j):ngroups(j+1)-1);
            if table(tok(1),i)~=0
                ik=ik+1;
                for aa=1:length(vals)
                    nq{ik}{aa}=q{stable(tok(1),i)}{aa};
                end
                nq{ik}{idate}=datestr(udat(i-2),'yyyymmddHHMMSS');
                nq{ik}{iparm}=uparm{k};
                nq{ik}{istart}=table(tok(1),1);
                nq{ik}{istop}=table(tok(end),1);
            end
        end
    end
end
netcdf.close(nc);
end

function b=get_rows(fname,vnames,typ,dimord)
nc=netcdf.open(fname,'NOWRITE');
for j=1:length(vnames)
    varid=netcdf.inqVarID(nc,['HISTORY_' vnames{j}]);
    a{j}=squeeze(permute(netcdf.getVar(nc,varid),dimord))';
end
netcdf.close(nc);
nd=size(a{j},1);
if nd==1
    nd=size(a{j},2);
end
for j=1:length(a)
    clear t
    temm=a{j};
    for k=1:nd
        rowk=[];
        if typ(j)=='c'
            b{k}{j}=temm(k,:);
        elseif typ(j)=='s'
            b{k}{j}=num2str(temm(k));
        else
            'unknown'
            stop
        end
    end
end
end

function put_rows(fname,vnames,typ,a)
copyfile(fname,[fname '.old']);
resize_dimension('N_HISTORY',length(a),fname);
nc=netcdf.open(fname,'WRITE');
for j=1:length(vnames)
    varid=netcdf.inqVarID(nc,['HISTORY_' vnames{j}]);
    %e=netcdf.getVar(nc,varid);
    clear tem;
    if typ(j)=='c'
        for i=1:length(a)
            tem(:,1,i)=a{i}{j};
        end
    elseif typ(j)=='s'
        for i=1:length(a)
            if ischar(a{i}{j})
                tem(i)=single(str2num(a{i}{j}));
            else
                tem(i)=single(a{i}{j});
            end
        end
    else
        error('Add type');
    end
    netcdf.putVar(nc,varid,tem);
end
netcdf.close(nc);
end

function [q,parm,dat,haschanged]=renameCVQCtoCF(q,vals)
haschanged=false;
iparm=strmatch('PARAMETER',vals);
iaction=strmatch('ACTION',vals);
idate=strmatch('DATE',vals);
for i=1:length(q)
    if strcmp(q{i}{iaction}(1:2),'CV') && length(q{i}{iparm})>5 && strcmp(q{i}{iparm}(5:7),'_QC')
        q{i}{iaction}(2)='F'; %rename CV QC to CF
        q{i}{iparm}(5:7)=' ';
        if ~haschanged haschanged=true;end
    end
    dat(i)=datenum(q{i}{idate},'yyyymmddHHMMSS');
    parm{i}=q{i}{iparm};
    qq=char(q{i});qq=(qq');roww(i,:)=qq(:)';
end
[tr,i]=unique(roww,'rows'); %remove redundant lines
haschanged=length(i)~=length(q);
q=q(i);parm=parm(i);dat=dat(i);
end