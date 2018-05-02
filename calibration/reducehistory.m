function reducehistory(local_config,floatname)
if ~isempty(local_config)
pathe=[local_config.OUT 'changed' filesep ];
if ~iscell(floatname)
    fl{1}=floatname;
    floatname=fl;
end
else
    pathe='';
end
for j=1:length(floatname)
    d=dir([pathe '*' floatname{j} '*.nc']);
    for i=1:length(d)
        reducehistory_i([pathe d(i).name]);
    end
end
end

