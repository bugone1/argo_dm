function fig_ts=plot_float_ts(PROFILE_NO,PTMP,PSAL,TEMP_QC,SAL_QC,qc_good_only)
% PLOT_FLOAT_TS Plot TS for all float profiles
%   USAGE:
%       plot_float_ts(PROFILE_NO,PTMP,PSAL,TEMP_QC,SAL_QC)
%   INPUTS:
%       PROFILE_NO - Vector of profile numbers
%       PTMP - Matrix of potential temperature, one row per depth and one
%           column per profile
%       PSAL - Matrix of salinity, same dimensions as PTMP
%       TEMP_QC - Matrix of temperature QC flags, same dimensions as PTMP
%       SAL_QC - Matrix of salinity QC flags, same dimensions as PSAL
%   OUTPUTS:
%       fig_ts - Figure handle
%   VERSION HISTORY:
%       02 Aug. 2017, Isabelle Gaboury: Created, based on
%           interactive_qc_ig.m
%       10 Nov. 2017, IG: Added the qc_good_only functionality

if nargin<6, qc_good_only=0; end

% Figure out which positions are good
ok=(SAL_QC>'1' | TEMP_QC>'1');
[foo,prof_qc]=find(ok);
if qc_good_only
    PSAL(ok)=NaN;
    PTMP(ok)=NaN;
end

% Prepare the figure
fig_ts = figure('units','normalized','position',[0.25 0.25 0.25 0.5]);
lt=length(PROFILE_NO);
set(gca,'colororder',jet(lt));
h=plot(PSAL, PTMP, '.');
if ~qc_good_only
    hold on; h(end+1) = plot(PSAL(ok), PTMP(ok), 'o');
end
for ii=1:length(h)-1
    set(h(ii),'userdata',PROFILE_NO(ii));
end
set(h(end),'userdata',PROFILE_NO(prof_qc));
% This line just tricks colorbar into working correctly for later
% versions of Matlab
scatter(ones(1,lt)*NaN,ones(1,lt)*NaN,0,PROFILE_NO);
xlabel('psal'); ylabel('ptmp'); grid on;
set(fig_ts,'colormap',jet(lt)); colorbar

% Set a custom data cursor mode so we can get the profile number
dcm_obj = datacursormode(fig_ts);
set(dcm_obj,'UpdateFcn',@profile_ts_datatip)
end

function txt = profile_ts_datatip(hObject,event)
    % Customizes text of data tips

    % Get the position clicked
    pos = get(event,'Position');

    % Get the profile number. The approach depends on whether we clicked one of
    % the QC flag markers (open circles) or TS values (filled points)
    h=get(event,'target');
    h_data=get(h,'userdata');
    if get(h,'marker')=='o'
        prof_num = h_data(get(event, 'DataIndex'));
    else
        prof_num = h_data;
    end

    % Update the text box
    txt = {['X: ',num2str(pos(1))],...
           ['Y: ',num2str(pos(2))],...
           ['N: ',num2str(prof_num)]};
end