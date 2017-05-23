function v=PiAction(profile_no,condslope,endpoint,oldcoeff)
%function v=PiAction(profile_no,condslope,endpoint,oldcoeff)
%Called by processcycle.m
profile_no=double(profile_no);
condslope=double(condslope);
oldcoeff=double(oldcoeff);
endpoint=double(endpoint);
close
plot(profile_no,oldcoeff,'r.')
if length(condslope)>20
    condfit=condslope(end-20:end);
    profit=profile_no(end-20:end);
else
    condfit=condslope;
    profit=profile_no;
end
profit=profit;
condfit=condfit;
cond_ok=find(condfit>.5 & condfit<1.5 & ~isnan(condfit));
cond_ok=~isnan(condfit);
p=polyfit(profit(cond_ok),condfit(cond_ok),1);
condcalc=p(1)*profit+p(2);
if sum(abs(p))==0
    condcalc=(profit*0)+1;
end
plot(profit(cond_ok),condfit(cond_ok),'r+'); %Red crosses are condfit values between .5 and 1.5
xlabel('Profile Number');
ylabel('Conductivity Slope Correction');
set(gca,'xlim',[1 max(profile_no)]);
ishappy=0;firsttime=0;
while ishappy~=1
    hold on
    plot(profile_no,condslope,'-bo');
    sq=plot(profit,condcalc,'gs'); %green squares are calculated values according to fit
    if ~firsttime
        vax=axis;
        axis([vax(1)-1,vax(2)+1,vax(3)-.00025,vax(4)+.00025]);
    end
    firsttime=1;
    texte=text(.1,.9,'Start Point (LeftClick to select)','Units','Normalized','BackgroundColor',[.7 .9 .7]);
    but=1;
    while but==1
        [xi,yi,but]=ginput(1);
        xi=round(xi);
        if but == 1
            if exist('dot1')
                set(dot1,'visible','off')
                clear dot1
            end
            dot1=plot(xi,yi,'ro');
            set(texte,'visible','off')
            texte=text(.1,.9,'Start Point (RightClick to confirm)','Units','Normalized','BackgroundColor',[.7 .9 .7]);
        end
    end
    but=1;
    if isnan(endpoint(1))
        clear texte
        texte=text(.1,.9,'End Point (LeftClick to select)','Units','Normalized','BackgroundColor',[.7 .9 .7]);
        while but==1
            [xf,yf,but]=ginput(1);
            xf=profile_no(end);
            if but == 1
                if exist('dot1')
                    set(dot1,'visible','off')
                    clear dot1
                end
                dot1=plot(xf,yf,'ro');
                set(texte,'visible','off')
                texte=text(.1,.9,'End Point (RightClick to confirm)','Units','Normalized','BackgroundColor',[.7 .9 .7]);
            end
        end
    else
        xf=endpoint(1);
        yf=endpoint(2);
    end
    p(1)=(yf-yi)/(xf-xi);
    p(2)=yi-xi*p(1); %note that the corrected conductivity is CONDraw*(offset+slope*PROFILE_NO)
    ok=find(profile_no>=xi & profile_no<=xf);
    profit=profile_no(ok);
    condcalc=p(1)*profit+p(2);
    sigma_err=nansum(sqrt((condcalc-condslope(ok)).^2));
    fitligne=plot(profit([1 end]),p(2)+p(1)*profit([1 end]),'-g','Linewidth',4);
    title(['From ' num2str(xi) ' to ' num2str(profile_no(end)) '; m=' num2str(p(1)) ' b=' num2str(p(2)) '; RMS err=' num2str(sigma_err)]);
    texte=text(.1,.9,'Are you happy with fit ? (LeftClick if Yes, RightClick if No)','Units','Normalized','BackgroundColor',[.7 .9 .7]);
    [tr,tr,ishappy]=ginput(1);
    if ishappy~=1
        set(sq,'visible','off')
        set(fitligne,'visible','off')
    end
end

v.condcalc=condcalc;
v.start=xi;
v.end=profile_no(end);
v.slope=p(1);
v.offset=p(2);
v.err=sigma_err;
v.prof=profile_no(ok);
v.ok=ok;

function out=nansum(in)
in(isnan(in))=0;
out=sum(in);