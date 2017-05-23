function update_historical_mapping( pn_float_dir, pn_float_name, po_system_configuration )


% load float source data ----------------------------------------

lo_float_source_data = load( strcat( po_system_configuration.FLOAT_SOURCE_DIRECTORY, pn_float_dir, pn_float_name, po_system_configuration.FLOAT_SOURCE_POSTFIX ));

[ ln_float_level_count, ln_float_profile_count ] = size( lo_float_source_data.SAL ) ;
PROFILE_NO = lo_float_source_data.PROFILE_NO ;


% load CFC data, standard theta levels and other constants -------

lo_cfc_data = load( strcat( po_system_configuration.CONFIG_DIRECTORY, po_system_configuration.CONFIG_CFC_DATA ) ) ;
load( strcat( po_system_configuration.CONFIG_DIRECTORY, po_system_configuration.CONFIG_STANDARD_LEVELS ), 'la_standard_levels' ) ;
load( strcat( po_system_configuration.CONFIG_DIRECTORY, po_system_configuration.CONFIG_WMO_BOXES ), 'la_wmo_boxes' ) ;
ln_max_casts = str2double( po_system_configuration.CONFIG_MAX_CASTS ) ;


% only use the first NO_USED_STANDARD_LEVELS (30C to 0C) -------------------------

ln_number_used_levels = str2double( po_system_configuration.NO_USED_STANDARD_LEVELS ) ;


% load precalculated mapped data --------

ls_float_mapped_filename = strcat( po_system_configuration.FLOAT_MAPPED_DIRECTORY, pn_float_dir, po_system_configuration.FLOAT_MAPPED_PREFIX, pn_float_name, po_system_configuration.FLOAT_MAPPED_POSTFIX ) ;

lh_file = fopen( ls_float_mapped_filename, 'r' ) ;
fclose('all') ;

if( lh_file > 0 )
   load( ls_float_mapped_filename ) ;
   ln_profile_index = size( la_mapped_sal, 2 ) ;
else
   ln_profile_index = 0 ;
   la_INTERP_SAL   = NaN.*ones( ln_number_used_levels, ln_float_profile_count ) ;
   la_INTERP_PRES  = NaN.*ones( ln_number_used_levels, ln_float_profile_count ) ;
   la_mapped_sal   = NaN.*ones( ln_number_used_levels, ln_float_profile_count ) ;
   la_mapsalerrors = NaN.*ones( ln_number_used_levels, ln_float_profile_count ) ;
   la_noise_sal    = NaN.*ones( ln_number_used_levels, ln_float_profile_count ) ;
   la_signal_sal   = NaN.*ones( ln_number_used_levels, ln_float_profile_count ) ;
   long_scale_large= NaN.*ones( 1, ln_float_profile_count ) ;
   lat_scale_large = NaN.*ones( 1, ln_float_profile_count ) ;
   long_scale_small= NaN.*ones( 1, ln_float_profile_count ) ;
   lat_scale_small = NaN.*ones( 1, ln_float_profile_count ) ;
   la_profile_no   = NaN.*ones( 1, ln_float_profile_count ) ;
   selected_hist   = [] ;
end


% compare profile numbers in float source matrix and mapped data matrix ------

missing_profile_index = [] ;

for i = 1 : length( PROFILE_NO )
  a = find( la_profile_no==PROFILE_NO(i) ) ;
  if( isempty(a)==1 )
    missing_profile_index = [ missing_profile_index, i ] ;
  end
end


% update mapped data matrix by missing_profile_index --------------------

