config=load_configuration('config_ow.txt');
load(fullfile(config.CONFIG_DIRECTORY,config.CONFIG_WMO_BOXES),'la_wmo_boxes');
data_types={'ctd','bottle','argo'};
for i=1:3
    floats=dir(fullfile(config.HISTORICAL_DIRECTORY,['historical_' data_types{i}]));
    