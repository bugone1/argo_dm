
function [gridindex,posindex]=findindices(regions,pos1,pos2,overlap)
%
% regions  1*4 matrix of grid locations (lat,long,lat,long)
% pos1     m1*3 matrix of gridlocations (lat,long,depth)
% pos2     m2*3 matrix of data locations (lat,long,depth)
% overlap  1*1  scalar of overlap in degrees
%
% The definition of regions is such that the first coordinate pair are 
% the top-left-hand corner, and the second coordinate pair is the 
% bottom-right-hand corner.
%
% gridindex  1*n1 vector of grid locations in the defined region
% posindex   1*n2 vector of position indices in the defined region 
%                 with overlap
%
% Modification: To take care of wraparounds in regions caused by
% longitudes greater 360 and less than 0.  The data always have 
% longitudes between 0 and 360. Regions always have longitudes
% in the 0-360 range.
%
% N. Bindoff
%
gridindex=find(pos1(:,1)<=regions(1)...
               & pos1(:,1)> regions(3)...
               & pos1(:,2)>= regions(2)...
               & pos1(:,2)< regions(4));
tmp=regions+overlap*[1,-1,-1,1];
%
posindex=find(pos2(:,1)<=tmp(1)...
               & pos2(:,1)> tmp(3)...
               & pos2(:,2)>= tmp(2)...
               & pos2(:,2)< tmp(4));
return

