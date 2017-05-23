
% adapted from Paul Robbins script ---
% A Wong, 21 April, 2008 ---


cutoff=0.5; % this percentage can be changed

pres=PRES;
sal=SAL;
ptmp=PTMP;

% exclude data not used ---

jj=find(isnan(la_ptmp)==1);
pres(jj)=NaN;
sal(jj)=NaN;
ptmp(jj)=NaN;

if(use_theta_lt~=99999&use_theta_gt==99999)
  jj=find(PTMP>use_theta_lt);
  pres(jj)=NaN;
  sal(jj)=NaN;
  ptmp(jj)=NaN;
end

if(use_theta_gt~=99999&use_theta_lt==99999)
  jj=find(PTMP<use_theta_gt);
  pres(jj)=NaN;
  sal(jj)=NaN;
  ptmp(jj)=NaN;
end

if(use_theta_gt~=99999&use_theta_lt~=99999)
  if(use_theta_gt>use_theta_lt)
    jj=find(PTMP<use_theta_gt&PTMP>use_theta_lt);
  else
    jj=find(PTMP<use_theta_gt|PTMP>use_theta_lt);
  end
  pres(jj)=NaN;
  sal(jj)=NaN;
  ptmp(jj)=NaN;
end

if(use_pres_lt~=99999&use_pres_gt==99999)
  jj=find(PRES>use_pres_lt);
  pres(jj)=NaN;
  sal(jj)=NaN;
  ptmp(jj)=NaN;
end

if(use_pres_gt~=99999&use_pres_lt==99999)
  jj=find(PRES<use_pres_gt);
  pres(jj)=NaN;
  sal(jj)=NaN;
  ptmp(jj)=NaN;
end

if(use_pres_gt~=99999&use_pres_lt~=99999)
  if(use_pres_gt>use_pres_lt)
    jj=find(PRES<use_pres_gt&PRES>use_pres_lt);
  else
    jj=find(PRES<use_pres_gt|PRES>use_pres_lt);
  end
  pres(jj)=NaN;
  sal(jj)=NaN;
  ptmp(jj)=NaN;
end


% find S var on theta levels ---
% use sal, ptmp, pres with unwanted data excluded ---

minTheta = ceil(min(min(ptmp))*10)/10;
maxTheta = floor(max(max(ptmp))*10)/10;

if(minTheta<maxTheta) % no levels 1-2 when no valid theta range --

maxpres=max(max(pres));
minpres=min(min(pres));

howmanylevels=length(minpres:50:maxpres); % 50 dbar increment
if( (maxTheta-minTheta)/howmanylevels<0.1 )
  Thetainc = round( (maxTheta-minTheta)*100/howmanylevels )/100; % 2 decimal points
else
  Thetainc = round( (maxTheta-minTheta)*10/howmanylevels )/10; % 1 decimal point
end

Thetalevels = [minTheta:Thetainc:maxTheta]; % Thetalevels about 50 dbar apart
Thetalevel_indexes = NaN*ones(length(Thetalevels),n);

for i=1:n
  for j=1:length(Thetalevels)
    if(Thetalevels(j)<max(ptmp(:,i))&Thetalevels(j)>min(ptmp(:,i)))
      diffTheta = abs(PTMP(:,i)-Thetalevels(j));
      if isempty(find(~isnan(diffTheta)))
        Thetalevel_indexes(j,i) = NaN;
      else
        Thetalevel_indexes(j,i) = min(find(diffTheta==min(diffTheta)));
      end
    end
  end
end

S_temp=NaN.*ones(length(Thetalevels),n);

for i=1:length(Thetalevels) % build the S matrix to find var & the max number of good profiles
  for j=1:n
   ti=Thetalevel_indexes(i,j);
   if ~isnan(ti)
     if(ptmp(ti,j)>Thetalevels(i))ki=ti+1;end
     if(ptmp(ti,j)<Thetalevels(i))ki=ti-1;end
     if(~isnan(sal(ti,j))&~isnan(sal(ki,j))&~isnan(sal(ti,j))&~isnan(sal(ki,j)) )
       S_temp(i,j) = interp1( [ptmp(ti,j), ptmp(ki,j)], [sal(ti,j), sal(ki,j)], Thetalevels(i) );
     else
       S_temp(i,j)=sal(ti,j);
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

