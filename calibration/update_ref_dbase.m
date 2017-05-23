load(fullfile(config.CONFIG_DIRECTORY,config.CONFIG_WMO_BOXES),'la_wmo_boxes');
a.data_types={'ctd','bot','argo'};
%Enter WMO#s to exclude
a.exclude.ctd=[]; %-1 to exclude all
a.exclude.bot=[]; %-1 to exclude all
a.exclude.argo=[];   %-1 to exclude all
for i=1:3
    a.floats=dir(fullfile(config.HISTORICAL_DIRECTORY,['historical_' a.data_types{i}],'*.mat'));
    a.fnames=char(a.floats.name);
    a.underscore=find(a.fnames(1,:)=='_');
    a.wmo_boxes=str2num(a.fnames(:,a.underscore+1:end-4));
    [a.tr,a.ok]=intersect(la_wmo_boxes(:,1),a.wmo_boxes);
    la_wmo_boxes(:,i+1)=0;
    if isempty(a.exclude.(a.data_types{i})) || a.data_types{i}(1)~=-1
        a.ok=setdiff(a.ok,a.exclude.(a.data_types{i}));
        la_wmo_boxes(a.ok,i+1)=1;
    end
end
save(fullfile(config.CONFIG_DIRECTORY,config.CONFIG_WMO_BOXES),'la_wmo_boxes');
clear a