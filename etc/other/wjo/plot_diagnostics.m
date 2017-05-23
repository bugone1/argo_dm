%---------------------------------------------------------------------------------
% function plot_diagnostics( pn_float_dir, pn_float_name, po_system_configuration )
%
% Annie Wong, 30 June 2005
%---------------------------------------------------------------------------------


function plot_diagnostics( pn_float_dir, pn_float_name, po_system_configuration )

close all

% modify pn_float_name for title if the name contains '_' ------------

ii=find(pn_float_name=='_');
if(isempty(ii)==0)
     title_floatname = strcat( pn_float_name(1:ii-1), '\_', pn_float_name(ii+1:length(pn_float_name)));
else
     title_floatname = pn_float_name;
end


% load data from /float_source, /float_mapped, /float_calib, and others --------------

lo_float_source_data = load(strcat(po_system_configuration.FLOAT_SOURCE_DIRECTORY, pn_float_dir, pn_float_name, po_system_configuration.FLOAT_SOURCE_POSTFIX));

PROFILE_NO = lo_float_source_data.PROFILE_NO;
ii=find(PROFILE_NO~=0); % do not plot profile number 0
PROFILE_NO=PROFILE_NO(ii);

LAT  = lo_float_source_data.LAT(ii) ;
LONG = lo_float_source_data.LONG(ii);
PRES = lo_float_source_data.PRES(:,ii);
PTMP = lo_float_source_data.PTMP(:,ii);
SAL  = lo_float_source_data.SAL(:,ii) ;

if(isempty(find(isnan(PRES)==0))==0) % if no data exists, terminate here, no plots will be produced

lo_float_mapped_data = load( strcat( po_system_configuration.FLOAT_MAPPED_DIRECTORY, pn_float_dir, po_system_configuration.FLOAT_MAPPED_PREFIX, pn_float_name, po_system_configuration.FLOAT_MAPPED_POSTFIX ) ) ;

INTERP_PRES = lo_float_mapped_data.la_INTERP_PRES(:,ii) ;
INTERP_SAL  = lo_float_mapped_data.la_INTERP_SAL(:,ii)  ;
mapped_sal  = lo_float_mapped_data.la_mapped_sal(:,ii)  ;
mapsalerrors= lo_float_mapped_data.la_mapsalerrors(:,ii);
selected_hist=lo_float_mapped_data.selected_hist;

if(isempty(find(isnan(INTERP_PRES)==0))==0) % if no data exists, terminate here, no plots will be produced

lo_float_calib_data = load( strcat( po_system_configuration.FLOAT_CALIB_DIRECTORY, pn_float_dir, po_system_configuration.FLOAT_CALIB_PREFIX, pn_float_name, po_system_configuration.FLOAT_CALIB_POSTFIX ) ) ;

cal_SAL = lo_float_calib_data.cal_SAL(:,ii) ;
cal_SAL_err = lo_float_calib_data.cal_SAL_err(:,ii) ;
condslope = lo_float_calib_data.condslope(ii) ;
condslope_err = lo_float_calib_data.condslope_err(ii) ;

if(isempty(find(isnan(cal_SAL)==0))==0) % if no data exists, terminate here, no plots will be produced

[m,n] = size(mapped_sal) ;
number_of_levels = str2double(po_system_configuration.NO_USED_STANDARD_LEVELS) ;
ptlevels = lo_float_mapped_data.la_standard_levels(1:number_of_levels) ;


% plot the float locations (figure 1) -----------------------

load( strcat( po_system_configuration.CONFIG_DIRECTORY, po_system_configuration.CONFIG_COASTLINES ), 'coastdata_x', 'coastdata_y' ) ;

figure
colormap(jet(n));
c=colormap;

if(isempty(selected_hist)==0)
  x=selected_hist(:,1);
  ii=find(x>360);
  jj=find(LONG>300);
  kk=find(LONG<50);
  if(isempty(ii)==0&isempty(jj)==1) % if all float points are east of 0
    x=x-360;
  end
  if(isempty(ii)==0&isempty(jj)==0&isempty(kk)==0) % if some float points are east of 0, and some are west of 0
    LONG(kk)=LONG(kk)+360;
    if(min(LONG)>350) % if majority of float points are east of 0
      x=x-360;
      LONG(kk)=LONG(kk)-360;
      LONG(jj)=LONG(jj)-360;
    end
  end
  plot(coastdata_x,coastdata_y,'k-');
  hold on
  plot(x,selected_hist(:,2),'b.')
  legend('float','historical points',0)
