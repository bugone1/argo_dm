%function plotcoef
%Shows coefficients used for DMQC and carefully chosen interpolated salinity 
%before/after last adjustment
clear
n_min=.05;
load coeff coeff ufloats
col='rg'; sym='o.';
for i=1:size(ufloats,1)
    title(ufloats(i,:))
    subplot(2,1,1)
    load(['E:\RApps\argo_DM\data\float_mapped\wjo\map_' ufloats(i,:)],'la_INTERP_SAL','la_standard_levels','la_INTERP_PRES','la_profile_no')
    for k=1:2
        s=length(la_profile_no);
        co=squeeze(coeff(i,1:s,k));
        ok=find(~isnan(co));
        a(k)=plot(la_profile_no(ok),co(ok),[sym(k) col(k)]);
        if max(co)>1.001
            set(gca,'ylim',[.998 1.002],'xlim',[1 ok(end)])
        else
            set(gca,'ylim',[.999 1.001],'xlim',[1 ok(end)])
        end
        plot(la_profile_no([1 end]),[1 1],'k-')
    end
    ylabel('(mmho/cm)')
    xlabel('Cycle #');
    legend(a,char('Penultimate Calibration','Latest Calibration'),3);
    title([ufloats(i,:) ' potential conductivity multiplicative correction factor']);
    clear cndr sal
    lq=size(la_INTERP_SAL);
    for j=1:lq(2)
        cndr(:,j)=sw_cndr(la_INTERP_SAL(:,j),la_standard_levels,la_INTERP_PRES(:,j));
        ok=find(~isnan(coeff(i,j,:)));
        if isempty(ok)
            sal(1:lq(1),j)=nan;
        else
            sal(1:lq(1),j)=sw_salt(cndr(:,j)*coeff(i,j,ok(end)),la_standard_levels,la_INTERP_PRES(:,j));
        end
    end
    ok=find(la_standard_levels<3); ok=ok(1);
    n=sum(~isnan(la_INTERP_SAL),2);
    tr=max(n(ok:end));
    j=find(n==tr);    j=j(end);
    if (tr/lq(2))<n_min
        ok=find(n>n_min*lq(2));
        j=ok(end);
    end
    subplot(2,1,2)
    title([ufloats(i,:) ' salinities interpolated on \theta=' num2str(la_standard_levels(j)) 'ºC']);
    a(1)=plot(la_profile_no,la_INTERP_SAL(j,:),'b*-');
    a(2)=plot(la_profile_no,sal(j,:),'g*-');
    legend(a,char('Uncalibrated','Latest Calibration'),3);
    xlabel('Cycle #')
    ylabel('(PSS-78)');
    print('-dpng',['diag_' ufloats(i,:)]);
    close
end