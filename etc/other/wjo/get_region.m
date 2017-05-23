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
% This program takes a while to run has been edited to optimize (<MO>) 
%     I cut down at least 30 seconds in the date conversion program; this program is ran as many times as cycles, so in the end, it saves
%     us around 50 minutes
%     I also cut down 4 seconds in the loading of archive data

[pa_grid_sal,pa_grid_pres,pa_grid_lat,pa_grid_long,pa_grid_dates] = deal([ ]);
j=0; %mo
for ln_index = 1:size(pa_wmo_numbers,1)
    %<mo/> changed some syntax to make use of logical indices and structs
    numberr=sprintf( '%4d', pa_wmo_numbers(ln_index,1));
    if( ~isnan(pa_wmo_numbers(ln_index,1)) && pa_wmo_numbers(ln_index,2)==1 ) % the 2nd column denotes CTD data
        j=j+1; %mo
        temp = load( strcat( po_config_data.HISTORICAL_DIRECTORY, po_config_data.HISTORICAL_CTD_PREFIX,numberr),'interp_sal','interp_pres','lat','long','dates');
        lo_box_data(j)=sortstruct(temp);
    end
    if( ~isnan(pa_wmo_numbers(ln_index,1)) && pa_wmo_numbers(ln_index,3)==1 ) % the 3rd column denotes bottle data
        j=j+1;
        temp = load( strcat( po_config_data.HISTORICAL_DIRECTORY, po_config_data.HISTORICAL_BOTTLE_PREFIX,numberr),'interp_sal','interp_pres','lat','long','dates');
        lo_box_data(j)=sortstruct(temp);    
    end
    if( ~isnan(pa_wmo_numbers(ln_index,1)) && pa_wmo_numbers(ln_index,4)==1 ) % the 3rd column denotes bottle data
        j=j+1;
        temp = load( strcat( po_config_data.HISTORICAL_DIRECTORY, po_config_data.HISTORICAL_ARGO_PREFIX,numberr),'interp_sal','interp_pres','lat','long','dates');
        lo_box_data(j)=sortstruct(temp);        
    end
    %</mo>
end
%<mo/>
pa_grid_sal   = cat(2,lo_box_data.interp_sal);
pa_grid_pres  = cat(2,lo_box_data.interp_pres);
pa_grid_lat   = cat(2,lo_box_data.lat);
pa_grid_long  = cat(2,lo_box_data.long);
pa_grid_dates = cat(2,lo_box_data.dates);
%</mo>
% if no boxes are assigned
if( isempty( pa_grid_lat ))
    pa_grid_lat = 999 ;
    pa_grid_long = 999 ;
    pa_grid_dates = NaN ;
    pa_grid_sal = -99 ;
    pa_grid_pres = -99 ;
end
% longitude goes from 0 to 360 degrees
ln_jj = pa_grid_long < 0 ;
pa_grid_long( ln_jj ) = 360 + pa_grid_long( ln_jj ) ;
% make sure longitude is continuous around the 0-360 degree mark
ln_kk = find( pa_grid_long>=320 & pa_grid_long<=360 ) ;
if ~isempty(ln_kk)
    ln_ll = find( pa_grid_long>=0 & pa_grid_long<=40 ) ;
    pa_grid_long( ln_ll ) = 360 + pa_grid_long( ln_ll ) ;
end

% make pa_grid_sal and pa_grid_pres have the same NaNs MO edited this to make it 3 times faster
ln_ii = isnan(pa_grid_sal);
pa_grid_pres(ln_ii) = NaN; 
ln_ii = isnan( pa_grid_pres );
pa_grid_sal(ln_ii) = NaN;
pa_grid_dates = changedates( pa_grid_dates ) ; %<mo> changed this program to account for leap years and to make it run 30 times faster

% turns rows into columns
pa_grid_lat = pa_grid_lat' ;
pa_grid_long = pa_grid_long' ;

function out=sortstruct(in);
out=[];
fnames = fieldnames(in);
sortednames=sort(fnames);
for k=1:size(sortednames,1)
    out=setfield(out,sortednames{k},getfield(in,sortednames{k}));
end