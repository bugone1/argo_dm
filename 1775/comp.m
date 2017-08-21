if pc
    addpath('w:\m_map');addpath('w:\vms_tools');addpath('w:\gsw');addpath('w:\gsw\pdf');addpath('w:\gsw\html');addpath('w:\gsw\library');
else
    addpath('/u01/rapps/m_map');addpath('/u01/rapps/vms_tools');addpath('/u01/rapps/gsw');addpath('/u01/rapps/gsw/pdf');addpath('/u01/rapps/gsw/html');addpath('/u01/rapps/gsw/library');
end
floatnum='4901109';
if ispc
    pathe='w:\argo_dm\data\temppresraw';
else
    pathe='/u01/rapps/argo_dm/data/temppresraw';
end
load([pathe filesep floatnum],'t');
ll=[cat(1,t.longitude)  cat(1,t.latitude)];
sdn=cat(1,t.dates);
rond(minmax(ll(:,1))+[-1 1]*.05,2)
rond(minmax(ll(:,2))+[-1 1]*.05,2)
datestr(minmax(sdn))
%do request
%[stat,prf]=getLatestMedsAsciiFile;
d=dir('MEDS*.mat');
i=1;
for i=i:length(d)
    i
    load(d(i).name,'stat');
    [todel,tokeep]=get_notstlawrence(stat);
    if length(tokeep)<length(stat)
        if isempty(tokeep)
            'deleting'
            d(i).name
            delete(d(i).name);
        else
            stat=stat(tokeep);
            load(d(i).name,'prf');
            prf=prf(tokeep,:);
            d(i).name
            length(stat)
            save(d(i).name,'stat','prf');
        end
    end
end
if ispc
    cd('w:\1775');
end
[stat,inde]=agg_ocproc_stat('MEDS');
[todel,tokeep0]=get_bestversion0(stat);
[todel,tokeep1]=get_bestversion1(stat(tokeep0));
[todel,tokeep2]=get_bestversion2(stat(tokeep0(tokeep1)));
tokeep=tokeep0(tokeep1(tokeep2));
todel=setdiff(1:length(stat),tokeep);
% d=dir('MEDS*.mat');
% for i=1:length(d)
%     if any(todel>((i-1)*1000+0) & todel<((i-1)*1000+1001))
%         load(d(i).name,'stat')
%         ok=setdiff((i-1)*1000+(1:length(stat)),todel)-((i-1)*1000);
%         if length(ok)~=length(stat)
%             stat=stat(ok);
%             load(d(i).name,'prf')
%             prf=prf(ok,:);
%             d(i).name
%             save(['n' d(i).name],'stat','prf');
%         end
%     end
% end

stat=stat(tokeep);
inde=inde(tokeep,:);


crn=get_crnumber(stat);nok=strmatch(['Q' floatnum],crn);ok=setdiff(1:length(stat),nok);stat=stat(ok);inde=inde(ok,:);
crn=get_fxd(stat,'DATA_TYPE');nok=strmatch('BO',crn);ok=setdiff(1:length(stat),nok);stat=stat(ok);inde=inde(ok,:);
xyt1=[get_ll(stat) get_sdn(stat)];
xyt2=[cat(1,t.longitude) cat(1,t.latitude) cat(1,t.dates)];

if ispc
    !del *.png
end

clear k j
for i=1:size(xyt2,1)
    clear d
    for jj=1:3
        d(:,jj)=xyt2(i,jj)-xyt1(:,jj);
    end
    dd=sum(d'.^2)';
    [k(i),j(i)]=min(dd);
    dis(i)=geodist(xyt2(i,[2 1]),xyt1(j(i),[2 1]))/1000;
end

for i=length(j):-1:1
    close all;
    load(sprintf('MEDS_ASCII0911253358_%3.3i',inde(j(i),1)),'prf');
    o=alignocprocprof(prf(inde(j(i),2),:));
    if isfield(o,'pres')
        z=o.pres;
    else
        z=gsw_p_from_z(-o.deph,t(i).latitude);
    end
    [pres,ii,jj]=intersect(round(t(i).pres),round(z));
   % if isempty(pres)
        tem=interp1(z,o.temp,t(i).pres);
        sal=interp1(z,o.psal,t(i).pres);
        d1=t(i).psal-sal;
        d2=t(i).temp-tem;
        pres=t(i).pres;
    %else
        d1=t(i).psal(ii)-o.psal(jj)';
       d2=t(i).temp(ii)-o.temp(jj)';
    %end
    subplot(2,2,1); hold on;grid;
    plot(t(i).psal,t(i).pres,'b.-');
    plot(o.psal,z,'ro-');
    xlabel('PSAL');
    set(gca,'ylim',minmax([t(i).pres z']),'xlim',minmax([t(i).psal o.psal']),'ydir','reverse')
    title(['blue = ' floatnum  sprintf('%4.4f %4.4f ',xyt2(i,1:2)) datestr(xyt2(i,3),' yyyy-mm-dd HH') ' ' sprintf('%ikm',round(dis(i)))]);
    subplot(2,2,2); hold on;grid;
    title(['red = ' stat(j(i)).FXD.CR_NUMBER ' ' sprintf('%4.4f %4.4f ',xyt1(j(i),1:2)) datestr(xyt1(j(i),3),' yyyy-mm-dd HH')]);
    xlabel('TEMP');
    plot(t(i).temp,t(i).pres,'b.-');
    plot(o.temp,z,'ro-');
    set(gca,'ylim',minmax([t(i).pres z']),'xlim',minmax([t(i).temp o.temp']),'ydir','reverse')
    subplot(2,2,3); hold on;grid;
    d=t(i).psal(ii)-o.psal(jj)';
    if any(~isnan(d1))
        plot(pres,d1,'.-');
        set(gca,'ylim',max(abs(d1))*[-1 1]);
        xlabel('PRES');
        ylabel('\deltaS');
        set(gca,'xlim',[0 2000],'yminortick','on');
    end
    subplot(2,2,4); hold on;grid;
    if any(~isnan(d2))
        plot(pres,d2,'.-');
        set(gca,'ylim',max(abs(d2))*[-1 1]);
        xlabel('PRES');
        ylabel('\deltaT');
        set(gca,'xlim',[0 2000],'yminortick','on');
    end
    set(gcf,'position',[1 45 1920 1088]);
    print('-dpng',sprintf('%3.3i',i));
    close;
end