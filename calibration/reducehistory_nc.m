function reducehistory_nc(fname)
nc=netcdf.open(fname,'NOWRITE');
rows=get_rows(nc,{'INSTITUTION','STEP','SOFTWARE','SOFTWARE_RELEASE','REFERENCE','DATE',...
    'ACTION','PARAMETER','PREVIOUS_VALUE','QCTEST'},[1 3 2]);
zz=get_rows(nc,{'START_PRES','STOP_PRES'},[1 3 2]);
z=netcdf.getVar(nc,netcdf.inqVarID(nc,'PRES'),'double');
netcdf.close(nc);

[urows,j]=unique(rows,'rows');
dups=setdiff(1:size(rows,1),j);
kk=0;
tochange=false;
todelz=[];
while ~isempty(dups)
    ok=strmatch(rows(dups(1),:),rows);
    vec=round([zz(ok,1) zz(ok,2)]*10)/10;
    z=round(z*10)/10;
    dups=setdiff(dups,ok);
    [tr,ok1]=intersect(z,vec(1,:));
    [tr,ok2]=intersect(z,vec(2,:));
    [tr,pres]=collapse([ok1(1):ok1(1) ok2(1):ok2(1)]);
    if any(size(pres)~=size(vec)) || any(z(pres(:))~=vec(:))
        tochange=true;
        for k=1:2:length(pres)
            kk=kk+1;
            newz(kk,1)=z(pres(k));
            newz(kk,2)=z(pres(k+1));
            indz(kk)=ok(k);
        end
        todelz=[todelz;ok(2)];
    end
end

ts={'START_PRES','STOP_PRES'};

if tochange
    tokeep=setdiff(1:size(rows,1),todelz);
    copyfile(fname,'../data/temp.nc');
    nc=netcdf.open('../data/temp.nc','WRITE');
    dimid=netcdf.inqDimID(nc,'N_HISTORY');
    clear ok
    for k=1:kk
        for j=1:2
            varid=netcdf.inqVarID(nc,['HISTORY_' ts{j}]);
            tem=netcdf.getVar(nc,varid);
            tem(indz(k))=newz(k,j);
            netcdf.putVar(nc,varid,tem);
        end
    end
    dimid=netcdf.inqDim(nc,dimid);
    netcdf.close(nc);
    if dimid>length(tokeep)
        ncid_in=netcdf.open(fname,'NOWRITE');
        ncid_out=netcdf.create('../data/temp2.nc','WRITE');
        [ncid_in,ncid_out]=resize_dimension(ncid_in,ncid_out,'N_HISTORY',length(tokeep));
        netcdf.close(ncid_in);
        netcdf.close(ncid_out);
        copyfile('../data/temp2.nc','../data/temp.nc')
    end
    nc=netcdf.open(fname,'NOWRITE');
    rows=get_rows(nc,{'INSTITUTION','STEP','SOFTWARE','SOFTWARE_RELEASE','REFERENCE','DATE',...
        'ACTION','PARAMETER','PREVIOUS_VALUE','QCTEST'},[1 3 2]);
    zz=get_rows(nc,'START_PRES','STOP_PRES',[1 3 2]);
    rows
    zz
    pause
    copyfile('temp.nc',fname);
end
end

function [vec,pres]=collapse(in)
vec=in(1);
for i=2:length(in)-1
    b=in(i)-in(i-1)~=1;
    f=in(i+1)-in(i)~=1;
    if b
        if vec(end)~=in(i)
            vec(end+1)=0;
            vec(end+1)=in(i);
        end
    end
    if f
        if vec(end)~=in(i)
            if ~b
                vec(end+1)=1;
            else
                vec(end+1)=0;
            end
            vec(end+1)=in(i);
        end
    end
end
if length(in)>1
    if in(end)-in(end-1)==1
        vec(end+1)=1;
    else
        vec(end+1)=0;
    end
    vec(end+1)=in(end);
end
for k=2:2:length(vec)
    kk=k/2;
    if vec(k)==1
        pres(kk,1)=vec(k-1);
        pres(kk,2)=vec(k+1);
    else
        pres(kk,1)=vec(k-1);
        pres(kk,2)=vec(k-1);
    end
end
if vec(end-1)==0
    pres(end+1,1)=vec(end);
    pres(end,2)=vec(end);
end
end

function rows=get_rows(nc,vnames,dimord)
for j=1:length(vnames)
    varid=netcdf.inqVarID(nc,['HISTORY_' vnames{j}]);
    a{j}=squeeze(permute(netcdf.getVar(nc,varid),dimord))';
end
rows=[];
stri=false;
nd=size(a{j},1);
if nd==1
    nd=size(a{j},2);
end
for k=1:nd
    rowk=[];
    for j=1:length(a)
        clear t
        temm=a{j};
        if size(temm,1)==1
            temm=temm(k);
        else
            temm=temm(k,:);
        end
        if isnumeric(temm) && stri
            temm=num2str(temm);
        end
        if isnumeric(temm)
            rowk(j)=temm;
        else
            stri=true;
            temm(temm==0)=' ';
            rowk=[rowk strtrim(temm)];
        end
    end
    rows(k,1:length(rowk))=rowk;
    if stri
        rows=char(rows);
    end
end
end