end

for i=1:n
  h=plot(LONG(i),LAT(i),'+');
  set(h,'color',c(i,:));
  j=text(LONG(i),LAT(i),int2str(PROFILE_NO(i)));
  set(j,'color',c(i,:),'fontsize',12,'hor','cen');
end
plot(LONG,LAT,'r-');
axis([min(LONG)-30,max(LONG)+30,min(LAT)-20,max(LAT)+20])
set(gca,'FontSize',12)
xlabel('Longitude');
ylabel('Latitude');
title( strcat(title_floatname, ' profile locations with historical data' ) );

drawnow
set(gcf,'papertype','usletter','paperunits','inches','paperorientation','landscape','paperposition',[.75,.75,9.5,7]);
print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_1.ps'));


% plot the uncalibrated theta-S curves from the float (figure 2) --------

figure;
colormap(jet( length([1:ceil(n/30):n]) )); % the legend can only fit 30 profiles
c=colormap;
qq=plot(PTMP(:,1:ceil(n/30):n),SAL(:,1:ceil(n/30):n));
for i=1:length([1:ceil(n/30):n])
 set(qq(i),'color',c(i,:)) ;
end
hold on
legend(int2str([PROFILE_NO(1:ceil(n/30):n)]'),-1)
q=errorbar(ptlevels*ones(1,length( [1:ceil(n/30):n] )),mapped_sal(:,1:ceil(n/30):n),mapsalerrors(:,1:ceil(n/30):n),'o');
for i=1:length([1:ceil(n/30):n])
 set(q(i),'color',c(i,:));
% set(q(i+length([1:ceil(n/30):n])),'color',c(i,:));
end
view([90 -90]);
set(gca,'FontSize',12)
ylabel('Salinity (PSS-78)');
xlabel('\theta ^{\circ} C');

max_s=max([max(SAL),max(mapped_sal)])+.1;
min_s=min([min(SAL),min(mapped_sal)])-.1;
max_t=max(max(PTMP))+1;
min_t=min(min(PTMP))-1;
axis([min_t,max_t,min_s,max_s]);

drawnow
title( strcat( title_floatname, ' uncalibrated float data (-) and mapped salinity (o) with objective errors' ) );
set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_2.ps'));


% time-varying series (figure 3) --------------------------

Soffset=cal_SAL-SAL;
avg_Soffset=NaN.*ones(1,n);
avg_Soffset_err=NaN.*ones(1,n);

for i=1:n
   ii=[];
   ii=find(isnan(Soffset(:,i))==0);
   avg_Soffset(i)=mean(Soffset(ii,i));
   avg_Soffset_err(i)=mean(cal_SAL_err(ii,i));
end

figure
subplot(2,1,1)
plot(PROFILE_NO(1:n),condslope, 'g-');
hold on
plot(PROFILE_NO(1:n),condslope, 'b-');
legend('2 x error','1 x error',0);
errorbar(PROFILE_NO(1:n),condslope,2*condslope_err,'g')
errorbar(PROFILE_NO(1:n),condslope,condslope_err,'b*-')
plot( [0, max(PROFILE_NO)+1], [1,1], 'k-')
axis([ 0, max(PROFILE_NO)+1, min(condslope-condslope_err)-.0004, max(condslope+condslope_err)+.0004 ])
set(gca,'FontSize',12)
xlabel('float profile number');
ylabel('r') % multiplicative term has no units
title( strcat(title_floatname, ' potential conductivity (mmho/cm) multiplicative correction r with errors') );

subplot(2,1,2)
plot(PROFILE_NO(1:n), avg_Soffset, 'g-');
hold on
plot(PROFILE_NO(1:n), avg_Soffset, 'b-');
legend('2 x error','1 x error',0);
errorbar(PROFILE_NO(1:n), avg_Soffset, 2*avg_Soffset_err,'g')
errorbar(PROFILE_NO(1:n), avg_Soffset, avg_Soffset_err,'bo-')
axis([ 0, max(PROFILE_NO)+1, min(avg_Soffset-avg_Soffset_err)-.02, max(avg_Soffset+avg_Soffset_err)+.02 ])
plot( [0, max(PROFILE_NO)+1], [0,0], 'k-')
set(gca,'FontSize',12)
xlabel('float profile number');
ylabel('\Delta S')
title( strcat(title_floatname, ' vertically-averaged salinity (PSS-78) additive correction \Delta S with errors') );

drawnow
set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_3.ps'));


% plot the calibrated theta-S curves from the float (figure 4) --------------------------

figure;
colormap(jet( length([1:ceil(n/30):n]))); % the legend can only fit 30 profiles
c=colormap;

qq=plot( PTMP(:, 1:ceil(n/30):n), cal_SAL(:, 1:ceil(n/30):n) );
for i=1:length([1:ceil(n/30):n])
 set(qq(i),'color',c(i,:)) ;
end
hold on;
legend(int2str([PROFILE_NO(1:ceil(n/30):n)]'),-1)
q=errorbar(ptlevels*ones(1,length( [1:ceil(n/30):n] ) ),mapped_sal(:,1:ceil(n/30):n), mapsalerrors(:,1:ceil(n/30):n),'o');
for i=1: length([1:ceil(n/30):n])
 set(q(i),'color',c(i,:));
% set(q(i+length([1:ceil(n/30):n])),'color',c(i,:));
end
view([90 -90]);
set(gca,'FontSize',12)
xlabel('\theta ^{\circ} C')
ylabel('Salinity (PSS-78)')

max_s=max([max(max(cal_SAL)),max(max(mapped_sal))])+.1;
min_s=min([min(min(cal_SAL)),min(min(mapped_sal))])-.1;
max_t=max(max(PTMP))+1;
min_t=min(min(PTMP))-1;
if(isnan(min_s)==0)
  axis([min_t,max_t,min_s,max_s]);
end

drawnow
title( strcat(title_floatname, ' calibrated float data (-) and mapped salinity (o) with objective errors' ) );
set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_4.ps'));


% plot salinity anomaly time series on theta levels (figure 5) ------

Smedian=NaN.*ones( length(ptlevels), 1);

for j=1:length(ptlevels)
     jj = find( isnan( INTERP_SAL(j,:) )==0 );
   if(isempty(jj)==0)
      Smedian(j)= median( INTERP_SAL(j,jj) );
   end
end

Sanomaly = INTERP_SAL-Smedian*ones(1,n);
a=max(max(Sanomaly));
b=min(min(Sanomaly));
top=max(max(PTMP));
bottom=min(min(PTMP));
if(top>10)
  cut=max(bottom,10);
elseif(top>5)
  cut=5;
else
  cut=round((top+bottom)/2);
end


figure
if(length(PROFILE_NO)>1)
  subplot('position',[.13 .72 .78 .2])
  set(gca,'FontSize',12)
  [c,h]=contourf(PROFILE_NO, ptlevels, Sanomaly, 'k-');
  colormap(jet)
  if(a>b)caxis([b a]);end
  axis([0 max(PROFILE_NO)+1 cut top]);
  set(gca,'XTick',[]);
  set(gca,'XTickLabel',[]);
  title( strcat( title_floatname, ' salinity anomaly on potential temperature levels') );

  subplot('position',[.13 .11 .78 .61])
  set(gca,'FontSize',12)
  if(bottom<cut)
    [c,h]=contourf(PROFILE_NO, ptlevels, Sanomaly, 'k-');
    axis([0 max(PROFILE_NO)+1 bottom cut]);
  end
  colormap(jet)
  if(a>b)caxis([b a]);end
  xlabel('float profile number')
  ylabel('\theta ^{\circ} C')
  h2=colorbar('horiz');
  set(h2,'FontSize',12)
end

drawnow
set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_5.ps'));


% plot salinity time series on level with the smallest S variance and smallest mean mapping error (figure 6) ------------

ICOND=sw_c3515*sw_cndr(INTERP_SAL,ptlevels*ones(1,n),0);
cal_ICOND=(ones(m,1)*condslope).*ICOND;
cal_ICOND1=ICOND.*(ones(m,1)*(condslope-condslope_err));
cal_INTERP_SAL=sw_salt(cal_ICOND/sw_c3515,ptlevels*ones(1,n),0);
cal_INTERP_SAL_err=abs(cal_INTERP_SAL-sw_salt(cal_ICOND1/sw_c3515,ptlevels*ones(1,n),0));

majority=[];
mstd=NaN*ones(m,1);
for i=1:m
   mm=find( isnan(INTERP_SAL(i,:))==0 );
   if(length(mm)>1)mstd(i)=std(INTERP_SAL(i,mm));end
   if(length(mm)>.7*n)majority=[majority,i];end %these are the levels with at least 70% data
end
kk=find( isnan(mstd)==0 );
if(isempty(kk)==0)
  if(isempty(majority)==0)
     jj=find(mstd==min(mstd(majority))); %smallest S variance
  else
     jj=find(mstd==min(mstd(kk)));
  end
else
  jj=[];
end

majority=[];
merr=NaN*ones(m,1);
for i=1:m
   mm=find( isnan(mapsalerrors(i,:))==0 );
   if(isempty(mm)==0)merr(i)=mean(mapsalerrors(i,mm));end
   if(length(mm)>.7*n)majority=[majority,i];end %these are the levels with at least 70% data
end
kk=find( isnan(merr)==0 );
if(isempty(kk)==0)
  if(isempty(majority)==0)
    ii=find(merr==min(merr(majority))); %smallest mean mapping error
  else
    ii=find(merr==min(merr(kk)));
  end
else
  ii=[];
end

figure
if(isempty(ii)==0&isempty(jj)==0)

  subplot(2,1,1)
  plot(PROFILE_NO(1:n),INTERP_SAL(jj,:),'b*-');
  hold on
  plot(PROFILE_NO(1:n),mapped_sal(jj,:),'r');
  plot(PROFILE_NO(1:n),cal_INTERP_SAL(jj,:),'g');
  legend('uncal float','mapped salinity','cal float w/err.',0);
  mm=find(finite(cal_INTERP_SAL(jj,:))==1); ll=PROFILE_NO(1:n); ll=ll(mm); kk=cal_INTERP_SAL(jj,mm); nn=cal_INTERP_SAL_err(jj,mm);
  h=fill([ll,fliplr(ll)],[kk+nn,fliplr([kk-nn])],'g');
  set(h,'EdgeColor','g');
  errorbar(PROFILE_NO(1:n),mapped_sal(jj,:),mapsalerrors(jj,:),'r-')
  plot(PROFILE_NO(1:n),INTERP_SAL(jj,:),'b*-');
  axis([0, max(PROFILE_NO)+1, min([INTERP_SAL(jj,:),cal_INTERP_SAL(jj,:),mapped_sal(jj,:)])-.05, max([INTERP_SAL(jj,:),cal_INTERP_SAL(jj,:),mapped_sal(jj,:)])+.05 ])
  set(gca,'FontSize',12)
  xlabel('float profile number');
  ylabel('salinity (PSS-78)')
  title( strcat(title_floatname, ' salinities with error on \theta= ', num2str(ptlevels(jj)), '^{\circ}C (smallest S variance)' ) );

  subplot(2,1,2)
  plot(PROFILE_NO(1:n),INTERP_SAL(ii,:),'b*-');
  hold on
  plot(PROFILE_NO(1:n),mapped_sal(ii,:),'r');
  plot(PROFILE_NO(1:n),cal_INTERP_SAL(ii,:),'g');
  legend('uncal float','mapped salinity','cal float w/err.',0);
  mm=find(finite(cal_INTERP_SAL(ii,:))==1); ll=PROFILE_NO(1:n); ll=ll(mm); kk=cal_INTERP_SAL(ii,mm); nn=cal_INTERP_SAL_err(ii,mm);
  h=fill([ll,fliplr(ll)],[kk+nn,fliplr([kk-nn])],'g');
  set(h,'EdgeColor','g');
  errorbar(PROFILE_NO(1:n),mapped_sal(ii,:),mapsalerrors(ii,:),'r-')
  plot(PROFILE_NO(1:n),INTERP_SAL(ii,:),'b*-');
  axis([0, max(PROFILE_NO)+1, min([INTERP_SAL(ii,:),cal_INTERP_SAL(ii,:),mapped_sal(ii,:)])-.05, max([INTERP_SAL(ii,:),cal_INTERP_SAL(ii,:),mapped_sal(ii,:)])+.05 ])
  set(gca,'FontSize',12)
  xlabel('float profile number');
  ylabel('salinity (PSS-78)')
  title( strcat(title_floatname, ' salinities with error on \theta= ', num2str(ptlevels(ii)), '^{\circ}C (smallest mapping error)' ) );

end

drawnow
set(gcf,'papertype','usletter','paperunits','inches','paperorientation','portrait','paperposition',[.25,.75,8,9.5]);
print('-dpsc ', strcat(po_system_configuration.FLOAT_PLOTS_DIRECTORY, pn_float_dir, pn_float_name, '_6.ps'));


end %if(isempty(find(isnan(cal_SAL)==0))==0) ---------------
end %if(isempty(find(isnan(INTERP_PRES)==0))==0) -----------
end %if(isempty(find(isnan(PRES)==0))==0) ------------------


