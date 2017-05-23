
function [vgrid,vgriderror,vdata,vdataerror]=map_data_grid(v,posgrid,...
    posdata,regions,rank,gs,ts,q,s,e)

% **********************************************************************
% Objective mapping routine - need findindices.m and covarxy.m.
% The 6th column of "regions" is empty - it was intended for variable
% scales and variable signal/noise ratios for each region but it didn't
% quite get implemented. (A.Wong, 13 April 2000)
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
%
% Notes for the apprehensive:
% 1) The rank in many applications is one.  Sometimes when two or more data
%    fields are to be mapped using the same statistics (eg longitude and
%    latitude spatial scales, signal and noise levels) large savings can
%    be obtained because the data-data covaiance function doesnot have 
%    to be reconstructed.
%
% 2) Regions matrix is especially valueable when the data set has to be
%    broken into small regions.  The regions are defined by a row of this
%    matrix, defining the top lefthand corner, and the bottom left hand
%    corner.  The overlap parameter controls the amount of overlap of each
%    of the data regions.  The overlap is helpful because it helps eliminate
%    edge effects that occur at the edge of regions.  Warning, if the
%    overlap parameter is too large the number of data will increase 
%    dramatically, very dramatically slowing the code.  In problems
%    where there are less than 1000 data pts and grid points it is simpler
%    define just one region that includes all the data.
%
% 3) The data donot have to be sorted into any order, and the returned data
%    correspond to the ordering specified in the posgrid and posdata 
%    variables.
%
% 4) Possible improvements would be to allow variable (i) signal, noise,
%    latitude, longitude and overlap scales.
%
% Author: N.L Bindoff
% Date: 24 April 1994
%
%
[m,n]=size(v);
%
% Set aside the memory that I need for this mapping
%
[nnn,i]=size(posgrid);
[mmm,i]=size(posdata);
vdata=zeros(mmm,rank);
vdataerror=vdata;
vgrid=zeros(nnn,rank);
vgriderror=vgrid;
%
% Create the data-data covariance function.  In this case it is the
% same for all data so it is done just once.
%
tic;
nregions=size(regions);
for ii=1:nregions(1)
	regiontime=toc;
	overlap=regions(ii,5);
%	overlap=1.0
	p=regions(ii,6);
%	disp(['REGION ' num2str(ii)])
	[gridindex,dataindex]=findindices(regions(ii,1:4),posgrid,posdata,overlap);
%	disp(['Number of grid and data points',num2str(length(gridindex)),...
%		', ' num2str(length(dataindex))])
%	disp('Creating data covariance matrices')
	[nn,i]=size(posgrid(gridindex));
	[mm,i]=size(posdata(dataindex));
	[Cdd] = s*covarxy(posdata(dataindex,:),posdata(dataindex,:),gs,ts,q);
	Cdd(1:mm+1:mm^2+mm)=diag(Cdd)+e*ones(mm,1);    % data-data cov. matrix
	Cdd=inv(Cdd);
%
% calculate the objectively mapped fields on the data and grid fields.
% note the mean field is removed to ensure that estimate is unbiased
%
	for i=1:rank
		meanv=meanstd2(v(i,dataindex));
		wght=Cdd*(v(i,dataindex)-meanv*ones(1,length(dataindex)))';
%		disp(['Mapping onto the data grid'])
		
		for j=1:mm,
			[Cmd] = s*covarxy(posdata(dataindex(j),:),posdata(dataindex,:),gs,ts,q);
			[vdata(dataindex(j),i)] = Cmd*wght+ meanv;
			[vdataerror(dataindex(j),i)]=sqrt(s-Cmd*Cdd*Cmd');
		end %for
%		disp(['Mapping onto the model grid'])
		for j=1:nn,
			[Cmd] = s*covarxy(posgrid(gridindex(j),:),posdata(dataindex,:),gs,ts,q);
			[vgrid(gridindex(j),i)] = Cmd*wght+ meanv;
			[vgriderror(gridindex(j),i)]=sqrt(s-Cmd*Cdd*Cmd');
		end %for
%		disp(['finished mapontodata at this rank' num2str(i)])
	end %for
	regiontime=toc-regiontime;
end %for 
totaltime=toc;
return

