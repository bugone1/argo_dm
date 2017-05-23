d=dir('*.mat');
for i=1:length(d)
    load(d(i).name);
    d(i).name
    ['before ' num2str(d(i).bytes)]
    save(d(i).name,'dates','lat','long','pres','ptmp','sal','source','temp','-v7');
    d(i)=dir(d(i).name);
    ['after ' num2str(d(i).bytes)]
    '-----'
    pause
end