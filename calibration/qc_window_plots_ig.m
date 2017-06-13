function [h_ax, h_qc]=qc_window_plots_ig(axedesxy,clim,qcxy,labs,xyt,crn,pfn,subplot_arr)
% QC_WINDOW_PLOTS - Create subplots for QC purposes
%   DESCRIPTION:
%       Create subplots for QC, showing the current QC flags
%   USAGE:
%      [h_ax,h_qc]=qc_window_plots(axedesxy,clim,qcxy,labs,xyt,crn,pfn,subplot_arr)
%   INPUTS:   
%       axesdesxy - Profile data. This is a 2D array, with one plot
%           variable per column
%       clim - Profile of climatology bounds
%       qcxy - Profile QC flags
%       labs - x- and y-axis labels
%       xyt - Position and time string, for the title
%       crn - Platform string
%       pfn - Station/cycle string
%       subplot_arr - Array descriptor of the subplot
%   OUTPUTS:
%       h_ax - Handle to the subplot axes
%       h_qc - Cell array of handles to the QC flag plots, one per flag level
%   VERSION HISTORY:
%       25 May 2017, Isabelle Gaboury: Created, based on code in the
%           vms_tools directory dated 9 January 2017.

% Setup
colscheme='bymr';

% Prepare the inputs
if isnumeric(pfn)
    pfn=num2str(pfn);
end
crn=strtok(crn,' ');

% Plotting
h_ax=subplot(subplot_arr(1),subplot_arr(2),subplot_arr(3));
hold on;
xyt=double(xyt);
set(gcf,'units','normalized')%,'position',[0 0 1 1]);
if subplot_arr(end) == floor(subplot_arr(2)/2)
    if size(xyt,1)==1
        title(sprintf(...
            ['Long:%6.3f,Lat:%5.3f,Date:' datestr(xyt(3),'yyyymmdd HH:MM') ' Plat:' crn ' Stn/Cyc:' pfn],...
            xyt(1),xyt(2)));
    else
        title(sprintf(...
            ['Long:%6.3f-%6.3f,Lat:%5.3f-%5.3f,Dates:' datestr(min(xyt(:,3)),'yyyymmdd HH:MM') '-' datestr(max(xyt(:,3)),'yyyymmdd HH:MM') ' Plat:' crn],...
            min(xyt(:,1)),max(xyt(:,1)),min(xyt(:,2)),max(xyt(:,2))));
    end
end
if strcmp(labs(2,:),'pres')
    rn='reverse';
else
    rn='normal';
end
set(gca,'units','normalized','xgrid','on','ygrid','on','Ydir',rn); % 'position',[0.1 0.1 .7 0.85],

if  ~isempty(clim)
    patch(clim.temp,clim.pres,ones(1,3)*.88,'edgecolor','none')
end

% Plot the data
plot(axedesxy(:,1),axedesxy(:,2),'-');
yylim=[min(axedesxy(:,2)) max(axedesxy(:,2))]+[-.05 .05];
if all(isnan(yylim))
    yylim=[0 1];
end
set(gca,'ylim',yylim);

% Array of QC values
% To start we assume we're flagging the x-axis
xlabel([labs(1,:), ' - flags from this axis currently shown']);
ylabel(labs(2,:));
% For each possible QC flag, plot the points
h_qc = cell(length(colscheme),2);
for i=1:length(colscheme)
    ok=qcxy(:,1)==num2str(i);
    if ~any(ok==1), h_qc{i,1} = plot(NaN,NaN,['.' colscheme(i)]);   % This just leaves a placeholder we can use later
    else h_qc{i,1}=plot(axedesxy(ok,1),axedesxy(ok,2),['.' colscheme(i)]);
    end
end
set(cat(1,h_qc{:}),'markersize',16);

% Indicate position(s) of QC flags on the other axis along the edge of the
% plot
xxlim = get(gca,'xlim');
for i=2:length(colscheme)
    ok=qcxy(:,2)==num2str(i);
    if ~any(ok==1), h_qc{i,2} = plot(NaN,NaN,['+' colscheme(i)]);   % This just leaves a placeholder we can use later
    else h_qc{i,2}=plot(xxlim(1),axedesxy(ok,2),['+' colscheme(i)]);
    end
end
    
end % end of qc_window_plots function