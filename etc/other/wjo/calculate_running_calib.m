
function calculate_running_calib( pn_float_dir, pn_float_name, po_system_configuration )

% function calculate_running_calib( pn_float_dir, pn_float_name, po_system_configuration )
%
% A. Wong, 5 May 2004
%

% load data from /float_source/, /float_mapped/ and others --------------

lo_float_source_data = load( strcat( po_system_configuration.FLOAT_SOURCE_DIRECTORY, pn_float_dir, pn_float_name, po_system_configuration.FLOAT_SOURCE_POSTFIX ) ) ;

LAT  = lo_float_source_data.LAT  ;
LONG = lo_float_source_data.LONG ;
PRES = lo_float_source_data.PRES ;
PTMP = lo_float_source_data.PTMP ;
SAL  = lo_float_source_data.SAL  ;
TEMP = lo_float_source_data.TEMP ;
PROFILE_NO = lo_float_source_data.PROFILE_NO ;

lo_float_mapped_data = load( strcat( po_system_configuration.FLOAT_MAPPED_DIRECTORY, pn_float_dir, po_system_configuration.FLOAT_MAPPED_PREFIX, pn_float_name, po_system_configuration.FLOAT_MAPPED_POSTFIX ) ) ;

INTERP_PRES  = lo_float_mapped_data.la_INTERP_PRES  ;
INTERP_SAL   = lo_float_mapped_data.la_INTERP_SAL   ;
mapped_sal   = lo_float_mapped_data.la_mapped_sal   ;
mapsalerrors = lo_float_mapped_data.la_mapsalerrors ;
long_scale_large = lo_float_mapped_data.long_scale_large;
lat_scale_large  = lo_float_mapped_data.lat_scale_large ;
long_scale_small = lo_float_mapped_data.long_scale_small;
lat_scale_small  = lo_float_mapped_data.lat_scale_small ;

lo_float_calseries = load( strcat( po_system_configuration.FLOAT_CALIB_DIRECTORY, pn_float_dir, po_system_configuration.FLOAT_CALSERIES_PREFIX, pn_float_name, po_system_configuration.FLOAT_CALIB_POSTFIX ) ) ;

running_const = lo_float_calseries.running_const;
cal_series_flags = lo_float_calseries.cal_series_flags;

number_of_levels = str2double(po_system_configuration.NO_USED_STANDARD_LEVELS);
ptlevels = lo_float_mapped_data.la_standard_levels(1:number_of_levels);


% calculate potential conductivities and errors for mapped values,
% calculate cond error by perturbing salinity ... to avoid problems
% caused by the non-linearity of the Equation of State -----------------

[m,n] = size(mapped_sal);
ICOND = sw_c3515*sw_cndr(INTERP_SAL,ptlevels*ones(1,n),0*INTERP_SAL);
mapped_cond = sw_c3515*sw_cndr(mapped_sal,ptlevels*ones(1,n),0*mapped_sal);
mapped_cond1 = sw_c3515*sw_cndr(mapped_sal+mapsalerrors/100,ptlevels*ones(1,n),0*mapped_sal);
mapconderrors = 100*abs(mapped_cond-mapped_cond1);


% do a weighted fit solving for a single conductivity slope that is station-varying,
% i.e. time-varying ... 2 x running constant (arbitrary) + 1 profiles ----------------

for i=1:n % use each profile as the centre

 condslope(i) = NaN; % initiate the variables
 time_deriv_condslope(i) = NaN;
 condslope_err(i) = NaN;
 time_deriv_condslope_err(i) = NaN;

 if(isempty(find(isnan(SAL(:,i))==0))==0) % only proceed if the profile has data

