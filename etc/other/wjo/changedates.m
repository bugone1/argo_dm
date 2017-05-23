% This function changes dates in format YYYYMMDDhhmmss to a
% decimal number. The input dates can be in either a single
% row or a single column, but the output dates are organised
% in a single column.
%
% A. Wong, 29 May 2001
%
%Changed by <MO> to account for leap years ; no need to use cal2dec; using matlab builtin sdn functions
%Also optimized the code; what used to take 31 s now takes 1 s
%However, it doesn't seem that there ever were seconds in the input

function [dates]=changedates(dates_format2)
%tic
if diff(size(dates_format2))>0
    dates_format2=dates_format2';
end
tosubtract=[];
years=fix(dates_format2/1e10);
tosubtract=years*1e10;
months=fix((dates_format2-tosubtract)/1e8);
tosubtract=tosubtract+months*1e8;
days=fix((dates_format2-tosubtract)/1e6);
tosubtract=tosubtract+days*1e6;
hours=fix((dates_format2-tosubtract)/1e4);
tosubtract=tosubtract+hours*1e4;
minutes=fix((dates_format2-tosubtract)/1e2);
tosubtract=tosubtract+minutes*1e2;
isleap=(mod(years,400)==0 | (mod(years,4)==0 & mod(years,100)~=0)); %leap years
dates=years+(datenum(years,months,days,hours,minutes,0)-datenum(years,1,1))./(365+isleap);
%toc
% tic %ANnie's version : too long
% dates=NaN.*ones(length(dates_format2),1); %organise dates in a single column
% for i=1:length(dates_format2)
%  if(isnan(dates_format2(i))==0)
%   junk=int2str(dates_format2(i));
%   yr=str2num(junk(:,1:4));
%   mo=str2num(junk(:,5:6));
%   day=str2num(junk(:,7:8));
%   hr=str2num(junk(:,9:10));
%   min=str2num(junk(:,11:12));
%   if(mo<1|mo>12|day<1|day>31)
%    dates(i)=yr;
%   else
%    dates(i)=yr+cal2dec(mo,day,hr,min)./365;
%   end
%  end
% end
% 
% toc