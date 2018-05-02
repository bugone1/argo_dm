function plot_float_tsprof(float_num, qc_good_only, highlight_cycle)
% PLOT_FLOAT_TSPROF Plot float temperature and salinity profiles as a
%   function of the cycle number. Data are read from the .mat file for the
%   float.
%   USAGE: plot_float_tsprof(float_num, qc_good_only, highlight_cycle)
%   INPUTS:
%       float_num - float number
%   OPTIONAL INPUTS:
%       qc_good_only - set to 1 to hide points with QC flags other than '1'
%       highlight_cycle - optional cycle to highlight
%   VERSION HISTORY:
%       Isabelle Gaboury, January 2018: Written
%       1 May 2018, IG: Highlight cycle can now be a vector

% Default values
if nargin < 3, highlight_cycle=[]; end
if nargin<2, qc_good_only=0; end
ITS90toIPTS68=1.00024;

% Make sure the Seawater toolboxe is on the path
if ~ispc
    addpath('/u01/rapps/seawater');
    %addpath('/u01/rapps/gsw/');
    %addpath('/u01/rapps/gsw/library');
else
    addpath('w:\seawater');
    %addpath('w:\gsw');
    %addpath('w:\gsw\library');
end

% Load the data
load(['/u01/rapps/argo_dm/data/temppresraw/' float_num]);

% Create matrices for plotting
lt=length(t);
si = zeros(1,lt);   
for ii_cyc=1:lt, si(ii_cyc) = length(t(ii_cyc).pres); end
[PRES,PSAL,TEMP,PRES_QC,PSAL_QC,TEMP_QC]=deal(nan(max(si),lt)); %preallocate profile with max depths
for i=1:lt
    PROFILE_NO(i)=t(i).cycle_number;
    PRES(1:si(i),i)=t(i).pres;
    PSAL(1:si(i),i)=t(i).psal;
    TEMP(1:si(i),i)=t(i).temp;
    PRES_QC(1:si(i),i)=t(i).pres_qc;
    PSAL_QC(1:si(i),i)=t(i).psal_qc;
    TEMP_QC(1:si(i),i)=t(i).temp_qc;
end

% Find bad values
bad_temp=(PRES_QC > '1' | TEMP_QC>'1');
bad_psal=(PRES_QC > '1' | PSAL_QC>'1');
if qc_good_only
    TEMP(bad_temp)=NaN;
    PSAL(bad_psal)=NaN;
end

% Plot
figure
set(gcf,'colormap',jet(lt));
ax1=subplot(1,2,1);
set(ax1,'colororder',jet(lt));
h1=plot(TEMP, PRES,'- .');
if ~qc_good_only
    hold on; plot(TEMP(bad_temp),PRES(bad_temp),'ko');
end
if ~isempty(highlight_cycle)
    [foo1,ii_hl,foo2]=intersect(PROFILE_NO,highlight_cycle);
    if isempty(ii_hl), highlight_cycle=[]; end
    hold on; plot(TEMP(:,ii_hl),PRES(:,ii_hl),'wo');
end
xlabel('temp'); ylabel('pres'); grid on;
set(gca,'ydir','rev');
colorbar;
ax2=subplot(1,2,2);
set(ax2,'colororder',jet(lt));
h2=plot(PSAL,PRES,'- .');
if ~qc_good_only
    hold on; plot(PSAL(bad_psal),PRES(bad_psal),'ko');
end
if ~isempty(highlight_cycle)
    hold on; plot(PSAL(:,ii_hl),PRES(:,ii_hl),'wo');
end
xlabel('psal'); ylabel('pres'); grid on;
set(gca,'ydir','rev');
colorbar
linkaxes([ax1,ax2],'y');

% Add userdata so the tooltip works
for ii=1:length(h1)-1, set(h1(ii),'userdata',t(ii).cycle_number); end
for ii=1:length(h2)-1, set(h1(ii),'userdata',t(ii).cycle_number); end

% Set a custom data cursor mode so we can get the profile number
dcm_obj = datacursormode(gcf);
set(dcm_obj,'UpdateFcn',@profile_ts_datatip)

% Also plot the TS curves
PTMP = sw_ptmp(PSAL,TEMP*ITS90toIPTS68,PRES,0);
plot_float_ts(PROFILE_NO,PTMP,PSAL,TEMP_QC,PSAL_QC,qc_good_only,highlight_cycle);

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