function [ pa_interp_sal, pa_interp_pres ] = interpolate_float_values_ron( lo_float_data, pa_levels, pa_profile_index, pn_max_number_of_levels );
%
% interpolate float data to the standard theta levels;
% adopted from ptlevels_akima.m
%Akima replaced by Reiniger and Ross, DSR 15, 185-193, 1968 on Dec. 15,
%2003   Ron
%Reiniger divide-by-zero errors fixed: Feb. 9, 2004
%
% function [ pa_interp_sal, pa_interp_pres ]
% = interpolate_float_values( lo_float_data, pa_levels, pa_profile_index, pn_max_number_of_levels );
%
% A. Wong, 2 Dec 2003.
%
% initialize

pa_interp_sal  = NaN.*ones( pn_max_number_of_levels, 1 ) ;
pa_interp_pres = NaN.*ones( pn_max_number_of_levels, 1 ) ;

la_compare_sal  = NaN.*ones( pn_max_number_of_levels, 1 ) ;
la_compare_pres = NaN.*ones( pn_max_number_of_levels, 1 ) ;

la_SAL  = lo_float_data.SAL(  :, pa_profile_index );
la_PTMP = lo_float_data.PTMP( :, pa_profile_index );
la_PRES = lo_float_data.PRES( :, pa_profile_index );

ii=find(isnan(la_SAL)==0);
la_SAL=la_SAL(ii);
la_PTMP=la_PTMP(ii);
la_PRES=la_PRES(ii);

ii=find(isnan(la_PTMP)==0);
la_SAL=la_SAL(ii);
la_PTMP=la_PTMP(ii);
la_PRES=la_PRES(ii);

ii=find(isnan(la_PRES)==0);
la_SAL=la_SAL(ii);
la_PTMP=la_PTMP(ii);
la_PRES=la_PRES(ii);

la_SAL = [ la_SAL; NaN];
la_PTMP =[ la_PTMP;NaN];
la_PRES =[ la_PRES;NaN];

ln_rows = length(la_SAL);

if(ln_rows==1)break
else
    % if in the subarctic North Pacific and profile does not go deeper than 400 dbar, ignore
    % if the float is shallower than 400 dbar, it is probably in a coastal
    % region with poor climatology. We do not want to use it for calibration no
    % matter its lat/long. So remove the position condition and keep the depth
    % conditon. Uwe Send uses f/H contours to select climatology which might
    % help in coastal areas.

    %la_LAT = lo_float_data.LAT (pa_profile_index); ron
    %la_LONG= lo_float_data.LONG(pa_profile_index); ron
    ii=find(isnan(la_PRES)==0);

    if(max(la_PRES(ii))<400); % if(la_LONG>140&la_LONG<240&la_LAT>45&max(la_PRES(ii))<400) ron
        break
    else


        % find out the deepest entry in the column that is not a NaN

        ln_last_row = ln_rows;
        while( isnan( la_PTMP( ln_last_row ) ) == 1 )
            ln_last_row = ln_last_row - 1 ;
            if( ln_last_row <= 1 )
                break ;
            end %if( ln_last_row <= 1 )
        end %while( isnan( la_PTMP( ln_last_row ) ) == 1 )


        % find the bottom of the temp inversion layer above 1000 dbar; ron

        ln_middle = ln_last_row ;
        if( ln_last_row ~= 1 )
            while( la_PTMP( ln_middle - 1 ) >= la_PTMP( ln_middle ) | la_PRES(ln_middle) > 999 ) % ron
                ln_middle = ln_middle - 1 ;
                if( ln_middle <= 2 )
                    break;
                end
            end
        end %if( ln_last_row ~= 1 )


        % gets rid of everything above the temp inversion layer. Small temperature
        % inversions are allowed deeper than 1000 dbar.

        ln_ptmp = [ la_PTMP( ln_middle:ln_last_row ) ] ;
        ln_pres = [ la_PRES( ln_middle:ln_last_row ) ] ;
        ln_sal  = [ la_SAL(  ln_middle:ln_last_row ) ] ;


        % akima has trouble with less than 3 numbers. Reiniger can use 2 but leave
        % this in.

        if( length( find( isnan( ln_ptmp ) == 0 ) ) > 3 )
            if( length( find( isnan( ln_sal ) == 0 ) ) > 3 )
                pa_interp_sal = reiniger_extrap( ln_sal, ln_ptmp, pa_levels(1:pn_max_number_of_levels),.01 ) ;
                la_compare_sal = interpolate1( ln_sal,  ln_ptmp, pa_levels(1:pn_max_number_of_levels) ) ;
            end
            if( length( find( isnan( ln_pres ) == 0 ) ) > 3 )
                pa_interp_pres = reiniger_extrap( ln_pres, ln_ptmp, pa_levels(1:pn_max_number_of_levels),15 ) ;
                la_compare_pres = interpolate1( ln_pres, ln_ptmp, pa_levels(1:pn_max_number_of_levels) ) ;
            end
        end %if( length( find( isnan( ln_ptmp ) == 0 ) ) > 3 )


        % where interpolate1 gives NaN, akima/reineger should also give NaN; ron

        ln_index = find( isnan( la_compare_sal ) == 1 ) ;
        pa_interp_sal(  ln_index ) = NaN.*ones( length( ln_index ), 1 ) ;
        pa_interp_pres( ln_index ) = NaN.*ones( length( ln_index ), 1 ) ;
        ln_index = find( isnan( la_compare_pres ) == 1 ) ;
        pa_interp_pres( ln_index ) = NaN.*ones( length( ln_index ), 1 ) ;
        pa_interp_sal(  ln_index ) = NaN.*ones( length( ln_index ), 1 ) ;

        % remove akima/reineger estimates if they stray too much from the linear estimates,
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
        end %for r=1:pn_max_number_of_levels

        % screen measurements that are more than 200 dbar apart

        for i=1:length(ln_ptmp)

            index=[1:length(ln_ptmp)];
            index(i)=[];
            ptmp_compare=ln_ptmp(index);

            if( isempty( find(ln_ptmp(i)==ptmp_compare) )==0 )
                ln_ptmp(i)=NaN; %ln_ptmp has to be monotonic, substitute equal values with NaN
            end

        end %for i=1:length(ln_ptmp)

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
        end %for i=1:pn_max_number_of_levels

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
        end %if( pn_max_number_of_levels < length( pa_interp_sal ) )
        % ---------
    end % if(max(la_PRES(ii))<400); % if(la_LONG>140&la_LONG<240&la_LAT>45&max(la_PRES(ii))<400) ron
end %if(ln_rows==1)break

