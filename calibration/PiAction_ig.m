function v=PiAction_ig(profile_no,condslope,oldcoeff)
% PIACTION_IG Create a conductivity adjustment curve based on OW results
%   DESCRIPTION: This modified version of PiAction allows the user to draw
%   	a conversion curve as a series of line segments, rather than
%   	iterating through PiAction multiple times.
%   USAGE: v=PiAction_ig(profile_no,condslope,oldcoeff)
%   INPUTS:
%       profile_no - Vector of profile numbers
%       condslope - Existing conductivity slope, 1 per profile number
%       oldcoeff - Existing conversion coefficients
%   OUTPUTS:
%       v - Array of adjustment data structures, one per segment
%   VERSION HISTORY:
%       4 Aug. 2017, Isabelle Gaboury: Written, based on PiAction.m 

%Called by processcycle.m
profile_no=double(profile_no);
condslope=double(condslope);
oldcoeff=double(oldcoeff);
close
plot(profile_no,oldcoeff,'r.')
if length(condslope)>20
    condfit=condslope(end-20:end);
    profit=profile_no(end-20:end);
else
    condfit=condslope;
    profit=profile_no;
end
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
% foo = get(gca,'ylim');
% set(gca,'ylim',[foo(1),max(foo(2),1)]);
ishappy=0;firsttime=0;
hold on
text_lc = 'Left-click points to select, ''q'' if done';
text_rc = 'Right-click to confirm, ''q'' if done';
texte=text(.1,.9,text_lc,'Units','Normalized','BackgroundColor',[.7 .9 .7]);
while ishappy~=1
    if ~firsttime
        plot(profile_no,condslope,'-bo');
        sq=plot(profit,condcalc,'gs'); %green squares are calculated values according to fit
        vax=axis;
        axis([vax(1)-1,vax(2)+1,vax(3)-.00025,vax(4)+.00025]);
        dot1 = plot(NaN,NaN,'ro-',NaN,NaN,'ro');
        fitligne = plot(NaN,NaN,'-g','Linewidth',4);
    end
    firsttime=1;
    set(texte,'visible','on')
    but=1;
    x_all=[];
    y_all=[];
    while but ~= 'q'
        [x_temp,y_temp,but]=ginput(1);
        if but==1
            x=round(x_temp);
            y=y_temp;
            set(dot1(2),'xdata',x,'ydata',y);
            set(texte,'string',text_rc);
        elseif but==3
            x_all=[x_all x];
            y_all=[y_all y];
            [x_all,ii]=sort(x_all);
            y_all=y_all(ii);
            set(dot1(1),'xdata',x_all,'ydata',y_all);
            set(dot1(2),'xdata',NaN,'ydata',NaN);
            set(texte,'string',text_lc);
        end
    end
    set(texte,'visible','off')
    p1=diff(y_all)./diff(x_all);
    p2=y_all(1:end-1)-x_all(1:end-1).*p1; %note that the corrected conductivity is CONDraw*(offset+slope*PROFILE_NO)
    tit_str={};
    fitligne_x=zeros(1,length(x_all));
    fitligne_y=zeros(1,length(x_all));
    profit_all=[];
    condcalc_all=[];
    sigma_err_all=zeros(1,length(x_all)-1);
    v=struct();
    for ii=1:length(x_all)-1
        ok=find(profile_no>=x_all(ii) & profile_no<=x_all(ii+1));
        profit=profile_no(ok);
        condcalc=p1(ii)*profit+p2(ii);
        sigma_err_all(ii)=nansum(sqrt((condcalc-condslope(ok)).^2));
        tit_str{ii}=['From ' num2str(x_all(ii)) ' to ' num2str(profit(end)) '; m=' num2str(p1(ii)) ' b=' num2str(p2(ii)) '; RMS err=' num2str(sigma_err_all(ii))];
        fitligne_x(ii:ii+1)=profit([1 end]);
        fitligne_y(ii:ii+1)=p2(ii)+p1(ii)*profit([1 end]);
        profit_all=[profit_all,profit];
        condcalc_all=[condcalc_all,condcalc];
        v(ii).condcalc=condcalc
        v(ii).start=x_all(ii);
        if ii==length(x_all)-1
            v(ii).end=profit(end);
        else
            v(ii).end=profit(end)-1;
        end
        v(ii).slope=p1(ii);
        v(ii).offset=p2(ii);
        v(ii).err=sigma_err_all(ii);
        v(ii).prof=profit;
        v(ii).ok=ok;
    end
    set(fitligne,'xdata',fitligne_x,'ydata',fitligne_y,'visible','on');
    set(sq,'xdata',profit_all,'ydata',condcalc_all,'visible','on');
    title(tit_str);
    set(texte,'string','Are you happy with fit ? (LeftClick if Yes, RightClick if No)','visible','on');
    [tr,tr,ishappy]=ginput(1);
    if ishappy~=1
        set(sq,'visible','off')
        set(fitligne,'visible','off')
    end
end

