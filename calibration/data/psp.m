%inven
clear
%find which % of files have been DMQCed

pathe={'2900000','3900000','4900000','4901000'};
fid=fopen('psp.txt','w');
for i=1:length(pathe)
    d=[dir([pathe{i} '\d*.nc']); dir([pathe{i} '\D*.nc'])];
    r=[dir([pathe{i} '\r*.nc']) ;dir([pathe{i} '\R*.nc'])];
    e=[d ;r];
    a=char(e.name);
    an=str2num(a(:,2:end-7));
    nu=unique(an);
    cyc=str2num(a(:,end-5:end-3));
    for j=1:length(nu)
        ok=find(an==nu(j));
        maxe=find(cyc==max(cyc(ok)) & nu(j)==an);
        nc=netcdf([pathe{i} filesep e(maxe(1)).name],'r');
        p1=nc{'PRES'}(:);
        p2=nc{'PRES_ADJUSTED'}(:);
        if isempty(p2)
        p2=nc{'PRES_CORRECTED'}(:);
        end            
        p2(p2==99999)=nan;
        psp2=unique(p1(:)-p2(:));
        e(maxe(1)).name
        nu(j)
        max(cyc(ok))
        e(maxe(1)).name
        fprintf(fid,[e(maxe(1)).name ' %6.3f \n'],psp2(1));
        close(nc)
    end
end
fclose(fid)