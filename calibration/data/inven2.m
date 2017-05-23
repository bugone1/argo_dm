clear upsal upres ufile fnam
notready=0;
k=0;kk=0;
datte=zeros(sum(tr+td),1);
for i=1:length(tr)
    for j=1:tr(i)
        nc=netcdf(fullfile(pathe{i},r{i}(j).name),'r');
        if ~isempty(nc)
            k=k+1;
            datte(k)=nc{'JULD'}(:)+datenum(1950,1,0);
            if datte(k)<datenum(1995,1,1)
                datestr(datte(k))
                pause
            end
            notready=notready+((datte(k)+182.5)>datenum(2009,9,18));
        else
            'EMPTY'
            r{i}(j).name
            pause
        end
        close(nc);
    end
    for j=1:td(i)
        [j td(i)]
        nc=netcdf(fullfile(pathe{i},d{i}(j).name),'r');
        if ~isempty(nc)
            tdate=nc{'JULD'}(:)+datenum(1950,1,0);
            if tdate<datenum(1995,1,1)
                datestr(tdate)
                pause
            else
                k=k+1;
                kk=kk+1;
                datte(k)=tdate;
            uui=nc{'PARAMETER'}(:);
            [ttr,okpsal]=intersect(uui(:,1:4),'PSAL','rows');
            [ttr,okpres]=intersect(uui(:,1:4),'PSAL','rows');
            caldate=nc{'CALIBRATION_DATE'}(:);
            upsal{kk}=caldate(okpsal,:);
            upres{kk}=caldate(okpres,:);
            ufile{kk}=nc{'DATE_CREATION'}(:);
            fnam{kk}=d{i}(j).name;
            end
        else
            'EMPTY'
            r{i}(j).name
            pause
        end
        close(nc);
    end
end
datte=datte(1:k);

j=0; clear num
ymd=datevec(datte);
t1=datevec(min(datte));
t2=datevec(max(datte));
for y=t1(1):t2(1)
    ok1=ymd(:,1)==y;
%    for m=1:12
        j=j+1;
        ok=ok1;% & ymd(:,2)==m;
        num(j)=sum(ok);
%    end
end
plot(t1(1)+1:t2(1),diff(num),'.')
pourc=sum(td)/(sum(td+tr)-notready);

psal=char(upsal);
psal(psal==' ')='0';
ym=[str2num(psal(:,1:4)) str2num(psal(:,5:6))];
ok=find(ym(:,1)==2008 & ym(:,2)==9);
nam=char(fnam{ok});
flo=unique(nam(:,2:8),'rows');
unique(ufile(ok))

pres=char(upres);
pres(pres==' ')='0';
ym=[str2num(pres(:,1:4)) str2num(pres(:,5:6))];
ok=find(ym(:,1)==2008 & ym(:,2)>8);
nam=char(fnam{ok});
flo=unique(nam(:,2:8),'rows');
unique(ufile(ok))

