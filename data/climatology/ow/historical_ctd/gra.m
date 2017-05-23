d=dir('ctd*');
for i=1:length(d)
    [i length(d)]
    load(d(i).name,'lat','long');
    
    ll=unique([long; lat]','rows');
    plot(ll(:,1),ll(:,2),'.');
    ll1=double(minmax(ll(:,1)));
    ll2=double(minmax(ll(:,2)));
    plot(ll1([1 1 2 2 1]),ll2([1 2 2 1 1]),'k');
    text(mean(ll1),mean(ll2),strtok(d(i).name(5:end),'.'));
    hold on
end


pate1='c:\z\box\';
pate2='w:\';
d=dir([pate2 'MEDS_ASCII0710421600_*.mat']);
for j=1:length(d)
    d(j).name
    load([pate2 d(j).name],'stat');
    z=[];
    for i=1:length(stat)
        prof=cat(1,stat(i).PROF);
        okk=strmatch('TEMP',char(prof.PROF_TYPE));
        if ~isempty(okk)
            z(i)=stat(i).PROF(okk).DEEP_DEPTH;
        end
    end
    ok=z>200;
    stat=stat(ok);
    if ~isempty(stat)
        load([pate2 d(j).name],'prf');
        prf=prf(ok,:);
        save([pate1 d(j).name],'stat','prf');
    end
    z(ok)
    delete([pate2 d(j).name]);
end
