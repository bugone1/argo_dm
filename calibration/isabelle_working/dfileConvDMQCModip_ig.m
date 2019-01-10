function nname=dfileConvDMQCModip_ig(fname)
%Routine to convert a D file formatted for GDAC to format recognized by
%MODIP to update database of calibration parameters
%if fname='D4902383_060.nc' new file will be 'nD4902383_060.nc'

nname=['n' fname];

ncid1=netcdf.open(fname,'NOWRITE');
ncid2=netcdf.create(nname,'CLOBBER');

[ndims1,nvars1]=netcdf.inq(ncid1);

alldims={'N_PROF','N_LEVELS','STRING','N_HISTORY','N_PARAM','DATE_TIME','N_CALIB'}; %these will be treated as prefixes
allvars={'PLATFORM_NUMBER','JULD','VERTICAL_SAMPLING_SCHEME','TEMP','PSAL','DOXY','PRES','PARAMETER','SCIENTIFIC_','HISTORY_'}; %these will be treated as prefixes

[junk,ncalib1]=netcdf.inqDim(ncid1,netcdf.inqDimID(ncid1,'N_CALIB')); %length of n_calib in old file
ncalib2=1;  %desired length of n_calib in new file

%keep only history entries associated with the date of the latest ARSQ
history_step=netcdf.getVar(ncid1,netcdf.inqVarID(ncid1,'HISTORY_STEP')); %array of history_steps
history_step=squeeze(history_step(:,end,:))'; %taking last N_CALIB, squeezing the array in 2 D
arsq_index=strmatch('ARSQ',history_step); %finding where the ARSQ related history info is
history_date=netcdf.getVar(ncid1,netcdf.inqVarID(ncid1,'HISTORY_DATE'));history_date=squeeze(history_date(:,end,:))';
dat=unique(history_date(arsq_index,:),'rows'); %find most recent DM QC date
tokeep_history=strmatch(dat,history_date); %vector index of history table entries to keep
nhistory2=length(tokeep_history); %length of n_history in new file


j=0;
for i=0:ndims1-1 %loop on old file dimensions
    [dimname1{i+1}, dimlen] = netcdf.inqDim(ncid1,i); %index of old file dimension names
    if any(strncmp(dimname1{i+1},alldims,length(dimname1{i+1}))) %if this a dimension we're interested in
        j=j+1;
        if strcmp(dimname1{i+1},'N_HISTORY') %we keep only the most recent DM QC info
            dimlen=nhistory2;   %set length of N_HISTORY dimension
        end
        if strcmp(dimname1{i+1},'N_CALIB') %we keep only the last calibration
            dimlen=ncalib2;                 %set length of N_CALIB dimension 
        end
        netcdf.defDim(ncid2,dimname1{i+1},dimlen); %define dimensions in new file
        dimname2{j}=dimname1{i+1};                 %index of new file dimension name
    end
end
for varid1=0:nvars1-1 %loop on old file variables
    [varname1,xtype1,dimids1,natts1] = netcdf.inqVar(ncid1,varid1);
    if any(strncmp(varname1,allvars,length(varname1))) %if this is a variable we're interested in
        [junk,junk,dimids2]=intersect(dimname1(dimids1+1),dimname2,'stable'); %find dimension indices in new file; must respect same dimension order
        varid2=netcdf.defVar(ncid2,varname1,xtype1,dimids2-1); %define variable in new file
        for j=0:natts1-1
            netcdf.copyAtt(ncid1,varid1,netcdf.inqAttName(ncid1,varid1,j),ncid2,varid2);
        end
    end
end
%create machine readable variables
[junk,junk,dimids2]=intersect({'N_PROF','N_PARAM'},dimname2,'stable');
varid2=netcdf.defVar(ncid2,'add_offset',6,dimids2-1); %define variable in new file
netcdf.putAtt(ncid2,varid2,'_FillValue',0); %0 is fill value, an offset of 0 does nothing
varid2=netcdf.defVar(ncid2,'scale_factor',6,dimids2-1); %define variable in new file
netcdf.putAtt(ncid2,varid2,'_FillValue',1); %1 is fill value
netcdf.endDef(ncid2);    %end define mode


