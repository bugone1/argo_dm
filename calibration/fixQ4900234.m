%NOVEMBER 2009
%This was created to fix a problem signaled by John Gilson
%Was ran after Viewplotsnew.m

%1-plotting
close all
k=dir([local_config.OUT 'changed' filesep '*234*.nc']);
col='rbgmy';
for i=1:length(k)
    nc=netcdf([local_config.OUT 'changed' filesep k(i).name],'r');
    tem=nc{'PSAL_ADJUSTED'}(:);
    tem(tem==99999)=nan;
    figure(1)
    plot(nc{'PRES'}(:),tem,col(i))
    figure(2)
    plot(nc{'TEMP'}(:),nc{'PSAL_ADJUSTED'}(:),col(i))
    ncclose
end
k=dir([local_config.DATA 'ingested' filesep '*234*.nc']);
for i=1:length(k)
    nc=netcdf([local_config.DATA 'ingested' filesep k(i).name],'r');
    tem=nc{'PSAL_ADJUSTED'}(:);
    tem(tem==99999)=nan;
    z=sw_ptmp(nc{'PSAL_ADJUSTED'}(:),nc{'TEMP'}(:),nc{'PRES'}(:),0);
    diff=abs(z-3.3);    
    [pres(i),ok]=min(diff);
    psal(i)=sw_cndr(tem(ok),nc{'TEMP'}(ok),nc{'PRES'}(ok));
    figure(1)
    plot(nc{'PRES'}(:),tem,'k')
    figure(2)
    plot(nc{'TEMP'}(:),nc{'PSAL'}(:),'k')
    ncclose
end
%good conductivity at ~3.3 should be
%0.67471791970975
%apply:
%cycle 66:      1.062692
%cycle 67:70 :  1.065272


%2-Enforce special message for this case
k=dir([local_config.OUT 'changed' filesep '*234*.nc']);
for i=1:length(k)
    nc=netcdf([local_config.OUT 'changed' filesep k(i).name],'w');
    nc{'DATA_MODE'}(:)='D';
    ok=nc{'PSAL_QC'}(:)~='4';    tem=nc{'PSAL_ADJUSTED_QC'}(:);    tem(ok)='3';    
    ok=nc{'PSAL_ADJUSTED'}(:)==99999;    tem(ok)='4';    nc{'PSAL_ADJUSTED_QC'}(:)=tem;
    ok=tem=='4';    tem=nc{'PSAL_ADJUSTED'}(:);    tem(ok)=99999;    nc{'PSAL_ADJUSTED'}(:)=tem;

    tem=nc{'PSAL_ADJUSTED_ERROR'}(:);
    newerr=nc{'PRES_ADJUSTED'}(:)*(-0.518+0.144)/2000+.518;
    newerr(ok)=99999;
    nc{'PSAL_ADJUSTED_ERROR'}(:)=newerr;

    nc{'SCIENTIFIC_CALIB_COMMENT'}(1,end,3,:)=netstr(['Correction applied to conductivity was based on theta=3.3ºC but is the result of an abrupt change. The correction is suspiciously high. Error on adjusted salinity has been assessed by a acomparison with nearby profiles. Interpret with caution.'],256);
    
    tem2=nc{'PSAL_QC'}(:);
    tem2=char('3'+tem2*0);
    nc{'PSAL_QC'}(:)=tem2;
    ncclose
end