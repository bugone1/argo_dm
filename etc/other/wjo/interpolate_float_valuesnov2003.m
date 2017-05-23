
function [ pa_interp_sal, pa_interp_pres ] = interpolate_float_values( lo_float_data, pa_levels, pa_profile_index, pn_max_number_of_levels );

%
% interpolate float data to the standard theta levels;
% adopted from ptlevels_akima.m
%
% function [ pa_interp_sal, pa_interp_pres ]
% = interpolate_float_values( lo_float_data, pa_levels, pa_profile_index, pn_max_number_of_levels );
%
% A. Wong, 16 Oct 2001.
%

% initialize

[ ln_rows, ln_cols ] = size( lo_float_data.SAL ) ;

pa_interp_sal  = NaN.*ones( pn_max_number_of_levels, 1 ) ;
pa_interp_pres = NaN.*ones( pn_max_number_of_levels, 1 ) ;

la_compare_sal  = NaN.*ones( pn_max_number_of_levels, 1 ) ;
la_compare_pres = NaN.*ones( pn_max_number_of_levels, 1 ) ;

la_SAL  = [ lo_float_data.SAL(  :, pa_profile_index ); NaN ] ;
la_PTMP = [ lo_float_data.PTMP( :, pa_profile_index ); NaN ] ;
la_PRES = [ lo_float_data.PRES( :, pa_profile_index ); NaN ] ;

% if in the subarctic North Pacific and profile does not go deeper than 400 dbar, ignore

la_LAT = lo_float_data.LAT (pa_profile_index);
la_LONG= lo_float_data.LONG(pa_profile_index);
ii=find(isnan(la_PRES)==0);
subarctic_NP=la_LONG>140&la_LONG<240&la_LAT>45&max(la_PRES(ii))<400;

if(subarctic_NP==0)

% find out the deepest entry in the column that is not a NaN

ln_last_row = ln_rows;
while( isnan( la_PTMP( ln_last_row ) ) == 1 )
  if( ln_last_row==1 ); break; end;
  ln_last_row = ln_last_row - 1 ;
end

% find the bottom of the temp inversion layer

ln_middle = ln_last_row ;
if( ln_last_row ~= 1 )
   while( la_PTMP( ln_middle - 1 ) >= la_PTMP( ln_middle ) )
      ln_middle = ln_middle - 1 ;
      if( ln_middle <= 2 )
  	break;
      end
   end
end

% find anything above the temp inversion layer that has greater temp, then
% gets rid of any other small non-monotonic temps above the temp inversion layer

good=[];

above = find( la_PTMP( 1:ln_middle ) > la_PTMP( ln_middle ) ) ;

for i=1:length(above)
     check = la_PTMP(above(i)) > la_PTMP(above(i+1:length(above)));
     if(isempty(find(check==0)))
         good=[good,above(i)];
     end
end

ln_ptmp = [ la_PTMP( good ); la_PTMP( ln_middle:ln_last_row ) ] ;
ln_pres = [ la_PRES( good ); la_PRES( ln_middle:ln_last_row ) ] ;
ln_sal  = [ la_SAL(  good ); la_SAL(  ln_middle:ln_last_row ) ] ;

% akima has trouble with less than 3 numbers

if( length( find( isnan( ln_ptmp ) == 0 ) ) > 3 )
   if( length( find( isnan( ln_sal ) == 0 ) ) > 3 )
      pa_interp_sal = akima( ln_ptmp, ln_sal, pa_levels(1:pn_max_number_of_levels) ) ;
      la_compare_sal = interpolate1( ln_sal,  ln_ptmp, pa_levels(1:pn_max_number_of_levels) ) ;
   end
   if( length( find( isnan( ln_pres ) == 0 ) ) > 3 )
      pa_interp_pres = akima( ln_ptmp, ln_pres, pa_levels(1:pn_max_number_of_levels) ) ;
      la_compare_pres = interpolate1( ln_pres, ln_ptmp, pa_levels(1:pn_max_number_of_levels) ) ;
   end