end


% find SAL var and PTMP var on P levels, this assumes the S, T, P matrices line up along a uniform depth axis ---
% use original SAL, PTMP, PRES ---

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


% find mean pres ---

avg_pres=NaN.*ones(1,m);
for i=1:m
    jj=find(isnan(PRES(i,:))==0);
    avg_pres(i)=mean(PRES(i,jj));
end


% plot ---

subplot(321)
plot(var_t,-avg_pres,'b-')
% plot chosen levels
xl = get(gca,'xlim');
for k = 3:6
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'r-'); hold off
end
%set(gca,'ydir','rev','ylim',[nanmin(pres) nanmax(pres)])
title('Temperature Variance on Pressure')
ylabel('Pressure (dbar)')
xlabel('^{\circ}C')


subplot(322)
plot(var_s,-avg_pres,'b-')
% plot chosen levels
xl = get(gca,'xlim');
for k = 7:10
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'m-'); hold off
end
%set(gca,'ydir','rev','ylim',[nanmin(pres) nanmax(pres)])
title('Salinity Variance on Pressure')
xlabel('PSS-78')


subplot(323)
plot(var_s_Thetalvls,Thetalevels,'b-')
xl = get(gca,'xlim');
hold on; plot(xl,[tlevel(1) tlevel(1)] ,'g-');
hold on; plot(xl,[tlevel(2) tlevel(2)] ,'g-'); hold off
title('Salinity Variance on Theta')
ylabel('Potential temp (^{\circ}C)')
xlabel('PSS-78')

% plot t-s profile
subplot(324)
plot(SAL,PTMP,'b-');
xl = get(gca,'xlim');
y1 = get(gca,'ylim');
xlabel('PSS-78')

for k = 3:6
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PTMP(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=mean(th(ii));
  hold on; plot(xl,[a a],'r-'); hold off
end

for k = 7:10
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PTMP(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=mean(th(ii));
  hold on; plot(xl,[a a],'m-'); hold off
end

for k = 1
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PTMP(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=mean(th(ii));
  hold on; plot(xl,[a a],'g-'); hold off
end

for k = 2
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PTMP(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=mean(th(ii));
  hold on; plot(xl,[a a],'g-'); hold off
end
%set(gca,'ydir','rev','ylim',[nanmin(pres) nanmax(pres)])
title(strcat('OW chosen levels - ', pn_float_name));

subplot(323)
set(gca,'ylim',y1);


% plot p-s profile
subplot(325)
plot(SAL,-PRES,'b-');
xl = get(gca,'xlim');
xlabel('PSS-78')
ylabel('Pressure (dbar)')

for k = 1
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'g-'); hold off
end

for k = 2
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'g-'); hold off
end

for k = 3:6
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'r-'); hold off
end

for k = 7:10
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'m-'); hold off
end
%set(gca,'ydir','rev','ylim',[nanmin(pres) nanmax(pres)])
title(strcat('OW chosen levels - ', pn_float_name));


% plot p-t profile
subplot(326)
plot(PTMP,-PRES,'b-');
xl = get(gca,'xlim');
xlabel('^{\circ}C')

for k = 1
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'g-'); hold off
end

for k = 2
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'g-'); hold off
end

for k = 3:6
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'r-'); hold off
end

for k = 7:10
  th=[];
  jj=find(isnan(index(k,:))==0);
  for i=1:length(jj)
    th(i)=PRES(index(k,jj(i)),jj(i));
  end
  ii=find(isnan(th)==0);
  a=-mean(th(ii));
  hold on; plot(xl,[a a],'m-'); hold off
end
%set(gca,'ydir','rev','ylim',[nanmin(pres) nanmax(pres)])
title(strcat('OW chosen levels - ', pn_float_name));

