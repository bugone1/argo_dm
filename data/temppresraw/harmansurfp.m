e=dir('*.mat');
tt=1;
for tt=tt:length(e)
    load(e(tt).name)
    ymd=datevec(presscorrect.sdn(1:end-1));
    [x,i]=sort(datenum(0,ymd(:,2),ymd(:,3)));
    %y=presscorrect.pres(i)-mean(presscorrect.pres);
    y=presscorrect.orig_pres(i);
    y(abs(y)>15)=nan;    
    ry=diff(minmax(y));
    if ry==0
        ry=0.001;
    end
    yprim=y-nanmean(y);
    ran1=max(yprim)/2-0.001:(ry/10):max(yprim)+.001;
    ran2=1:365;    
    clear d
    for i=1:length(ran1)
        for j=1:length(ran2)
            yy=harman3([0 ran1(i) ran1(i) 0 0 0 0],x-ran2(j))';            
            %        plot(x,y)
            %        plot(x,yy,'r');
            d(i,j)=sum((yy-yprim).^2);
            %        title(num2str(d(i,j)))
            %        pause
        end
    end
    [u,v]=find(d<=min(d(:)));
    if ~isempty(u)
        uu=ran1(u(1));
        vv=ran2(v(1));
    else
        uu=min(ran1);
        vv=ran2(1);
    end
    
    plot(x,y,'or')
    l=plot(0:366,harman3([nanmean(y) uu uu 0 0 0 0],(0:366)-vv),'k');
    set(gca,'xtick',datenum(0,1:12,1))
    set(gca,'xticklabel',datestr(get(gca,'xtick'),'mmm'));
    set(gca,'xlim',[0 366]);
    tii{1}=['Relative surface pressure measured by ' e(tt).name(1:end-4) ' from ' num2str(ymd(1)) '-' num2str(ymd(end,1))];
    oo=length(t);
    tii{2}=[num2str(t(fix(oo/2)).longitude) ' ' num2str(t(fix(oo/2)).latitude)];
    title(tii)
    
    ylabel('Pressure (dbar)');
    xlabel('Time of year (mmm)');
    legend(l,['Sinusoid; phi=' num2str(vv) ' d, A=' num2str(uu) ' dbar'])
    print('-dpng',[e(tt).name '_pres.png']);
    close
end