
% function [ pa_wmo_numbers ] = find_25boxes( pn_float_long, pn_float_lat, pa_wmo_boxes);
%
% This function finds 5x5=25 WMO boxes with the float profile in the centre.
% The WMO box numbers, between 90N and 90S, are stored in wmo_boxes.mat.
% The 1st column has the box numbers, the 2nd column denotes CTD data,
% the 3rd column denotes bottle data, the 4th column denotes Argo data.
% No data is denoted by 0. Otherwise 1.
%
% A. Wong, 16 August 2004
% heavily edited by Mathieu Ouellet to make use of cell arrays and reduce code

function [ pa_wmo_numbers ] = find_25boxes_mat( pn_float_long, pn_float_lat, pa_wmo_boxes ) ;
pa_wmo_numbers = [ NaN.*ones( 25, 1 ), zeros( 25, 1 ), zeros( 25, 1 ), zeros( 25, 1 ) ] ;
la_x = [ 5:10:355 ] ; % 36 elements
la_y = [ 85:-10:-85 ] ; % 18 elements
la_lookup_x=repmat(la_x,18,1);
la_lookup_y=repmat(la_y',1,36);
vector_y=repmat(la_y',36,1);
vector_x=repmat(la_x',18,1);
la_lookup_no=reshape( [ 1:648 ], 18, 36 ) ;
offsets=[.01 10.01 -9.99 20.01 -19.99];
for i=1:length(offsets)
    ln_x{i} = pn_float_long + offsets(i);
    ln_y{i} = pn_float_lat +  offsets(i);
end
% interp2 will treat 360 as out of range, but will interpolate 0
for i=[3 5]
    if( ln_x{i}<0 )ln_x{i}=360+ln_x{i};end;
end
for i=[1 2 4]
    if (ln_x{i}>=360) ln_x{i}=ln_x{i}-360;end
end
if ~(isnan(pn_float_lat) | isnan(pn_float_long))
    for j=1:5
        for k=1:5
            ln_i{(j-1)*5+k} = interp2( la_lookup_x, la_lookup_y, la_lookup_no, ln_x{k}, ln_y{j}, 'nearest' ) ;
            [(j-1)*5+k k j]
        end
    end
else
    for i=1:25
        ln_i(i) = 'NaN' ;
    end
end
for i=1:25
    if ~isnan(ln_i{i})
        pa_wmo_numbers(i,:)=pa_wmo_boxes(ln_i{i},:);
    end;
end