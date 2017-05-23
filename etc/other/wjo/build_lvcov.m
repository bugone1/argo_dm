
% function lvcovariance = build_lvcov( x, y, Lx, Ly, ptlevels );
%
% This function builds the covariance (vertical and lateral) matrix (a square matrix)
% that has (2xrunning_mean+1 = no_of_tiles) x (2xrunning_mean+1 = no_of_tiles)
% number of tiles, each tile is of m x m size (where m = length of ptlevels).
%
% The vertical covariance matrix is the building tile. It has 1 at its diagonal,
% then decreases exponentially in the off-diagonals, which represents the vertical
% covariance between water masses.
%
% Each tile is then multiplied by the lateral covariance between profile locations.
%
% A. Wong, 29 May 2001
%

function lvcovariance = build_lvcov( x, y, Lx, Ly, ptlevels );

% set up the theta boundaries for water masses

ptboundaries = [ 30; 24; 18; 12; 8; 4; 2.5; 1; 0 ];
ptscale_down = [ 6; 6; 6; 4; 4; 1.5; 1.5; 1; 1 ];
ptscale_up = [ 6; 6; 6; 6; 4; 4; 1.5; 1.5; 1 ];


% set up the building tile = vertical covariance matrix
%
% upper triangle of the matrix = covariance of each ptlevel with every ptlevel below it,
%  looking down the water column from the diagonal
% lower triangle of the matrix = covariance of each ptlevel with every ptlevel above it,
%  looking up the water column from the diagonal

m=length(ptlevels);
building_tile=ones(m,m);

for i=1:m
  for j=1:m
    if(i<j) % upper triangle, look down the water column for vertical scale
      Ltheta = interp1( ptboundaries, ptscale_down, ptlevels(i), 'linear' );
      building_tile(i,j) = exp( - ( ptlevels(j) - ptlevels(i) ).^2/ Ltheta.^2 );
    elseif(i>j) % lower triangle, look up the water column for vertical scale
      Ltheta = interp1( ptboundaries, ptscale_up, ptlevels(i), 'linear' );
      building_tile(i,j) = exp( - ( ptlevels(j) - ptlevels(i) ).^2/ Ltheta.^2 );
    end
  end
end


% build the whole matrix with the building tile

no_of_tiles=length(x);

vcovariance = repmat( building_tile, no_of_tiles, no_of_tiles );


% calculate the lateral covariance
lat_cov=[];
for i=1:no_of_tiles
  for j=1:no_of_tiles
    lat_cov(i,j) = exp( - ( (x(i) - x(j)).^2/Lx(i).^2 + (y(i) - y(j)).^2/Ly(i).^2 ) );
  end
end


% multiply the tiles by the lateral covariance
lvcovariance=[];
k=length(ptlevels);
for i=1:no_of_tiles
  for j=1:no_of_tiles
    lvcovariance( 1+k*(i-1) : k*i, 1+k*(j-1) : k*j ) = vcovariance( 1+k*(i-1) : k*i, 1+k*(j-1) : k*j ).*lat_cov(i,j);
  end
end