for i = 1 : length( missing_profile_index )

   j = missing_profile_index( i ) ;
   ln_profile_index = ln_profile_index + 1 ;

   % append profile numbers

   la_profile_no( ln_profile_index ) = PROFILE_NO( j ) ;

   % reload longitudinal & latitudinal scales for mapping

   longitude_scale_large = str2num( po_system_configuration.MAPSCALE_LONGITUDE_LARGE );
   latitude_scale_large  = str2num( po_system_configuration.MAPSCALE_LATITUDE_LARGE ) ;
   longitude_scale_small = str2num( po_system_configuration.MAPSCALE_LONGITUDE_SMALL );
   latitude_scale_small  = str2num( po_system_configuration.MAPSCALE_LATITUDE_SMALL ) ;

   % update interpolated float data

   [ la_INTERP_SAL(:,ln_profile_index), la_INTERP_PRES(:,ln_profile_index) ] = interpolate_float_values( lo_float_source_data, la_standard_levels, j, ln_number_used_levels ) ;

   % initialize output variables

   la_mapped_sal  ( :, ln_profile_index ) = NaN.*ones( ln_number_used_levels, 1 ) ;
   la_mapsalerrors( :, ln_profile_index ) = NaN.*ones( ln_number_used_levels, 1 ) ;
   la_noise_sal   ( :, ln_profile_index ) = NaN.*ones( ln_number_used_levels, 1 ) ;
   la_signal_sal  ( :, ln_profile_index ) = NaN.*ones( ln_number_used_levels, 1 ) ;
   long_scale_large( ln_profile_index ) = NaN;
   lat_scale_large ( ln_profile_index ) = NaN;
   long_scale_small( ln_profile_index ) = NaN;
   lat_scale_small ( ln_profile_index ) = NaN;

   % get historical data

   LONG = lo_float_source_data.LONG( j ) ;
   LAT  = lo_float_source_data.LAT ( j ) ;
   DATES= lo_float_source_data.DATES(j ) ;

   if(isnan(LONG)==0&isnan(LAT)==0)

   [ la_wmo_numbers ] = find_25boxes( LONG, LAT, la_wmo_boxes ) ;
   [ la_grid_sal, la_grid_pres, la_grid_lat, la_grid_long, la_grid_dates ] = get_region( la_wmo_numbers, po_system_configuration ) ;
   la_corners = [ max(la_grid_lat)+5, min(la_grid_long)-5, min(la_grid_lat)-5, max(la_grid_long)+5 ] ;

   if( la_grid_lat~=999 ) % if no historical data is assigned to the float profile

      % get cfc apparent age

      ln_x_coord = round( round( LONG) / 10 ) * 10 ;
      ln_y_coord = round( round( LAT ) / 10 ) * 10 ;
      la_age = lo_cfc_data.grid_cfc( 1:ln_number_used_levels, find( lo_cfc_data.posgrid(:,1)==ln_y_coord & lo_cfc_data.posgrid(:,2)==ln_x_coord ));
      if(isempty(la_age)==1)la_age=NaN.*ones(ln_number_used_levels,1);end % if no cfc data, set age to NaNs

      % if needed, deform the longitudinal & latitudinal mapping scales, or rotate data

      [longitude_scale_large,latitude_scale_large,rotateflag] = deform_scale( LONG, LAT, longitude_scale_large, latitude_scale_large, po_system_configuration);
      [longitude_scale_small,latitude_scale_small,rotateflag] = deform_scale( LONG, LAT, longitude_scale_small, latitude_scale_small, po_system_configuration);

      [rotation] = rotate_coord( LONG, LAT, po_system_configuration ) ;

      if(isempty(find(la_grid_long>360))==0)
        if(LONG>=0&LONG<=20)
          LONG=LONG+360; % make LONG compatiable with la_grid_long at the 0-360 mark before rotation
        end
      end

      if( rotateflag==1 )
        rot_hist  = inv( rotation ) * [ la_grid_long'; la_grid_lat' ] ; % lat & long have to be row matrices
        rot_float = inv( rotation ) * [ LONG; LAT ] ;
        la_grid_long = rot_hist( 1,: )' ;
        la_grid_lat  = rot_hist( 2,: )' ;
        LONG = rot_float( 1,: ) ;
        LAT  = rot_float( 2,: ) ;
        la_corners = [ max(la_grid_lat)+5, min(la_grid_long)-5, min(la_grid_lat)-5, max(la_grid_long)+5 ] ;
      end

      % find ln_max_casts historical points that are most strongly correlated
      % with the float profile, then map, one standard theta level at a time,
      % only map the la_standard_levels that are within the float data range

      la_mappable_levels = find( isnan( lo_float_source_data.PTMP(:,j) ) == 0 ) ;

      for ln_level = 1:ln_number_used_levels

	if( la_standard_levels(ln_level)<=max(lo_float_source_data.PTMP(la_mappable_levels,j)) & la_standard_levels(ln_level)>=(lo_float_source_data.PTMP(la_mappable_levels(length(la_mappable_levels)),j) ) )

            % for each ptlevels, only use the grid_sal and grid_pres that are not NaNs;
            % (grid_sal and grid_pres have the same NaNs)

            ln_max_hist_casts = find( isnan(la_grid_sal(ln_level,:))==0 ) ;

	    la_hist_sal   = la_grid_sal  ( ln_level, ln_max_hist_casts ) ;
	    la_hist_pres  = la_grid_pres ( ln_level, ln_max_hist_casts ) ;
            la_hist_long  = la_grid_long ( ln_max_hist_casts ) ;
            la_hist_lat   = la_grid_lat  ( ln_max_hist_casts ) ;
	    la_hist_dates = la_grid_dates( ln_max_hist_casts ) ;

	    % pick out points within +/- 250 dbar of interpolated float pressure at that ptlevel

            compare_pres = la_hist_pres - la_INTERP_PRES(ln_level,ln_profile_index);
            ii=find( abs(compare_pres) < 250);
            la_hist_sal   = la_hist_sal  (ii) ;
            la_hist_pres  = la_hist_pres (ii) ;
            la_hist_long  = la_hist_long (ii) ;
            la_hist_lat   = la_hist_lat  (ii) ;
            la_hist_dates = la_hist_dates(ii) ;

            if ~isempty(ii)
                debu=2;
            end
            
            % pick out points within the ellipse

             ellipse = sqrt((la_hist_long-LONG).^2./(longitude_scale_large*3).^2 + (la_hist_lat-LAT).^2./(latitude_scale_large*3).^2) ;
             ii = find( ellipse<1 ) ;
             la_hist_sal   = la_hist_sal  (ii) ;
             la_hist_pres  = la_hist_pres (ii) ;
             la_hist_long  = la_hist_long (ii) ;
             la_hist_lat   = la_hist_lat  (ii) ;
             la_hist_dates = la_hist_dates(ii) ;

            if( length(ii) > ln_max_casts )

           % pick ln_max_casts/3 random points

             index_random = round(rand(1,ceil(ln_max_casts/3)).*length(la_hist_long)) ;
             kk=find(index_random==0);
             index_random(kk)=ones(1,length(kk));

             index_junk = [1:length(la_hist_long)];
             ii=[];
             for h=1:length(la_hist_long)
                a=find(index_random==index_junk(h));
                if(isempty(a)==0)
                  ii=[ii,h];
                end
             end
             index_junk(ii)=[];
             index_remain=index_junk;

            % sort remaining points by large spatial correlations

             remain_hist_sal  = la_hist_sal ( index_remain) ;
             remain_hist_pres = la_hist_pres( index_remain) ;
             remain_hist_lat  = la_hist_lat ( index_remain) ;
             remain_hist_long = la_hist_long( index_remain) ;
             remain_hist_dates= la_hist_dates(index_remain) ;

             correlation_large = (remain_hist_long-LONG).^2./longitude_scale_large.^2 + (remain_hist_lat-LAT).^2./latitude_scale_large.^2 ;
             [ sorted_correlation_large, index_large ] = sort( correlation_large ) ;

             remain_hist_sal   = remain_hist_sal  ( index_large ) ;
	     remain_hist_pres  = remain_hist_pres ( index_large ) ;
	     remain_hist_lat   = remain_hist_lat  ( index_large ) ;
	     remain_hist_long  = remain_hist_long ( index_large ) ;
	     remain_hist_dates = remain_hist_dates( index_large ) ;

            % sort remaining points by short spatial and temporal correlations

             zsal   = remain_hist_sal  ( ceil(ln_max_casts/3)+1 : length(remain_hist_long) ) ;
             zpres  = remain_hist_pres ( ceil(ln_max_casts/3)+1 : length(remain_hist_long) ) ;
             zlong  = remain_hist_long ( ceil(ln_max_casts/3)+1 : length(remain_hist_long) ) ;
             zlat   = remain_hist_lat  ( ceil(ln_max_casts/3)+1 : length(remain_hist_long) ) ;
             zdates = remain_hist_dates( ceil(ln_max_casts/3)+1 : length(remain_hist_long) ) ;

             if( isnan(la_age(ln_level))==0 )
               correlation_small = (zlong-LONG).^2./longitude_scale_small.^2 + (zlat-LAT).^2./latitude_scale_small.^2 + (zdates-DATES).^2./la_age(ln_level).^2 ;
             else
               correlation_small = (zlong-LONG).^2./longitude_scale_small.^2 + (zlat-LAT).^2./latitude_scale_small.^2 ;
             end

  	     [ sorted_correlation_small, index_small ] = sort( correlation_small ) ;

             zsal   = zsal  ( index_small ) ;
             zpres  = zpres ( index_small ) ;
             zlong  = zlong ( index_small ) ;
             zlat   = zlat  ( index_small ) ;
             zdates = zdates( index_small ) ;

           % piece the 3 steps together

	     leftover=ln_max_casts-2*ceil(ln_max_casts/3);
             la_hist_sal=[la_hist_sal(index_random),remain_hist_sal(1:ceil(ln_max_casts/3)),zsal(1:leftover)];
             la_hist_pres=[la_hist_pres(index_random),remain_hist_pres(1:ceil(ln_max_casts/3)),zpres(1:leftover)];
             la_hist_lat=[la_hist_lat(index_random);remain_hist_lat(1:ceil(ln_max_casts/3));zlat(1:leftover)];
             la_hist_long=[la_hist_long(index_random);remain_hist_long(1:ceil(ln_max_casts/3));zlong(1:leftover)];
             la_hist_dates=[la_hist_dates(index_random);remain_hist_dates(1:ceil(ln_max_casts/3));zdates(1:leftover)];

            end

            % map historical data to float profiles -------------------------

	    if( length(la_hist_sal)<=1 ) % if there is no or only one data point
   		la_mapped_sal  ( ln_level, ln_profile_index ) = NaN ;
		la_mapsalerrors( ln_level, ln_profile_index ) = NaN ;
		la_noise_sal   ( ln_level, ln_profile_index ) = NaN ;
		la_signal_sal  ( ln_level, ln_profile_index ) = NaN ;
            else

		[ ln_rows, ln_cols ] = size( la_hist_sal ) ;
		ln_rank = 1 ;
                la_regions = [ la_corners(1), la_corners(2), la_corners(3), la_corners(4), 1, 0 ] ;

		% use large length scales to map original data - use covarxy.m in map_data_grid.m

		noise_sal  = noise( la_hist_sal, la_hist_lat, la_hist_long ) ;
		signal_sal = signal( la_hist_sal ) ;

		la_salgrid1 = NaN ;
		la_salgriderror1 = NaN ;
		la_saldata1 = NaN .* ones( ln_rows, ln_cols ) ;
		la_saldataerror1 = NaN .* ones( ln_rows, ln_cols ) ;

		[a,b,c,d]...
			= mapweighted_data_grid( la_hist_sal, [ LAT, LONG, lo_float_source_data.DATES(j) ], [ la_hist_lat, la_hist_long, la_hist_dates ], la_regions, ln_rank, longitude_scale_large, latitude_scale_large, la_age( ln_level ), signal_sal, noise_sal ) ;
		la_salgrid1 = a' ;
		la_salgriderror1 = b' ;
		la_saldata1 = c' ;
		la_saldataerror1 = d' ;

                % use short length scales and temporal scales to map residuals - use covarxyt.m in map_data_grid_t.m

		la_residualsal1 = la_hist_sal - la_saldata1 ;
		la_signalresidualsal = signal( la_residualsal1 ) ;

		la_salgrid2 = NaN ;
		la_salgriderror2 = NaN ;
		la_saldata2 = NaN .* ones( ln_rows, ln_cols ) ;
		la_saldataerror2 = NaN .* ones( ln_rows, ln_cols ) ;

		[a,b,c,d]...
			= mapweighted_data_grid_t( la_residualsal1, [ LAT, LONG, lo_float_source_data.DATES(j) ], [ la_hist_lat, la_hist_long, la_hist_dates], la_regions, ln_rank, longitude_scale_small, latitude_scale_small, la_age( ln_level ), la_signalresidualsal, noise_sal ) ;
		la_salgrid2 = a' ;
		la_salgriderror2 = b' ;
		la_saldata2 = c' ;
		la_saldataerror2 = d' ;

		la_mapped_sal(  ln_level, ln_profile_index ) = la_salgrid1 + la_salgrid2 ;
		la_mapsalerrors(ln_level, ln_profile_index ) = la_salgriderror2 ;
                la_noise_sal(   ln_level, ln_profile_index ) = noise_sal ;
                la_signal_sal(  ln_level, ln_profile_index ) = signal_sal ;
                long_scale_large( ln_profile_index ) = longitude_scale_large ;
                lat_scale_large ( ln_profile_index ) = latitude_scale_large ;
                long_scale_small( ln_profile_index ) = longitude_scale_small ;
                lat_scale_small ( ln_profile_index ) = latitude_scale_small ;

                if(rotateflag==1) %rotate back to original coordinate for plotting
                  original = rotation*[ la_hist_long'; la_hist_lat'] ;
                  la_hist_long= original(1,:)' ;
                  la_hist_lat = original(2,:)' ;
                end
                % only save selected historical points to conserve computer space
                if(isempty(selected_hist)==1)selected_hist=[la_hist_long(1),la_hist_lat(1),la_profile_no(ln_profile_index)];end
                for k = 1 : length(la_hist_long)
                   [m,n] = size(selected_hist);
                   b = [ la_hist_long(k), la_hist_lat(k) ];
                   c = selected_hist(:,1:2) - ones(m,1)*b;
                   d = find( abs(c(:,1))<1/60&abs(c(:,2))<1/60 ); %within 1 min, do not save
                   if( isempty(d)==1 )
                     selected_hist = [ selected_hist; [ la_hist_long(k), la_hist_lat(k), la_profile_no(ln_profile_index) ] ];
                   end
                end

            end %if( length(la_hist_sal)<=1 )
	end %if profile levels is within ptlevels, map
      end %for ln_level = 1:ln_number_used_levels
   end %if( la_grid_lat==999 )
 end %if(isnan(LONG)==0&isnan(LAT)==0)
