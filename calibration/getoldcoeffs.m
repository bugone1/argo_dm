function oldcoeff=getoldcoeffs(fname)
pos=find(fname==filesep);
pathe=fname(1:pos(end));
ingested_flnm=dir(fname);
oldcoeff=zeros(size(ingested_flnm));
ftc={'SCIENTIFIC_CALIB_COEFFICIENT','SCIENTIFIC_CALIB_EQUATION','SCIENTIFIC_CALIB_COMMENT','CALIBRATION_DATE'};
ndd=[256 256 256 14];
for j=1:length(ingested_flnm)
    input_flnm=[pathe ingested_flnm(j).name];
    nc=netcdf.open(input_flnm,'NOWRITE');
    [trash,n_calib(j)]=netcdf.inqDim(nc,netcdf.inqDimID(nc,'N_CALIB'));
    [trash,n_param]=netcdf.inqDim(nc,netcdf.inqDimID(nc,'N_PARAM'));
    try
        iparms=netcdf.getVar(nc,netcdf.inqVarID(nc,'STATION_PARAMETERS'),[1 1 1]-1,[16 n_param 1])';
    catch
        iparms=netcdf.getVar(nc,netcdf.inqVarID(nc,'STATION_PARAMETERS'),[1 1 1]-1,[4 n_param 1])';
    end
    if ~strmatch(iparms(1,1:4),'PRES') || ~strmatch(iparms(2,1:4),'TEMP')
        error('unusual parms');
    end
    parid=netcdf.inqVarID(nc,'PARAMETER');
    try
        parms=netcdf.getVar(nc,parid,[1 1 n_calib(j) 1]-1,[16 n_param 1 1])';
    catch
        parms=netcdf.getVar(nc,parid,[1 1 n_calib(j) 1]-1,[4 n_param 1 1])';
    end
    parms(parms==0)=32;
    if any(~any(parms'~=32))
        [tr,a,b]=intersect(parms,iparms,'rows');
        nc=netcdf.open(input_flnm,'WRITE');
        for o=1:length(ftc)
            varidt=netcdf.inqVarID(nc,ftc{o});
            tem1=netcdf.getVar(nc,varidt);
            tem2=char(tem1*0+32);
            if ndims(tem1)==2
                tem2(:,b)=tem1(:,a);
            else
                tem2(:,b,:)=tem1(:,a,:);
            end
        end
        netcdf.putVar(nc,varidt,tem2);
        netcdf.close(nc)
        nc=netcdf.open(input_flnm,'NOWRITE');
        parms
        yn=input('OK to fill empty parms (1=yes)');
        if yn==1
            if size(parms,1)==4
                parms={'PRES','TEMP','PSAL','DOXY'};
            elseif size(parms,1)==3
                parms={'PRES','TEMP','PSAL'};
            end
            parms=char(parms);
            parms(:,5:16)=' ';
            netcdf.close(nc)
            nc=netcdf.open(input_flnm,'WRITE');
            netcdf.putvar(nc,parid,parms');
            netcdf.close(nc)
            nc=netcdf.open(input_flnm,'NOWRITE');
        end
    end
    [tr,n_param]=intersect(parms(:,1:4),'PSAL','rows');
    comm=deblank(netcdf.getVar(nc,netcdf.inqVarID(nc,'SCIENTIFIC_CALIB_COEFFICIENT'),[1 n_param n_calib(j) 1]-1,[256 1 1 1]))';
    netcdf.close(nc);
    if isempty(comm)
        oldcoeff(j)=nan;
    else
        keyw='conductivity is';
        if isempty(findstr(lower(comm),keyw))
            keyw='r=';
        end
        virgule=find(comm==',');
        if isempty(virgule)
            virgule=length(comm);
        end
        oldcoeff(j)=str2num(comm((findstr(lower(comm),keyw)+length(keyw):virgule-1)));
    end
end
if sum(diff(n_calib)>1)>0
    warning('Some cycles have been calibrated more often than others');
    pause
end