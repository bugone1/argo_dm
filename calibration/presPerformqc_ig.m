function pres3=presPerformqc(pres,offset,scalefactor,apex)
% PRESPERFORMQC Perform pressure QC
%   DESCRIPTION: Function called by presMain.m. Remove >1000 spikes and
%       replace them with mean (1). Subtract 5-dbar from the values in 
%       PRES_SurfaceOffsetTruncatedPlus5dbar _dBAR. 
%   USAGE: pres3=presPerformqc(pres,offset,scalefactor)
%   INPUTS:
%       pres - raw pressure
%       offset - offset
%       scalefactor - scale factor
%       apex - Set to 1 to indicate an Apex float (default is zero)
%   OUTPUTS:
%       pres3 - QC'd pressure
%   VERSION HISTORY:
%       29 Jun. 2011: Current working version version, author unknown
%       08 Nov. 2017, Isabelle Gaboury: Added documentation
%       24 Nov. 2017, IG: Added optional apex keyword, removal of erroneous
%           values before deespiking as per the current version of the Argo
%           QC manual.

if nargin < 4, apex=0; end

pres1=(pres-offset)/scalefactor; %hpa to kpa

% As per version 3.0 of the Argo QC manual, remove erroneous outliers
if apex==1
    is_good = pres1<20 & pres1>-20;
    ii_bad = find(~is_good);
    ii_cur_good = find(is_good,1,'first');
    for ii=1:length(ii_bad)
        if ii_bad(ii)-1>ii_cur_good, ii_cur_good=ii_bad(ii)-1; end
        pres1(ii_bad(ii)) = pres1(ii_cur_good);
    end
end

%ok=abs(pres1)>=1000;
%moy=mean(pres1(~ok));
%pres1(ok)=moy;

%(2). Despike the SP time series to 1-dbar.
%This is most effectively done by first removing the more conspicuous
%spikes that are bigger than 4.9-dbar (as in the real-time procedure)
pres2=presDespikargo_ig(pres1,5,1000,3);

%then the more subtle spikes that are between 1- to 5-dbar by comparing the
%SP values with those derived from a 5-point (50 days) median filter.
pres3=presDespikargo_ig(pres2,1,1000,5);

disp('')
% a(1)=plot(sdn-sdn(1),pres1,'.r');
% a(2)=plot(sdn-sdn(1),pres3,'bo')
% legend(a,'Surface pressure in tech file, raw','Despiked and filtered');
% xlabel('Time (days)');
% ylabel('Pressure (dbar)');
% pause
% print('-dpng',[lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep 'pres_' floatname '.png']);
% 
% close all
end
