cd('E:\RApps\argo_DM\data\climatology\wjo\historical_ctd')
fil=dir('*.mat');
for i=1:length(fil)
    fil(i)
    load(fil(i).name)
    save(fil(i).name,'-V6')
end

cd('E:\RApps\argo_DM\data\constants')
cd 'wjo'
fil=dir('*.mat');
for i=1:length(fil)
    fil(i)
    load(fil(i).name)
    save(fil(i).name,'-V6')
end

cd('E:\RApps\argo_DM\data\float_calib')
cd 'wjo'
fil=dir('*.mat');
for i=1:length(fil)
    fil(i)
    load(fil(i).name)
    save(fil(i).name,'-V6')
end

cd('E:\RApps\argo_DM\data\float_mapped')
cd 'wjo'
fil=dir('*.mat');
for i=1:length(fil)
    fil(i)
    load(fil(i).name)
    save(fil(i).name,'-V6')
end

cd('E:\RApps\argo_DM\data\float_source')
cd 'wjo'
fil=dir('*.mat');
for i=1:length(fil)
    load(fil(i).name)
    save(fil(i).name,'-V6')
end

