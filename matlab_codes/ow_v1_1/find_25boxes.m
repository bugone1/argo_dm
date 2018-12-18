function pa_wmo_numbers=find_25boxes(pn_float_long, pn_float_lat, pa_wmo_boxes)
% function pa_wmo_numbers=find_25boxes( pn_float_long, pn_float_lat,pa_wmo_boxes)
%
% This function finds 5x5=25 WMO boxes with the float profile in the centre.
% The WMO box numbers, between 90N and 90S, are stored in wmo_boxes.mat.
% The 1st column has the box numbers, the 2nd column denotes CTD data,
% the 3rd column denotes bottle data, the 4th column denotes Argo data.
% No data is denoted by 0. Otherwise 1.
%
% A. Wong, 16 August 2004
%
pa_wmo_numbers = [ NaN.*ones( 25, 1 ), zeros( 25, 3 )];
%[la_lookup_x,la_lookup_y,vector_x,vector_y]=deal([]);
la_x=5:10:355; % 36 elements
la_y=85:-10:-85; % 18 elements
% for i=1:18
%   la_lookup_x = [ la_lookup_x; la_x ] ;
% end
% for i=1:36
%   la_lookup_y = [ la_lookup_y, la_y ];
%   vector_y = [ vector_y; la_y ];
%   vector_x = [ vector_x; la_x(i).*ones(18,1) ];
% end
la_lookup_x=repmat(la_x,[18 1]);
la_lookup_y=repmat(la_y',[1 36]);
%vector_x=a.la_lookup_x(:);
%vector_y=a.la_lookup_y(:);
la_lookup_no=reshape(1:648, 18, 36 ) ;
ln_x=pn_float_long+[.01 10.01 -9.99 20.01 -19.99];
ln_y=pn_float_lat+[.01 10.01 -9.99 20.01 -19.99];
% interp2 will treat 360 as out of range, but will interpolate 0
for i=[3 5]
    if ln_x(i)<0 
        ln_x(i)=360+ln_x(i);
    end
end
for i=[1 2 4]
    if ln_x(i)>=360 
        ln_x(i)=ln_x(i)-360;
    end
end
ln_i=NaN*ones(25,1);
i=0;
if ~isnan(pn_float_lat) && ~isnan(pn_float_long)
    for iy=1:5
        for ix=1:5
            i=i+1;
            ln_i(i)=interp2( la_lookup_x, la_lookup_y, la_lookup_no, ln_x(ix), ln_y(iy), 'nearest' ) ;
        end
    end
end
ok=~isnan(ln_i);
pa_wmo_numbers(ok,:)=pa_wmo_boxes(ln_i(ok),:);