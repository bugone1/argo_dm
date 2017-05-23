nn=[17 22 26 32 38 73 76];

for J=1:length(nn)
    dd=dir(['*4900633_0' num2str(nn(J)) '.nc']);
    if lower(dd(1).name(1))=='r';
        system(['rename ' dd(1).name ' ' 'D' dd(1).name(2:end)]);
    end
end
    nc=netcdf.open(dd(1).name,'WRITE');
    varnames={'TEMP','PSAL','PRES'};
    for i=1:length(varnames)
        raw.(varnames{i})=netcdf.getVar(nc,netcdf.inqVarID(nc,[varnames{i}]),'double');
        adj.(varnames{i})=netcdf.getVar(nc,netcdf.inqVarID(nc,[varnames{i} '_ADJUSTED']),'double');
        adj.([varnames{i} '_ERR'])=netcdf.getVar(nc,netcdf.inqVarID(nc,[varnames{i} '_ADJUSTED_ERROR']),'double');
        adj.([varnames{i} '_QC'])=netcdf.getVar(nc,netcdf.inqVarID(nc,[varnames{i} '_QC']),'char');
    end
    fv1=netcdf.getatt(nc,netcdf.inqVarID(nc,'TEMP'),'_FillValue');
    [tr,i,j]=intersect(rond(str2num(num2str(raw.PRES)),2),rond(str2num(num2str(adj.PRES)),2));
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
        checkif=netcdf.getVar(nc,netcdf.inqVarID(nc,varname));
        if ~isempty(checkif)
            ok1=isnan(adj.(varname)(:)); ok2=adj.([varname '_QC'])(:)=='4'; ok3=adj.(varname)(:)==fv1;
            ok=(ok1|ok2|ok3);
            adj.([varname '_QC'])(ok')='4';adj.(varname)(ok)= fv1;adj.([varname '_ERR'])(ok)=fv1;
            netcdf.putvar(nc,netcdf.inqVarID(nc,[varname '_ADJUSTED']),adj.(varname));
            netcdf.putvar(nc,netcdf.inqVarID(nc,[varname '_ADJUSTED_QC']),adj.([varname '_QC']));     %adj flags
            netcdf.putvar(nc,netcdf.inqVarID(nc,[varname '_ADJUSTED_ERROR']),adj.([varname '_ERR']));
        end
    end
    netcdf.close(nc)
end