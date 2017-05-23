%function plotcoef
%Shows coefficients used for DMQC and the deepest reported salinity
%before/after last adjustment
clear
load coeff

col='rb';
for i=1:size(ufloats,1)
    load(['E:\RApps\argo_DM\data\float_calib\wjo\cal_' ufloats(i,:) '.mat'],'cal_COND','cal_SAL','cal_COND_err','cal_SAL_err');
    load(['E:\RApps\argo_DM\data\float_source\wjo\' ufloats(i,:) '.mat'],'PRES','TEMP','SAL','PTMP','PROFILE_NO','DATES','LAT','LONG');


    close all
    subplot(2,1,1)
    title(ufloats(i,:))
    for j=1:2
        co=squeeze(coeff(i,:,j));
        ok=find(~isnan(co));
        plot(ok,co(ok),['.-' col(j)])
        set(gca,'ylim',[.998 1.002])
    end
    clear psal psal_adj
    fil=dir(['E:\RApps\argo_DM\Calibration\output\changed\*' ufloats(i,:) '*.nc']);
    for j=1:length(fil)

        num=str2num(fil(j).name(10:12));
        %        k=PROFILE_NO(find(PROFILE_NO==num));
        cal_SAL(:,j)=sw_salt(cal_COND(:,j).*coeff(i,j,end)/sw_c3515,PTMP(:,j),0*SAL(:,j));
        subplot(2,1,2)
        nc=netcdf(['E:\RApps\argo_DM\Calibration\output\changed\' fil(j).name]);
        apsal=nc{'PSAL'}(:);
        if j==1
            ok=find(PTMP(:,j)<3);
            tem=PTMP(ok(1),j);
        else
            %[tr,ok]=min(abs(PTMP(:,j)-tem));
            ok=find(abs(abs(PTMP(:,j)-tem))<.03);
        end
        ok=50;
        if ~isempty(ok)
            ok=ok(1);
            psal(j)=apsal(ok(1));
            apsaladj=nc{'PSAL_ADJUSTED'}(:);
            apsaladj=cal_SAL(:,j);
            psal_adj(j)=apsaladj(ok(1));
        else
            psal(j)=nan;
            psal_adj(j)=nan;
        end
        ncclose
    end
    plot(psal)
    plot(psal_adj,'r.')
    pause
end