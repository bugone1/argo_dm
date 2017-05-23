function [scical,h]=getcomments(profile_name)
profile_name
f=netcdf.open(profile_name,'NOWRITE');

[trash,N_CALIB]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_CALIB'));
[trash,N_PARAM]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_PARAM'));
[trash,N_HISTORY]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_HISTORY'));
parameterid=netcdf.inqVarID(f,'PARAMETER');
[varname,xtype,dimids]=netcdf.inqVar(f,parameterid);
clear di dj
for i=1:length(dimids)
    [tr,di(i)]=netcdf.inqDim(f,dimids(i));
    if strcmp(tr,'N_CALIB')
        i_calib=i;
    elseif strcmp(tr,'N_PARAM')
        i_param=i;
    elseif strcmp(tr,'N_PROF')
        i_prof=i;
    else
        i_parlen=i;
    end
    dj(i)=1;
end
dj(i_calib)=N_CALIB;
di(i_calib)=1;
di(i_parlen)=16;
di(i_param)=N_PARAM;
try
    parms=netcdf.getVar(f,parameterid,dj-1,di)';
catch
    di(i_parlen)=4;
    parms=netcdf.getVar(f,parameterid,dj-1,di)';
end

[varname,xtype,dimids]=netcdf.inqVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COMMENT'));
clear di dj
for i=1:length(dimids)
    [tr,di(i)]=netcdf.inqDim(f,dimids(i));
    if strcmp(tr,'N_CALIB')
        i_calib=i;
    elseif strcmp(tr,'N_PARAM')
        i_param=i;
    elseif strcmp(tr,'N_PROF')
        i_prof=i;
    elseif strcmp(tr,'N_HISTORY')
        i_prof=i;
    else
        i_parlen=i;
    end
    dj(i)=1;
end
di(i_param)=1;
di(i_calib)=1;
for j=1:N_CALIB
    dj(i_calib)=j;
    for i=1:N_PARAM
        dj(i_param)=i;
        parm=deblank(parms(i,:));
        di(i_parlen)=256;
        scical.(parm)(j).comment=netcdf.getVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COMMENT'),dj-1,di);
        scical.(parm)(j).equation=netcdf.getVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_EQUATION'),dj-1,di);
        tem=deblank(netcdf.getVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COEFFICIENT'),dj-1,di));
        if ~isempty(tem)&&all(tem==0)
            dbstop if error
            error('alltem==0');
        end
        tem(tem==0)='±';
        scical.(parm)(j).coefficient=char(tem);
        scical.(parm)(j).cyc=netcdf.getVar(f,netcdf.inqVarID(f,'CYCLE_NUMBER'));
        di(i_parlen)=14;
        try
            ymd=netcdf.getVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_DATE'),dj-1,di)';
        catch
            ymd=netcdf.getVar(f,netcdf.inqVarID(f,'CALIBRATION_DATE'),dj-1,di)';
        end
        scical.(parm)(j).sdn=datenum(str2num(ymd(1:4)),str2num(ymd(5:6)),str2num(ymd(7:8)),str2num(ymd(9:10)),str2num(ymd(11:12)),str2num(ymd(13:14)));
    end
end

[varname,xtype,dimids]=netcdf.inqVar(f,netcdf.inqVarID(f,'HISTORY_STEP'));
clear di dj
for i=1:length(dimids)
    [tr,di(i)]=netcdf.inqDim(f,dimids(i))
    if strcmp(tr,'N_PROF')
        i_prof=i;
    elseif strcmp(tr,'N_HISTORY')
        i_history=i;
    else
        i_parlen=i;
    end
    dj(i)=1;
end
di(i_history)=1;
ok=[i_prof i_history];
for i=1:N_HISTORY
    di(i_parlen)=4;
    dj(i_history)=i;
    history(i).step=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_STEP'),dj-1,di);
    history(i).software=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_SOFTWARE'),dj-1,di);
    history(i).software_release=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_SOFTWARE_RELEASE'),dj-1,di);
    history(i).institution=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_INSTITUTION'),dj-1,di);
    history(i).action=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'),dj-1,di);
    di(i_parlen)=64;
    history(i).reference=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_REFERENCE'),dj-1,di);
    di(i_parlen)=14;
    history(i).date=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_DATE'),dj-1,di);
    di(i_parlen)=16;
    try
    history(i).parameter=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_PARAMETER'),dj-1,di);
    catch
            di(i_parlen)=4;
        history(i).parameter=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_PARAMETER'),dj-1,di);        
    end
    history(i).qc_test=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),dj-1,di);
    history(i).start_pres=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_START_PRES'),dj(ok)-1,di(ok));
    history(i).stop_pres=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_STOP_PRES'),dj(ok)-1,di(ok));
    history(i).previous_value=netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_PREVIOUS_VALUE'),dj(ok)-1,di(ok));
end
h.history=history;
netcdf.close(f);

if isfield(scical,'OTMP')
    scical.TEMP_DOXY=scical.OTMP;
    scical=rmfield(scical,'OTMP');
end
