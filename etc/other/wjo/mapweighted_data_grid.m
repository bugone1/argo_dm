function [vgrid,vgriderror,vdata,vdataerror]=mapweighted_data_grid(v,posgrid,...
    posdata,regions,rank,gs,ts,q,s,e)

% **********************************************************************
% Objective mapping routine - need findindices.m and covarxy.m.
% The 6th column of "regions" is empty - it was intended for variable
% scales and variable signal/noise ratios for each region but it didn't
% quite get implemented. (A. Wong, 13 Feb 2003)
%
%Minor optimizations by MO, made it 0.25 instead of 0.5
% **********************************************************************
%
% Inputs:
%
% v=data   rank*m1 matrix of data (rank is the number of repeated data). This does not take NaN's.
% posgrid  m2*3 matrix of grid locations [latitude,longitude,dates]
% posdata  m1*3 matrix of data locations [latitude,longitude,dates]
% regions  m3*6 matrix defining mapping regions
%               [lattopleft,longtopleft,latbottomright,longbottomright,overlap]
% rank     scalar number of repeats data sets to be mapped
% gs       scalar longitude scale (in degrees)
% ts       scalar latitude scale (in degrees)
% q        scalar time scale (in years)
% s        scalar signal level (in variance terms)
% e        scalar noise level (in variance terms)
% 
% Outputs:
% 
% vgrid    m2*rank matrix of mapped fields (n is the number of repeated data)
% vgriderror  m2*rank matrix of error estimates of the mapped data 
%             (assumed statistics)
% vdata    m1*rank matrix of mapped fields on original data locations
% vdataerror  m1*rank matric of error estimate of the mapped data
%             (assumed statitics)
%
% Purpose: An optimal mapping routine, taking data measured in arbitrary
%          geographic locations and mapping these data onto a more regular
%          grid.  This routine is designed to handle the common problems
%          associated with large data sets, by mapping only in predetermined
%          regions, rather than using all the data globally.  As should 
%          happen in every mapping problem the data are both mapped onto
%          the prescribed grid, and the data locations (so that the mapped
%          field can be checked with the original data to ensure that the 
%          statistics are valid and consistent.

[m,n]=size(v);
[nnn,i]=size(posgrid);
[mmm,i]=size(posdata);
nregions=size(regions);

[vdata,vdataeroor]=deal(zeros(mmm,rank));
%vdataerror=vdata; <MO>
[vgrid,vgriderror]=deal(zeros(nnn,rank));
%vgriderror=vgrid; <MO>

% Create the data-data covariance matrix ----------

for ii=1:nregions(1)
    overlap=regions(ii,5);
    p=regions(ii,6);
    [gridindex,dataindex]=findindices(regions(ii,1:4),posgrid,posdata,overlap);
    [nn,i]=size(posgrid(gridindex));
    [mm,i]=size(posdata(dataindex));
    [Cdd] = s*covarxy(posdata(dataindex,:),posdata(dataindex,:),gs,ts,q);
    Cdd(1:mm+1:mm^2+mm)=diag(Cdd)+e*ones(mm,1);    % data-data cov. matrix
    Cdd=inv(Cdd);
    
    % calculate the objectively mapped fields on data and grid
    % the weighted mean field is removed first, then added back on ------
    
    for i=1:rank
        
        for j=1:mm, % map to posdata -----
            if j<=mm
            weights = covarxy(posdata(dataindex(j),:),posdata(dataindex,:),gs,ts,q);
            weighted_meanv = sum(weights.*v)/sum(weights);
            %<mo>minor optimizations; make each instance 5 times faster (0.01 instead of 0.05)
            %wght = Cdd*( v(i,dataindex)-weighted_meanv*ones(1,length(dataindex)) )';
            [Cmd] = s*covarxy(posdata(dataindex(j),:),posdata(dataindex,:),gs,ts,q);
            CmdCdd=Cmd*Cdd; %mo
            Cmdwght = CmdCdd*( v(i,dataindex)-weighted_meanv*ones(1,length(dataindex)) )'; %mo
            %[vdata(dataindex(j),i)] = Cmd*wght + weighted_meanv;
            [vdata(dataindex(j),i)] = Cmdwght + weighted_meanv; %mo
            %[vdataerror(dataindex(j),i)]=sqrt(s-Cmd*Cdd*Cmd');
            [vdataerror(dataindex(j),i)]=sqrt(s-CmdCdd*Cmd'); %mo
        end
            
        end
        
        for j=1:nn, % map to posgrid -----
            weights = covarxy(posgrid(gridindex(j),:),posdata(dataindex,:),gs,ts,q);
            weighted_meanv = sum(weights.*v)/sum(weights);
            %<mo>minor optimizations; make each instance 5 times faster (0.01 instead of 0.05)
            %wght = Cdd*( v(i,dataindex)-weighted_meanv*ones(1,length(dataindex)) )';            
            [Cmd] = s*covarxy(posgrid(gridindex(j),:),posdata(dataindex,:),gs,ts,q);
            CmdCdd=Cmd*Cdd; %mo
            Cmdwght = CmdCdd*( v(i,dataindex)-weighted_meanv*ones(1,length(dataindex)) )';            %mo
            %[vgrid(gridindex(j),i)] = Cmd*wght + weighted_meanv;
            [vgrid(gridindex(j),i)] = Cmdwght + weighted_meanv; %mo
            %[vgriderror(gridindex(j),i)]=sqrt(s-Cmd*Cdd*Cmd');
            [vgriderror(gridindex(j),i)]=sqrt(s-CmdCdd*Cmd'); %mo
        end
    end
end

return