for varid1=0:nvars1-1   %loop on old file variables
    [varname1,junk,dimids1] = netcdf.inqVar(ncid1,varid1);
    if any(strncmp(varname1,allvars,length(varname1))) %if this is a variable we're inerested in
        varid2=netcdf.inqVarID(ncid2,varname1);    %find index of variable in new file
        val=netcdf.getVar(ncid1,varid1);          %find value in old file
        ind=strmatch('N_CALIB',char(dimname1{dimids1+1})); %check whether N_CALIB is one of the dimensions
        if ~isempty(ind)                     %if N_CALIB is one of the dimensions
            if ind==3 && ndims(val)==2 && ncalib1==1 %data already squeezed, no need to do anything
            else
                error('edit for new case');        %need to squeeze the data
            end
        end
        ind=strmatch('N_HISTORY',char(dimname1{dimids1+1}));
        if ~isempty(ind)                         %if N_HISTORY is one of the dimensions
            if ind==3 && ndims(val)==3          %case where history is 3rd dimension
                val=val(:,:,tokeep_history);
            elseif ind==2 && ndims(val)==2     %case where history is 2nd dimension
                val=val(:,tokeep_history);
            else                                %need to squeeze the data
                error('edit for new case');
            end
        end
        netcdf.putVar(ncid2,varid2,val);      %store variable in new file
    end
end

%extract coefficients
coeffstrings=netcdf.getVar(ncid2,netcdf.inqVarID(ncid2,'SCIENTIFIC_CALIB_COEFFICIENT'))';
[junk,nparam2]=netcdf.inqDim(ncid2,netcdf.inqDimID(ncid2,'N_PARAM')); %length of n_calib
if size(coeffstrings,1)~=nparam2
    error('dimensions');
end
[junk,nprof2]=netcdf.inqDim(ncid1,netcdf.inqDimID(ncid2,'N_PROF')); %length of n_calib
if nprof2~=1
    error('Edit/Test for case where N_PROF ~= 1');
end
ao=zeros(nprof2,nparam2);
sf=ones(nprof2,nparam2);
for i=1:nparam2
    if startsWith(coeffstrings(i,:),'ADDITIVE COEFFICIENT FOR PRESSURE ADJUSTMENT IS ')
        tem=extractBetween(coeffstrings(i,:),'ADDITIVE COEFFICIENT FOR PRESSURE ADJUSTMENT IS ',' dbar');
        ao(i)=str2num(tem{:});
    elseif startsWith(coeffstrings(i,:),'r=')
        tem=extractBetween(coeffstrings(i,:),'r=',',');
        sf(i)=str2num(tem{:});
    elseif all(coeffstrings(i,:)==' ')
    else
        error('unknown coefficient string');
    end        
end
netcdf.putVar(ncid2,netcdf.inqVarID(ncid2,'add_offset'),ao);
netcdf.putVar(ncid2,netcdf.inqVarID(ncid2,'scale_factor'),sf);
netcdf.close(ncid1);
netcdf.close(ncid2);

if 0 %check/validate
    s=read_nc_generic(fname);
    t=read_nc_generic(nname);
    fn=intersect(fieldnames(t),fieldnames(s));
    for i=1:length(fn)
        clc
        fn{i}
        if all(size(t.(fn{i}))==size(s.(fn{i})))
            d1=t.(fn{i})-s.(fn{i});
            d2=isnan(t.(fn{i})) & ~isnan(s.(fn{i}));
            unique(d1(:))
            unique(d2(:))
            pause
        else
            t.(fn{i})
            s.(fn{i})
            pause
        end
    end
end