function [nr,start,SAL,TEMP,PTMP,PRES,REJECT_SAL]=gredit_confirm(SAL,TEMP,PTMP,PRES,REJECT_SAL,PROFILE_NO,flnm)
%function [nr,start,SAL,TEMP,PTMP,PRES,REJECT_SAL]=gredit_confirm(SAL,TEMP,PTMP,PRES,REJECT_SAL,PROFILE_NO,flnm)
%called by pre_WJO
close all;
h6=figure(6);
[m,n]=size(PRES);
JJ=ones(m,n);
for ii=1:m;
    for jj=1:n;
        PRESOFF(ii,jj)=PRES(ii,jj)+60*jj;
        TEMPOFF(ii,jj)=TEMP(ii,jj)+.4*jj;
        SALOFF(ii,jj)=SAL(ii,jj)+.2*jj;
        JJ(ii,jj)=ii;
    end
end

axedesx=PRESOFF;
axedesy=JJ;
plot(axedesx,axedesy,'-+');
v=axis;axis([v(1)-100,v(2)+100,v(3),v(4)]);xlabel('Offset Pressure');ylabel('Level');
cascade={'PRES','TEMP','PTMP','SAL'};
[PRES,TEMP,PTMP,SAL,REJECT_SAL,nr,start]=qc_window(PRES,TEMP,PTMP,SAL,axedesx,axedesy,REJECT_SAL,PROFILE_NO,flnm,cascade,0);

axedesx=TEMPOFF;
axedesy=-PRES;
plot(axedesx,axedesy,'-+');
v=axis;axis([v(1)+.25,v(2)+.25,-2100,10]);xlabel('Offset Temp');ylabel('Pressure');
cascade={'TEMP','PTMP','SAL'};
[PRES,TEMP,PTMP,SAL,REJECT_SAL,nr,start]=qc_window(PRES,TEMP,PTMP,SAL,axedesx,axedesy,REJECT_SAL,PROFILE_NO,flnm,cascade,nr);

axedesx=SALOFF;
plot(axedesx,axedesy,'-+');xlabel('Offset Psal');ylabel('Pressure');
v=axis;axis([v(1)+.25,v(2)+.25,-2100,10]);
cascade={'SAL'};
[PRES,TEMP,PTMP,SAL,REJECT_SAL,nr,start]=qc_window(PRES,TEMP,PTMP,SAL,axedesx,axedesy,REJECT_SAL,PROFILE_NO,flnm,cascade,nr);

axedesx=SAL;
axedesy=TEMP;
load as as
plot(as(:,1),as(:,2),'color',4*ones(3,1)/5,'linestyle','none','marker','.','markersize',3);
clear as
plot(axedesx,axedesy,'-+');xlabel('Psal');ylabel('Temp');
set(gca,'xlim',minmax(axedesx)+[-1 1]/4,'ylim',minmax(axedesy)+[-1 1]/4);
cascade={'SAL'};
[PRES,TEMP,PTMP,SAL,REJECT_SAL,nr,start]=qc_window(PRES,TEMP,PTMP,SAL,axedesx,axedesy,REJECT_SAL,PROFILE_NO,flnm,cascade,nr);

hold off;

function [PRES,TEMP,PTMP,SAL,REJECT_SAL,nr,start]=qc_window(PRES,TEMP,PTMP,SAL,axedesx,axedesy,REJECT_SAL,PROFILE_NO,flnm,cascade,nr)
title(strcat('Argo Float: ',flnm(end-10:end)));
hold on;
disp 'Left mouse button picks points.'
disp 'Right mouse button when finished'
but=1;
[mr nr]=size(REJECT_SAL);
start=nr;
while but == 1;
    [xi,yi,but]=ginput(1);
    if but ~= 1; break; end;
    %Pythagoras:
    pdif=(axedesx-xi)/diff(get(gca,'xlim')); idif=(axedesy-yi)/diff(get(gca,'ylim')); dif=sqrt(pdif.^2+idif.^2);
    [C,I]=min(dif);[D,J]=min(C);
    plot(axedesx(I(J),J),axedesy(I(J),J),'bo')
    confirm=0
    confirm=input('Confirm? (= 1)  ')
    if confirm == 1
        nr=nr+1;
        REJECT_SAL(:,nr)=[I(J);PROFILE_NO(J);now]; %since J could be re-sorted, use the profile number to track changes instead of J
        for i=1:length(cascade)
            eval([cascade{i} '(I(J),J)=NaN;']);
        end
    end
end
close all