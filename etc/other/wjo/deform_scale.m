
% function [ deform_long_scale, deform_lat_scale, rotateflag ] = deform_scale( LONG, LAT, ln_longitude_scale, ln_latitude_scale, po_config_data );
%
% This function checks how close a float profile (LONG, LAT) is to the 1000 m isobath,
% and decides whether it needs to deform the ellipse (deform_long_scale, deform_lat_scale),
% or rotate the data set (rotateflag = 1).
%
% A. Wong, 29 May 2001
%

function [ deform_long_scale, deform_lat_scale, rotateflag ] = deform_scale( LONG, LAT, ln_longitude_scale, ln_latitude_scale, po_config_data );


% calculate the radii (in local distance) of the ellipse defined by the mapping scales
% with the float profile as the centre

a=sw_dist([LAT,LAT],[LONG,LONG+ln_longitude_scale],'km'); % semimajor axis
b=sw_dist([LAT,LAT+ln_latitude_scale],[LONG,LONG],'km'); % semiminor axis

% check whether the ellipse encloses any 1000 m isobath

load( strcat( po_config_data.CONFIG_DIRECTORY, po_config_data.CONFIG_1000M ), 'long_1000', 'lat_1000' ) ;

ii=find(long_1000<LONG+ln_longitude_scale&long_1000>LONG-ln_longitude_scale);

if(isempty(ii)==0)
 jj=find(lat_1000(ii)<LAT+ln_latitude_scale&lat_1000(ii)>LAT-ln_latitude_scale);
else
 jj=[];
end

closest_long_1000=long_1000(ii(jj)); % coordinates of the 1000 m isobath
closest_lat_1000=lat_1000(ii(jj)); % within the ellipse

for k=1:length(jj) % calculate local distance from float profile to the 1000 m isobath
  distance(k) = sw_dist([LAT,closest_lat_1000(k)],[LONG,closest_long_1000(k)],'km');
end

% if there's no 1000 m isobath within the ellipse, do nothing,
% else, deform the ellipse to preserve the area defined by the
% longitudinal and latitudinal scales, until the ellipse
% degenerates to a circle

if(isempty(jj)==1) % if there's no 1000 m isobath within the ellipse
 deform_long_scale = ln_longitude_scale;
 deform_lat_scale = ln_latitude_scale;
 rotateflag = 0;
end

if(isempty(jj)==0&min(distance)<sqrt(a*b))% if the profile is so close to the coast that
  deform_long_scale = ln_longitude_scale; % it won't fit a circle of radius sqrt(a*b)
  deform_lat_scale = ln_latitude_scale;   % around it, then rotate axes
  rotateflag = 1;
end

if(isempty(jj)==0&min(distance)>=sqrt(a*b)) % else, deform the ellipse
  diff_lat=abs(LAT-closest_lat_1000);
  i=find(diff_lat==min(diff_lat)); % indices of the latitude of the closest 1000 m isobath
  diff_long=abs(LONG-closest_long_1000(i));
  j=find(diff_long==min(diff_long)); % index of the longitude of the closest 1000 m isobath
  deform_long=closest_long_1000(i(j(1))); % coordinate of the x-intercept
  deform_long_scale=abs(deform_long-LONG); % in degree, not in local distance
  deform_lat_scale=ln_longitude_scale*ln_latitude_scale/deform_long_scale;
  rotateflag = 0;
end

