%inven
clear
%find which % of files have been DMQCed

pathe={'2900000','3900000','4900000','4901000'};

for i=1:length(pathe)
d{i}=[dir([pathe{i} '\d*.nc']) dir([pathe{i} '\D*.nc'])];
r{i}=[dir([pathe{i} '\r*.nc']) dir([pathe{i} '\R*.nc'])];
end

for i=1:length(r)
    td(i)=length(d{i});
    tr(i)=length(r{i});
    if td(i)>0 && tr(i)>0
        e1=char(d{i}.name);
        e2=char(r{i}.name);
        num1=e1(:,2:end);
        num2=e2(:,2:end);
        [commun,I,J]=intersect(num1,num2,'rows');        
        if ~isempty(commun)
            for j=1:length(commun)
                delete(fullfile(pathe{i},['r' commun(j,:)]))
            end
        end
        r{i}=[dir([pathe{i} '\r*.nc']) dir([pathe{i} '\R*.nc'])];
        tr(i)=length(r{i});
    end
end

