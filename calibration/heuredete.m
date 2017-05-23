function aju=heuredete(nowe)
%Du deuxième dimanche de mars inclus ou premier dimanche de novembre exclus
ymd=datevec(nowe(1));
[tr,iMarDim1]=intersect(datestr(datenum(ymd(1),3,1:7),8),'Sun','rows');
[tr,iNovDim1]=intersect(datestr(datenum(ymd(1),11,1:7),8),'Sun','rows');
marDim2=iMarDim1+datenum(ymd(1),3,0);
novDim1=iNovDim1+datenum(ymd(1),11,0);
aju=6-(nowe>=marDim2 & nowe<novDim1);