function allfloats=uniquefloatsindir(pathe)
allfiles=dir([pathe '*.nc']);
if ~isempty(allfiles)
    allfilenames=char(allfiles.name);
    allfloats=unique(allfilenames(:,2:8),'rows');
else
    allfloats=[];
end