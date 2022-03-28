addpath('w:\seawater');
if ~ispc
    addpath('/u01/rapps/seawater');
end
set(0,'defaultaxesnextplot','add')
set(0,'defaultfigurenextplot','add')
clc;
if ~exist('argu','var')
    argu=[];
end
keep argu
local_config=load_configuration('local_OW.txt');
if ispc
    %    local_config=bugzilla2pc(local_config);
    local_config=xp1152pc(local_config);
end
lo_system_configuration=load_configuration([local_config.BASE 'config_ow.txt']);
if ispc
    %    lo_system_configuration=bugzilla2pc(lo_system_configuration);
    lo_system_configuration=xp1152pc(lo_system_configuration);
    
end
[filestoprocess,i]=deal(0);
while ~isempty(filestoprocess)
    i=i+1;
    [filestoprocess,floatnames{i},ow]=menudmqc(local_config,lo_system_configuration,argu);
    if ~isempty(filestoprocess)
        if ow(2)
            %set(0,'defaultfigureWindowStyle','modal')
            presMain(local_config,lo_system_configuration,filestoprocess,floatnames{i}); %find pressure correction
            interactive_qc(local_config,filestoprocess); %visual qc
            create_source_files(local_config,lo_system_configuration,floatnames{i});
            close all
        end
        if ow(3)
            cd(local_config.MATLAB)
            argo_calibration(lo_system_configuration,floatnames(i));% new profiles are mapped and calibrated in this program from Annie Wong
            cd(local_config.BASE)
            close all
        end
        if ow(4)
            set(0,'defaultfigureWindowStyle','normal')
            viewplots(lo_system_configuration,local_config,floatnames{i});
        end
        if ow(5)
            reducehistory(local_config,floatnames{i});
        end
        if ow(6)
            publishtoweb(local_config,lo_system_configuration,floatnames{i},1);
        end
    end
end

if 0
    
    %remove the blank before ":"
    changed=0;
    j=netcdf.getVar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COMMENT'));
    for jj=1:size(j,2)
        for kk=1:size(j,3)
            str=squeeze(j(:,jj,kk))';
            if ~isempty(strfind(str,'TNPD :'))
                j(1:end-1,jj,kk)=j([1:4 6:end],jj,kk);
                j(end,jj,kk)=' ';
                changed=1;
            end
        end
    end
    if changed
        netcdf.close(f)
        ff = netcdf.open(profile_name,'write'); % f is the netcdf object
        netcdf.putvar(f,netcdf.inqVarID(f,'SCIENTIFIC_CALIB_COMMENT'),j);
        netcdf.close(ff)
        f = netcdf.open(profile_name,'nowrite'); % f is the netcdf object
    end
end