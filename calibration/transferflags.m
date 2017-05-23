function t=transferflags(t1,t2)
%t1 contains new data
%t2 contains flags
i1=cat(1,t1.cycle_number);
i2=cat(1,t2.cycle_number);
i=intersect(i1,i2);
a.i=unique([i1;i2]);

fields1=fieldnames(t1);
fields2=fieldnames(t2);
a.fields=unique([fields1; fields2]);

[I,J]=deal(0);
for ii=1:length(a.fields)
    if isempty(strfind(a.fields{ii},'_qc'))
        I=I+1;
        fieldsfor1{I}=a.fields{ii};
    else 
        J=J+1;
        fieldsfor2{J}=a.fields{ii};
    end
end

for ii=1:length(i)
    ok=a.i==i(ii);
    for j=1:length(fieldsfor1)
        if isfield(t1(i1==i(ii)),fieldsfor1{j})
            t(ok).(fieldsfor1{j})=t1(i1==i(ii)).(fieldsfor1{j});
        end
    end
    for j=1:length(fieldsfor2)
        if isfield(t2(i2==i(ii)),fieldsfor2{j})
            t(ok).(fieldsfor2{j})=t2(i2==i(ii)).(fieldsfor2{j});
        end
    end
end

i=setdiff(i1,i2);
for ii=1:length(i)
    ok=a.i==i(ii);
    for j=1:length(fields1)
        t(ok).(fields1{j})=t1(i1==i(ii)).(fields1{j});
    end
end
i=setdiff(i2,i1);
for ii=1:length(i)
    ok=a.i==i(ii);
    for j=1:length(fields2)
        t(ok).(fields2{j})=t2(i2==i(ii)).(fields2{j});
    end
end