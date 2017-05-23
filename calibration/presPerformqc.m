%callled by presMain.m
%remove >1000 spikes and replace them with mean
%(1). Subtract 5-dbar from the values in PRES_SurfaceOffsetTruncatedPlus5dbar _dBAR.
pres1=(pres-offset)/scalefactor; %hpa to kpa

%ok=abs(pres1)>=1000;
%moy=mean(pres1(~ok));
%pres1(ok)=moy;

%(2). Despike the SP time series to 1-dbar.
%This is most effectively done by first removing the more conspicuous
%spikes that are bigger than 4.9-dbar (as in the real-time procedure)
pres2=presDespikargo(pres1,4.9,1000);

%then the more subtle spikes that are between 1- to 5-dbar by comparing the
%SP values with those derived from a 5-point (50 days) median filter.
n=5;fpres=filter(ones(n,1),n,pres2);
ano=presDespikargo(pres2-fpres,1,1000);
pres3=fpres+ano; %fpres+pres2-fpres

% a(1)=plot(sdn-sdn(1),pres1,'.r');
% a(2)=plot(sdn-sdn(1),pres3,'bo')
% legend(a,'Surface pressure in tech file, raw','Despiked and filtered');
% xlabel('Time (days)');
% ylabel('Pressure (dbar)');
% pause
% print('-dpng',[lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep 'pres_' floatname '.png']);
% 
% close all