end

% where interpolate1 gives NaN, akima should also give NaN

ln_index = find( isnan( la_compare_sal ) == 1 ) ;
pa_interp_sal(  ln_index ) = NaN.*ones( length( ln_index ), 1 ) ;
pa_interp_pres( ln_index ) = NaN.*ones( length( ln_index ), 1 ) ;
ln_index = find( isnan( la_compare_pres ) == 1 ) ;
pa_interp_pres( ln_index ) = NaN.*ones( length( ln_index ), 1 ) ;
pa_interp_sal(  ln_index ) = NaN.*ones( length( ln_index ), 1 ) ;

% remove akima estimates if they stray too much from the linear estimates,
% 0.1 pss for salinity above 0.3C, 0.01 pss below 0.3C (ARGO salinity
% accuracy target is 0.01 pss), 50 dbar for pressure, or 50% of linearly
% interpolated estimate (for when pressure is less than 50 dbar)

ln_diff_sal  = abs( la_compare_sal  - pa_interp_sal  ) ;
ln_diff_pres = abs( la_compare_pres - pa_interp_pres ) ;
ln_salAccu  = [.1.*ones( 45, 1 ) ; .01.*ones( 9, 1 ) ] ;

for r=1:pn_max_number_of_levels
   if( ln_diff_sal( r ) > ln_salAccu( r ) )
      pa_interp_sal(  r ) = NaN;
      pa_interp_pres( r ) = NaN;
   end
   if( ln_diff_pres( r ) > min( 50, la_compare_pres( r ) / 2 ) )
      pa_interp_pres( r ) = NaN;
      pa_interp_sal(  r ) = NaN;
   end
end

% screen measurements that are more than 200 dbar apart

for i=1:length(ln_ptmp)

   index=[1:length(ln_ptmp)];
   index(i)=[];
   ptmp_compare=ln_ptmp(index);

   if( isempty( find(ln_ptmp(i)==ptmp_compare) )==0 )
      ln_ptmp(i)=NaN; %ln_ptmp has to be monotonic, substitute equal values with NaN
   end

end

ii=find(isnan(ln_ptmp)==0);
ln_ptmp=ln_ptmp(ii);
ln_pres=ln_pres(ii);

for i=1:pn_max_number_of_levels
   if(pa_levels(i)>min(ln_ptmp)&pa_levels(i)<max(ln_ptmp))
     index1=floor(interp1(ln_ptmp,[1:1:length(ln_ptmp)]',pa_levels(i)));
     index2=index1+1;
     diffpres=abs(ln_pres(index1)-ln_pres(index2));
     if(diffpres>200)
       pa_interp_pres(i)=NaN;
       pa_interp_sal(i)=NaN;
     end
   end
end

% gets rid of weird (less than 0) pressure points

ln_index = find( pa_interp_pres < 0 ) ;
pa_interp_pres( ln_index ) = NaN.*ones( 1, length( ln_index ) ) ;
pa_interp_sal( ln_index ) = NaN.*ones( 1, length( ln_index ) ) ;

% Truncate to number of "used" levels.

if( pn_max_number_of_levels < length( pa_interp_sal ) )
   pa_interp_sal  = pa_interp_sal( 1:pn_max_number_of_levels ) ;
   pa_interp_pres = pa_interp_pres( 1:pn_max_number_of_levels ) ;
elseif( pn_max_number_of_levels > length( pa_interp_sal ) )
   pa_interp_sal  = [ pa_interp_sal;  Nan.*ones( pn_max_number_of_levels - length( pa_interp_sal  ) ) ] ;
   pa_interp_pres = [ pa_interp_pres; Nan.*ones( pn_max_number_of_levels - length( pa_interp_pres ) ) ] ;
end

% ---------

end %if(subarctic_NP==0)--------