% split series according to the cal_series file for calibration -------

   cal_index = find( cal_series_flags==cal_series_flags(i) ); % index for cal_series
   j=find(i==cal_index); % this is the position of profile i in the cal_series

   cal_LONG=LONG(cal_index);
   cal_LAT=LAT(cal_index);
   cal_long_scale=long_scale_small(cal_index);
   cal_lat_scale=lat_scale_small(cal_index);
   cal_ICOND=ICOND(:,cal_index);
   cal_mapped_cond=mapped_cond(:,cal_index);
   cal_mapconderrors=mapconderrors(:,cal_index);

   [g,h] = size(cal_mapped_cond); % set up a matrix of cal_series index
   ju = [1:h];
   cal_floatindex = ones(g,1)*(ju);

   if( j<=running_const(i) ) % find the two ends of the time series
     a=1;
   else
     a=j-running_const(i);
   end
   b=min( j+running_const(i), h );

   r = length(a:b); % length of a:b should equal 2xrunning_const+1 when there are enough profiles
   x = cal_LONG(a:b);
   y = cal_LAT(a:b);
   Lx= cal_long_scale(a:b); % Lx and Ly will be NaNs if no mapped_sal exists for that profile (for whatever reasons)
   Ly= cal_lat_scale(a:b);
   trunc_cal_ICOND=cal_ICOND(:,a:b);
   trunc_cal_mapped_cond=cal_mapped_cond(:,a:b);
   trunc_cal_mapconderrors=cal_mapconderrors(:,a:b);
   trunc_cal_floatindex=cal_floatindex(:,a:b);

   cal_diffcond=trunc_cal_ICOND-trunc_cal_mapped_cond;
   jj = find(finite(cal_diffcond)==1); % weed out all the NaNs

   lvcovariance = build_lvcov(x,y,Lx,Ly,ptlevels); % build the data covariance matrix
   lvcovariance = lvcovariance(jj,jj);

   if(r>1)
     G = [trunc_cal_ICOND(jj),trunc_cal_ICOND(jj).*(trunc_cal_floatindex(jj)-j)]; % build the model matrix
   else
     G = [ trunc_cal_ICOND(jj) ]; % for fitting a single profile
   end

   W = diag(1./trunc_cal_mapconderrors(jj));

% note: pinv(W*G)*W is equivalent to
% [u,s,v]=svd(W*G);
% geninv=v(:,1:2)*inv(s(1:2,1:2))*u(:,1:2)'*W;

   if(length(jj)>1) % only proceed if there are more than one data point

    [u,s,v]=svd(W*G);
    if(r>1)
      geninv=v(:,1:2)*inv(s(1:2,1:2))*u(:,1:2)'*W; % solve the system
    else
      geninv=v(:,1:1)*inv(s(1:1,1:1))*u(:,1:1)'*W; % for fitting a single profile
    end
    naturalsoln = geninv*trunc_cal_mapped_cond(jj);

    if(r>1)
      if((isempty(naturalsoln)==1)|(rank(W*G)<2))
        condslope(i) = NaN;
        time_deriv_condslope(i) = NaN;
      else
        condslope(i) = naturalsoln(1);
        time_deriv_condslope(i) = naturalsoln(2);
      end
    else
      condslope(i) = naturalsoln; % for fitting a single profile
      time_deriv_conslope(i) = NaN;
    end

    R2 = diag(trunc_cal_mapconderrors(jj).^2)*lvcovariance; % error estimation
    error = sqrt(diag(geninv*R2*geninv'));

    if(r>1)
      if((isempty(error)==1)|(rank(W*G)<2))
        condslope_err0(i) = NaN;
        time_deriv_condslope_err(i) = NaN;
      else
        condslope_err0(i) = error(1);
        time_deriv_condslope_err(i) = error(2);
      end
    else
      condslope_err0(i) = error; % for fitting a single profile
      time_deriv_condslope_err(i) = NaN;
    end

    if( (r>1) & (r<2*running_const(i)+1) ) % if the series is shorter than 2xrunning_const+1
      midpt=(a+b)/2;        % find mid point of the series
      condslope_err(i)=sqrt( condslope_err0(i).^2 + ((midpt-j)*time_deriv_condslope_err(i)).^2 );
    else
      condslope_err(i)=condslope_err0(i); % for fitting a single profile
    end

   end

 end

end


% apply the calibrations to float data ------------------------------

[k,n] = size(SAL);

COND = sw_c3515*sw_cndr(SAL,PTMP,0*SAL);
cal_COND = (ones(k,1)*condslope).*COND;
cal_SAL = sw_salt(cal_COND/sw_c3515,PTMP,0*SAL);


% estimate the error in salinity -------------------------------------------------

cal_COND_err = (ones(k,1)*condslope_err).*COND;
cal_SAL1 = sw_salt((cal_COND+cal_COND_err)/sw_c3515,PTMP,0*SAL);
cal_SAL_err = abs(cal_SAL-cal_SAL1);


% save calibration data --------------------------------

ls_float_calib_filename = strcat( po_system_configuration.FLOAT_CALIB_DIRECTORY, pn_float_dir, po_system_configuration.FLOAT_CALIB_PREFIX, pn_float_name, po_system_configuration.FLOAT_CALIB_POSTFIX ) ;

save( ls_float_calib_filename, 'cal_SAL', 'cal_SAL_err', 'running_const', 'condslope', 'condslope_err', 'time_deriv_condslope', 'time_deriv_condslope_err', 'cal_COND', 'cal_COND_err', 'PROFILE_NO','COND') ;


