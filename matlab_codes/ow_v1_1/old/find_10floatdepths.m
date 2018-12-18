
function [index, tlevel] = find_10floatdepths( SAL, PTMP, PRES, la_ptmp, use_theta_gt, use_theta_lt, use_pres_gt, use_pres_lt )

% Chooses 10 depth levels from the float series for use in the linear fit.
% In the following order:-
%
% min S variance on theta levels = 2
% min PTMP variance on P levels = 4
% min SAL variance on P levels = 4
%
% This routine relies on the S, T, P matrices to line up along a uniform depth axis.
% For Apex floats that don't report measurements on fixed depth surfaces, assume the
% measurements are reported on fixed nominal depths, i.e. ignore small differences
% between fixed nominal depths and actual measured depths.
%
% These levels are distinct (ie. they don't repeat each other). So sometimes
% there may only be 8 levels.
%
% A.Wong, 4 June 2008.


% initialize variables ---

[m,n]=size(PRES);
index=NaN.*ones(10,n);
tlevel=NaN.*ones(2,1);


% levels with percentage of good profiles less than this number will not be used ---

cutoff=0.5; % this percentage can be changed


% exclude mixed layer that has not been mapped ---

jj=find(isnan(la_ptmp)==1);
PRES(jj)=NaN;
SAL(jj)=NaN;
PTMP(jj)=NaN;


% use only manually specified THETA & PRES range ---

if(use_theta_lt~=99999&use_theta_gt==99999)
  jj=find(PTMP>use_theta_lt);
  PRES(jj)=NaN;
  SAL(jj)=NaN;
  PTMP(jj)=NaN;
end

if(use_theta_gt~=99999&use_theta_lt==99999)
  jj=find(PTMP<use_theta_gt);
  PRES(jj)=NaN;
  SAL(jj)=NaN;
  PTMP(jj)=NaN;
end

if(use_theta_gt~=99999&use_theta_lt~=99999)
  if(use_theta_gt>use_theta_lt)
    jj=find(PTMP<use_theta_gt&PTMP>use_theta_lt);
  else
    jj=find(PTMP<use_theta_gt|PTMP>use_theta_lt);
  end
  PRES(jj)=NaN;
  SAL(jj)=NaN;
  PTMP(jj)=NaN;
end

if(use_pres_lt~=99999&use_pres_gt==99999)
  jj=find(PRES>use_pres_lt);
  PRES(jj)=NaN;
  SAL(jj)=NaN;
  PTMP(jj)=NaN;
end

if(use_pres_gt~=99999&use_pres_lt==99999)
  jj=find(PRES<use_pres_gt);
  PRES(jj)=NaN;
  SAL(jj)=NaN;
  PTMP(jj)=NaN;
end

if(use_pres_gt~=99999&use_pres_lt~=99999)
  if(use_pres_gt>use_pres_lt)
    jj=find(PRES<use_pres_gt&PRES>use_pres_lt);
  else
    jj=find(PRES<use_pres_gt|PRES>use_pres_lt);
  end
  PRES(jj)=NaN;
  SAL(jj)=NaN;
  PTMP(jj)=NaN;
end


% Define theta levels about 50 dbar apart ---
% This theta level subdivision is based on equally dividing PRES into 50 dbar bins.
% Because temp gradient varies with depth, the theta levels are not going to be
% exactly 50 dbar apart. But this is better than specifying a fixed theta increment
% for all profiles.

minTheta = ceil(min(min(PTMP))*10)/10;
maxTheta = floor(max(max(PTMP))*10)/10;

if(minTheta<maxTheta) % no levels 1-2 when no valid theta range --

maxpres=max(max(PRES));
minpres=min(min(PRES));
howmanylevels=length(minpres:50:maxpres); % 50 dbar increment
if( (maxTheta-minTheta)/howmanylevels<0.1 )
  Thetainc = round( (maxTheta-minTheta)*100/howmanylevels )/100; % 2 decimal points
else
  Thetainc = round( (maxTheta-minTheta)*10/howmanylevels )/10; % 1 decimal point
end
Thetalevels = [minTheta:Thetainc:maxTheta];
Thetalevel_indexes = NaN*ones(length(Thetalevels),n);


% find profile levels closest to theta levels ---
% At areas with temp inversions (e.g. Gulf of Alaska, Southern Ocean),
% PTMP is not unique, so this will pick out indexes from different depths for the same T,
% thus giving artificially high S var on T. This is ok since areas with
% temp inversions are also areas with naturally high S var on T, and therefore
% will not be selected as a min S var on T level anyway.

for i=1:n
  for j=1:length(Thetalevels)
   if(Thetalevels(j)<max(PTMP(:,i))&Thetalevels(j)>min(PTMP(:,i)))
     diffTheta = abs(PTMP(:,i)-Thetalevels(j));
     if isempty(find(~isnan(diffTheta)))
       Thetalevel_indexes(j,i) = NaN;
     else
       Thetalevel_indexes(j,i) = min(find(diffTheta==min(diffTheta)));
     end
   end
  end
end


% find min variance of S on theta levels (= 2), these indexes will differ between profiles ---

S_temp=NaN.*ones(length(Thetalevels),n);

for i=1:length(Thetalevels) % build the S matrix to find var & the max number of good profiles
  for j=1:n
   ti=Thetalevel_indexes(i,j);
   if ~isnan(ti)
     if(PTMP(ti,j)>Thetalevels(i))ki=ti+1;end
     if(PTMP(ti,j)<Thetalevels(i))ki=ti-1;end
     if( ~isnan(SAL(ti,j))&~isnan(SAL(ki,j))&~isnan(PTMP(ti,j))&~isnan(PTMP(ki,j)) )
       S_temp(i,j) = interp1( [PTMP(ti,j), PTMP(ki,j)], [SAL(ti,j), SAL(ki,j)], Thetalevels(i) );
     else
       S_temp(i,j)=SAL(ti,j); % interpolate if possible because that is more accurate than using closest points
     end
   end
  end
end


numgood=NaN.*ones(length(Thetalevels),1);
percentSprofs=NaN.*ones(length(Thetalevels),1);
var_s_Thetalvls=NaN.*ones(length(Thetalevels),1);

for i=1:length(Thetalevels)
  good=find(isnan(S_temp(i,:))==0);
  numgood(i)=length(good);
  var_s_Thetalvls(i) =  var(S_temp(i,good)); % only use S on theta level that has valid values
end

for j=1:length(Thetalevels)
  percentSprofs(j) = numgood(j)/max(numgood); % maximum number of good data points on a theta level
end
bad = find(percentSprofs<cutoff);
var_s_Thetalvls(bad)=NaN;

if(isempty(find(isnan(var_s_Thetalvls)==0))==0)
  kk=min(find(var_s_Thetalvls==min(var_s_Thetalvls(find(isnan(var_s_Thetalvls)==0)) )));
  index(1,:) = Thetalevel_indexes(kk,:);
  tlevel(1) = Thetalevels(kk); %theta that has min S variance
end

var_s_Thetalvls(kk)=NaN; % block out this level --
if(isempty(find(isnan(var_s_Thetalvls)==0))==0)
  ll=min(find(var_s_Thetalvls==min(var_s_Thetalvls(find(isnan(var_s_Thetalvls)==0)) ))); % find from remaining levels --
  index(2,:) = Thetalevel_indexes(ll,:);
  tlevel(2) = Thetalevels(ll); %theta that has min S variance
end


end % no levels 1-2 when no valid theta range --


% find SAL var and PTMP var on P levels, this assumes the S, T, P matrices line up along a uniform depth axis ---

numgoodPTMP=NaN.*ones(m,1);
numgoodSAL=NaN.*ones(m,1);
percentPTMP=NaN.*ones(m,1);
percentSAL=NaN.*ones(m,1);
var_t=NaN.*ones(m,1);
var_s=NaN.*ones(m,1);

for i=1:m
  good=find( isnan(PTMP(i,:))==0 );
  numgoodPTMP(i)=length(good);
  if( length(good)>1 )
    var_t(i)=var(PTMP(i,good));
  end
  good=find( isnan(SAL(i,:))==0 );
  numgoodSAL(i)=length(good);
  if( length(good)>1 )
    var_s(i)=var(SAL(i,good));
  end
end

for j=1:m
  percentPTMP(j) = numgoodPTMP(j)/max(numgoodPTMP);  %Percent of PTMP that has valid values
  percentSAL(j) = numgoodSAL(j)/max(numgoodSAL);  %Percent of SAL that has valid values
end
bad = find(percentPTMP<cutoff);
var_t(bad)=NaN;
bad = find(percentSAL<cutoff);
var_s(bad)=NaN;


% find min variance PTMP on P (= 4), min variance SAL on P (= 4), these indexes are common between all profiles ---

jj=find( isnan(var_t)==0 ); % remaining level find min var T
if( isempty(jj)==0 )
  min_var_t=min(var_t(jj));
  k_min=find( var_t==min_var_t );
  index(3,:)=k_min(1).*ones(1,n);
  var_s(k_min(1))=NaN; % block out this level
  var_t(k_min(1))=NaN; % block out this level
end
jj=find( isnan(var_t)==0 ); % remaining level find min var T
if( isempty(jj)==0 )
  min_var_t=min(var_t(jj));
  k_min=find( var_t==min_var_t );
  index(4,:)=k_min(1).*ones(1,n);
  var_s(k_min(1))=NaN; % block out this level
  var_t(k_min(1))=NaN; % block out this level
end
jj=find( isnan(var_t)==0 ); % remaining level find min var T
if( isempty(jj)==0 )
  min_var_t=min(var_t(jj));
  k_min=find( var_t==min_var_t );
  index(5,:)=k_min(1).*ones(1,n);
  var_s(k_min(1))=NaN; % block out this level
  var_t(k_min(1))=NaN; % block out this level
end
jj=find( isnan(var_t)==0 ); % remaining level find min var T
if( isempty(jj)==0 )
  min_var_t=min(var_t(jj));
  k_min=find( var_t==min_var_t );
  index(6,:)=k_min(1).*ones(1,n);
  var_s(k_min(1))=NaN; % block out this level
  var_t(k_min(1))=NaN; % block out this level
end


jj=find( isnan(var_s)==0 );
if( isempty(jj)==0 )
  min_var_s=min(var_s(jj));
  k_min=find( var_s==min_var_s );
  index(7,:)=k_min(1).*ones(1,n);
  var_s(k_min(1))=NaN; % block out this level
end
jj=find( isnan(var_s)==0 );
if( isempty(jj)==0 )
  min_var_s=min(var_s(jj));
  k_min=find( var_s==min_var_s );
  index(8,:)=k_min(1).*ones(1,n);
  var_s(k_min(1))=NaN; % block out this level
end
jj=find( isnan(var_s)==0 );
if( isempty(jj)==0 )
  min_var_s=min(var_s(jj));
  k_min=find( var_s==min_var_s );
  index(9,:)=k_min(1).*ones(1,n);
  var_s(k_min(1))=NaN; % block out this level
end
jj=find( isnan(var_s)==0 );
if( isempty(jj)==0 )
  min_var_s=min(var_s(jj));
  k_min=find( var_s==min_var_s );
  index(10,:)=k_min(1).*ones(1,n);
  var_s(k_min(1))=NaN; % block out this level
end


% make sure levels 1-2 don't repeat each other and don't repeat levels 3-10 ---

for i=1:n
     match=find( index(1,i)==index(2:10,i) );
     if( isempty(match)==0 )index(1,i)=NaN;end
     match=find( index(2,i)==index([1,3:10],i) );
     if( isempty(match)==0 )index(2,i)=NaN;end
end


% make sure levels 3-10 are within the manually specified THETA range ---

for i=1:n
  jj=find( isnan(index(:,i))==0 );
  a=index(jj,i);
  kk=find( isnan(PTMP(a,i))==1 );
  b=a(kk);

  for j=1:10
    match=find(index(j,i)==b);
    if(isempty(match)==0)index(j,i)=NaN;end
  end
end


