
% function [ rotation ] = rotate_coord( LONG, LAT, po_config_data ) ;
%
% This function finds the 1000 m isobath closest to [ LONG, LAT ],
% picks up the phase angle of the gradient of the 1000 m isobath,
% and forms the rotational matrix with the phase angle + 90 degrees.
%
% A. Wong, 29 May 2001.
%

function [ rotation ] = rotate_coord( LONG, LAT, po_config_data ) ;

% load isobath_1000.mat
% (alpha_1000 is already in radians)

load( strcat( po_config_data.CONFIG_DIRECTORY, po_config_data.CONFIG_1000M ), 'long_1000', 'lat_1000', 'alpha_1000' ) ;

% find the 1000 m isobath closest to the float profile (LONG,LAT),
% and pick out the phase angle (a) of the gradient of the isobath
% (cannot use interp2 because long_1000 & lat_1000 are not monotonic)

for i=1:length(alpha_1000)
 distance(i)=sw_dist([LAT,lat_1000(i)],[LONG,long_1000(i)],'km');
end
j=find(distance==min(distance));
if(length(j)>1)j=j(1);end; % if more than 2 points, pick the first one
a=alpha_1000(j);

% convert 90 degrees to radians

rightangle = 90*pi/180;

% form matrix for rotation

rotation = [ cos(a+rightangle), -sin(a+rightangle); sin(a+rightangle), cos(a+rightangle) ] ;

