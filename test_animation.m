clear all;

h_geo_plots = figure;
baseURL = "https://basemap.nationalmap.gov/ArcGIS/rest/services";
usgsURL = baseURL + "/BASEMAP/MapServer/tile/${z}/${y}/${x}";
basemaps = "USGSImageryTopo";
displayNames ="USGS Topographic Imagery";
maxZoomLevel = 16;
attribution = '';
name = lower(basemaps);
url = replace(usgsURL,"BASEMAP",basemaps);
addCustomBasemap(name,url,'Attribution',attribution, ...
         'DisplayName',displayNames,'MaxZoomLevel',maxZoomLevel)
     
g_axes=geoaxes(h_geo_plots);
% if(title_string(1)~=99999)
 geoplot(g_axes,56,-45,'or','LineWidth',3);% latitude longitude
geobasemap(g_axes,basemaps)
% title(g_axes,displayNames)
% else
% geobasemap(g_axes,basemaps)
% title(g_axes,displayNames)  
% end