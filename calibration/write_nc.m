function write_nc(old_name,t,new_name)
%Reads an Argo profile netCDF file, return a structure s with lower case
%fields corresponding to most netCDF variables
%qc field==1 if visual QC has already been performed on that cycle

vars={'pres','psal','temp','pi_name','dc_reference',...
    'reference_date_time','juld_qc','position_qc','pres_qc','temp_qc',...
    'latitude','longitude','psal_qc','cycle_number','platform_number',...
    'psal_adjusted','temp_adjusted','pres_adjusted',...
    'psal_adjusted_qc','temp_adjusted_qc','pres_adjusted_qc',...
    'psal_adjusted_error','temp_adjusted_error','pres_adjusted_error'};

copyfile(old_name,new_name);
f = netcdf.open(new_name,'write'); % f is the netcdf object
t.juld=t.dates-datenum(t.reference_date_time,'yyyymmddHHMM');
t=rmfield(t,'dates');
[trash,N_HISTORY]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_HISTORY'));
history_action=squeeze((netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'),ones(1,3)-1,[4 1 N_HISTORY])));
history_qctest=squeeze((netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),ones(1,3)-1,[16 1 N_HISTORY])));
qcp=strmatch('QCP$',history_action');
qcf=strmatch('QCF$',history_action');
if length(qcf)>2 || length(qcp)>2 || isempty(qcf) || isempty(qcp)
    dbstop if error
    error(['QCP$/QCF$ problem in ' profile_name]);
end

display (squeeze(history_qctest(:,qcp)'));
tests=dec2bin(hex2dec(deblank(history_qctest(:,qcp)')));
tests=tests(end-1:-1:1); %remove bit 0 and invert bytes
if isfield(t,'qc')
    tests(17)=num2str(t.qc=='1');
    t=rmfield(t,'qc');
end
tests=[tests(end-1:-1:1) 0];
nqcp=dec2hex(bin2dec(tests),8)';
history_qctest(3:10,qcp)=nqcp';

netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),zeros(1,3),[16 1 N_HISTORY],history_qctest);

[tr,tr,dimids]=netcdf.inqVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'));
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
    dj(i)=1;
end
anychange=false;
z=netcdf.getVar(f,netcdf.inqVarID(f,'PRES'));

for i=1:length(vars)
    varr=upper(vars{i});
    vart=vars{i};
    varid=netcdf.inqVarID(f,varr);
    dummy=netcdf.getVar(f,varid);
    if any(dummy(:)~=t.(vart)(:))
        if ~anychange
            anychange=true;
        end
        netcdf.putVar(f,varid,t.(vart)');
        new=t.(vart)';old=dummy;
        k=0; dep=[]; ov=[];
        for j=1:length(new)
            if new(j)~=old(j)
                if j>1 && (new(j)~=new(j-1) || old(j)~=old(j-1))
                    k=k+1;
                    dep(k,1)=z(j);
                    ov(k,1)=old(j);
                    ov(k,2)=new(j);
                elseif j==1
                    k=k+1;
                    dep(k,1)=z(j);
                    ov(k,1)=old(j);
                    ov(k,2)=new(j);
                else
                    dep(k,2)=z(j);
                end
            end
        end
        if ischar(old)
            ov=char(ov);
        end
        if size(dep,2)==1
            dep(:,2)=dep(:,1);
        end
        okkkk=dep(:,2)==0;
        dep(okkkk,2)=dep(okkkk,1);
        for j=1:size(dep,1)
            N_HISTORY=N_HISTORY+1;
            dj(i_history)=N_HISTORY;
            di(i_history)=1;
            di(i_parlen)=4;
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_INSTITUTION'),dj-1,di,netstr('ME',4));
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_STEP'),dj-1,di,netstr('ARGQ',4)); 
            
            if ~isempty(findstr('_qc',varr));
                netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'),dj-1,di,netstr('CF',4));
            else
                netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'),dj-1,di,netstr('CV',4));
            end
            di(i_parlen)=16;
            try
                netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_PARAMETER'),dj-1,di,netstr(varr,di(i_parlen)));
            catch
                di(i_parlen)=4;
                netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_PARAMETER'),dj-1,di,netstr(varr,di(i_parlen)));
            end
            di(i_parlen)=14;
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_DATE'),dj-1,di,datestr(now, 'yyyymmddHHMMSS'));
            ok=[i_prof i_history];
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_START_PRES'),dj(ok)-1,dep(k,1));
            netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_STOP_PRES'),dj(ok)-1,dep(k,2));
            if ischar(t.(vart))
                netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_PREVIOUS_VALUE'),dj(ok)-1,di(ok),single(str2num(ov(j,1))));
            else
                netcdf.putVar(f,netcdf.inqVarID(f,'HISTORY_PREVIOUS_VALUE'),dj(ok)-1,di(ok),single(ov(j,1)));
            end
            

        end
    elseif ~isempty(findstr('adjusted_qc',vart))        
        varid=netcdf.inqVarID(f,varr);
        und=find(vart=='_');
        name_non=vart([1:und(1)-1 und(2):end]);
        if any(t.(vart)~=t.(name_non))
            netcdf.putVar(f,varid,t.(name_non)');
        end
        display(vart);
        if ~isempty(findstr('pres',vart))
            ncprofileQc = squeeze(netcdf.getVar(f,netcdf.inqVarID(f,'PROFILE_PRES_QC')));        
            profile_qc = calculate_profile_qc(t.(name_non));       
          
            if (profile_qc ~= ncprofileQc) 
                netcdf.putVar(f,netcdf.inqVarID(f,'PROFILE_PRES_QC'),profile_qc);                
            end
        end
        if ~isempty(findstr('temp',vart))
            ncprofileQc = squeeze(netcdf.getVar(f,netcdf.inqVarID(f,'PROFILE_TEMP_QC')));        
            profile_qc = calculate_profile_qc(t.(name_non));
            if (profile_qc ~= ncprofileQc)                
                netcdf.putVar(f,netcdf.inqVarID(f,'PROFILE_TEMP_QC'),profile_qc);
            end
        end
        if (findstr('psal',vart))
            ncprofileQc = squeeze(netcdf.getVar(f,netcdf.inqVarID(f,'PROFILE_PSAL_QC')));        
            profile_qc = calculate_profile_qc(t.(name_non));
            if (profile_qc ~= ncprofileQc)                
                netcdf.putVar(f,netcdf.inqVarID(f,'PROFILE_PSAL_QC'),profile_qc);                
            end
        end
    end
    netcdf.putVar(f,netcdf.inqVarID(f,'DATE_UPDATE'),datestr(now, 'yyyymmddHHMMSS'));
end
netcdf.close(f);