end %for i = 1 : length( missing_profile_index )


% quality control - subst all mapped_sal < 30 and > 38 with NaNs ----------

ii = find( la_mapped_sal<30|la_mapped_sal>38 ) ;
la_mapped_sal(ii) = NaN.*ones( 1,length(ii) ) ;


% sort the mapped data matrix by profile numbers ------------

[y,ii] = sort( la_profile_no ) ;

la_INTERP_SAL   = la_INTERP_SAL  (:,ii) ;
la_INTERP_PRES  = la_INTERP_PRES (:,ii) ;
la_mapped_sal   = la_mapped_sal  (:,ii) ;
la_mapsalerrors = la_mapsalerrors(:,ii) ;
la_noise_sal    = la_noise_sal   (:,ii) ;
la_signal_sal   = la_signal_sal  (:,ii) ;
long_scale_large= long_scale_large(ii) ;
lat_scale_large = lat_scale_large (ii) ;
long_scale_small= long_scale_small(ii) ;
lat_scale_small = lat_scale_small (ii) ;
la_profile_no   = la_profile_no(ii) ;

if(isempty(selected_hist)==0)
  [y,ii] = sort( selected_hist(:,3) ) ;
  selected_hist = selected_hist(ii,:) ;
end


% save the relevant data ----------------

la_standard_levels = la_standard_levels( 1:ln_number_used_levels ) ;

%save( ls_float_mapped_filename, 'la_mapped_sal', 'la_mapsalerrors', 'la_standard_levels', 'la_INTERP_SAL', 'la_INTERP_PRES', 'long_scale_large', 'lat_scale_large', 'long_scale_small', 'lat_scale_small', 'la_noise_sal', 'la_signal_sal', 'la_profile_no', 'selected_hist' ) ;

