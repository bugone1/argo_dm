
function [ pa_grid_sal, pa_grid_pres, pa_grid_lat, pa_grid_long, pa_grid_dates ] = get_region( pa_wmo_numbers, po_config_data ) ;

% function [ pa_grid_sal, pa_grid_pres, pa_grid_lat, pa_grid_long, pa_grid_dates ] = get_region( pa_wmo_numbers, po_config_data ) ;
%
% this function gets historical data from the 25 selected WMO boxes,
% merges the CTD, BOT and Argo files, makes sure longitude is continuous
% around the 0-360 degree mark, and converts the dates of the
% historical data from time format2 to year.mo+ (changedates.m).
%
% pa_wmo_numbers can be NaN: when float profiles are out of range (65N, 65S),
% or when there's no .mat file in that box, denoted by 0 (e.g. box on land).
%
% Historical data have lat,long and dates organised in single rows.
% The output from this function gives lat,long and dates in columns,
% just for ease of checking .... really doesn't matter.
%
% A. Wong, 16 August 2004
%
%<mo> variables' initialisation on one line 
[pa_grid_sal,pa_grid_pres,pa_grid_lat,pa_grid_long,pa_grid_dates]=deal([ ]);
%<mo> removed some if clauses by introducing a loop and system of cell arrays
archname={'','CTD','BOTTLE','ARGO'}; %the position of cell must correspond to the column in pa_wmo_numbers CTD=2, BOTTLE=3, ARGO=4
for ln_index = 1:length(pa_wmo_numbers)
    display(['Number ' num2str(ln_index) ' of ' length(pa_wmo_numbers)]);
    if ~isnan(pa_wmo_numbers(ln_index,1)) 
        for i=2:4
            if pa_wmo_numbers(ln_index,i)==1
                namearch=getfield(po_config.data,['HISTORICAL_' archname{i} '_PREFIX']);
                lo_box_data = load( strcat( po_config_data.HISTORICAL_DIRECTORY, namearch, sprintf( '%4d', pa_wmo_numbers(ln_index,1))));
                display(['Loading ' namearch sprintf( '%4d', pa_wmo_numbers(ln_index,1))]);
                
                pa_grid_sal   = [ pa_grid_sal,   lo_box_data.interp_sal ] ;
                pa_grid_pres  = [ pa_grid_pres,  lo_box_data.interp_pres ] ;
                pa_grid_lat   = [ pa_grid_lat,   lo_box_data.lat ] ;
                pa_grid_long  = [ pa_grid_long,  lo_box_data.long ] ;
                pa_grid_dates = [ pa_grid_dates, lo_box_data.dates ] ;
            end
        end
    end
end
% if no boxes are assigned
if isempty( pa_grid_lat )
    pa_grid_lat = 999 ;
    pa_grid_long = 999 ;
    pa_grid_dates = NaN ;
    pa_grid_sal = -99 ;
    pa_grid_pres = -99 ;
end
% longitude goes from 0 to 360 degrees
ln_jj = find( pa_grid_long < 0 ) ;
pa_grid_long( ln_jj ) = 360 + pa_grid_long( ln_jj ) ;

% make sure longitude is continuous around the 0-360 degree mark
ln_kk = find( pa_grid_long>=320 & pa_grid_long<=360 ) ;
if ~isempty( ln_kk ) 
    ln_ll = find( pa_grid_long>=0 & pa_grid_long<=40 ) ;
    pa_grid_long( ln_ll ) = 360 + pa_grid_long( ln_ll ) ;
end
% make pa_grid_sal and pa_grid_pres have the same NaNs
ln_ii = find( isnan( pa_grid_sal ) == 1 ) ;
pa_grid_pres( ln_ii ) = NaN.*ones( 1, length( ln_ii ) ) ;
ln_ii = find( isnan( pa_grid_pres ) == 1 ) ;
pa_grid_sal( ln_ii ) = NaN.*ones( 1, length( ln_ii ) ) ;
pa_grid_dates = changedates( pa_grid_dates ) ;
% turns rows into columns
pa_grid_lat = pa_grid_lat' ;
pa_grid_long = pa_grid_long' ;