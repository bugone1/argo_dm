function [adj,R,r]=rmsfit(lon,lat,mois,temp,pres,psal,range)
adj=[nan nan];
ly2=length(pres)/10;
if ~isempty(psal)
    sal=getClim(lon,lat,mois,'PSAL');
    jj=0;
    for ii=-range:range
        jj=jj+1;
        y=interp1(sal.pres,mean(sal.temp,2),pres+ii); %interpolate climatology as if it were deeper
        r2(jj)=sum(isnan(y));
        if r2(jj)<ly2
        rms(jj)=nanmeanstd((psal-y).^2);
        else
        rms(jj)=nan;
        end
        d(jj)=ii;
    end
    [r(1),i]=min(rms);        
    adj(2)=d(i);
    r(2)=r2(i);
end
if ~isempty(temp)
    sal=getClim(lon,lat,mois,'TEMP');
    jj=0;
    for ii=-range:range
        jj=jj+1;
        y=interp1(sal.pres,mean(sal.temp,2),pres+ii); %interpolate climatology as if it were deeper
        R2(jj)=sum(isnan(y));
        if R2(jj)<ly2
        rms(jj)=nanmeanstd((temp-y).^2);
        else
        rms(jj)=nan;
        end
        d(jj)=ii;
    end
    [R(1),i]=min(rms);
    adj(1)=d(i);
    R(2)=R2(i);
end