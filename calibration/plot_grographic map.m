h_geo_plots=figure('position',[30 30 800 800]);

baseURL = "https://basemap.nationalmap.gov/ArcGIS/rest/services";
usgsURL = baseURL + "/BASEMAP/MapServer/tile/${z}/${y}/${x}";
basemaps = "USGSImageryTopo";
displayNames ="Canadian Drifting Buoys";
maxZoomLevel = 16;
attribution = 'Credit: U.S. Geological Survey';
name = lower(basemaps);
url = replace(usgsURL,"BASEMAP",basemaps);
addCustomBasemap(name,url,'Attribution',attribution, ...
         'DisplayName',displayNames,'MaxZoomLevel',maxZoomLevel)
     
g_axes=geoaxes(h_geo_plots);
geoplot(g_axes,lat1,lon1,'go','LineWidth',0.5);

 geolimits([43 48],...
     [-54 -47])
geobasemap(g_axes,basemaps)


