function fig_traj=plot_time_and_traj(t,t_traj)
% PLOT_TIME_AND_TRAJ Plot the trajectory and cycle number as a function of
%   time for a float, based on both the profile data and optionally the
%   trajectory data.
%   USAGE: 
%       fig_traj=plot_time_and_traj(t,t_traj)
%   INPUTS:
%       t - structure of profile data, as obtained from read_nc_all
%   OPTIONAL INPUTS:
%       t_traj - structure of trajectory data, e.g. from read_traj_nc
%   OUTPUTS:
%       fig_traj - handle to the figure created
%   VERSION HISTORY:
%       Isabelle Gaboury, 5 Jan. 2017: Written, using code extracted from
%           interactive_qc_ig.m

if nargin < 2, t_traj = {}; end

% Plot the float positions, dates. Load the coast data, deal with discontinuities
% and wrap-around, display.
fig_traj = figure('units','normalized','position',[0.7 0.25 0.25 0.5]);
subplot(2,1,1);
dates_temp = [t.dates];
cycles_temp = [t.cycle_number];
lon_temp = [t.longitude];
lat_temp = [t.latitude];
hp=plot(lon_temp,lat_temp,'k');
position_accuracy = repmat(' ',1,length(t));
if ~isempty(t_traj)
    ok = ~isnan(t_traj.longitude);
    hold on; ht=plot(t_traj.longitude(ok), t_traj.latitude(ok), 'color', [0.5 0.5 0.5]); 
    legend([hp,ht],'profiles','trajectory','location', 'southeast');
    for ii=1:length(t)
        ok = find(t_traj.cycle_number==t(ii).cycle_number & t_traj.position_accuracy~=' ');
        if length(ok)>=1
            % TODO: Finish testing this
            if length(ok)>1, error('Check that we''re dealing correctly with >1 position accuracy'); end
            position_accuracy(ii) = t_traj.position_accuracy(ok);
        end
    end
end
h=scatter3(lon_temp,lat_temp,[t.cycle_number],30,[t.cycle_number],'filled');
if ~isempty(t_traj)
    set(h,'userdata',position_accuracy);
end
hold on;
ok = [t.position_qc] > '1';
if ~isempty(ok), plot(lon_temp(ok),lat_temp(ok),'ko','markersize',7); end
if ~isempty(t_traj)
    ok = t_traj.position_qc > '1' & t_traj.position_qc < '9';
    if ~isempty(ok)
        plot(t_traj.longitude(ok), t_traj.latitude(ok),'o', 'color', [0.5 0.5 0.5], 'markersize',7); 
    end
end
xlabel('Longitude');
ylabel('Latitude');
grid on;
foo=colorbar;
set(get(foo,'xlabel'),'string','Cycle #');
subplot(2,1,2);
scatter(dates_temp,cycles_temp,30,cycles_temp,'filled');
foo=find([t.juld_qc]>'1');
if ~isempty(foo)
    hold on;
    plot(dates_temp(foo),cycles_temp(foo),'o');
end
xlabel('Date'); ylabel('Cycle number');
grid on;
foo=colorbar;
set(get(foo,'xlabel'),'string','Cycle #');
datetick('x','dd mmm yyyy')

% Set a custom data cursor mode so we can get the profile number
dcm_obj = datacursormode(fig_traj);
set(dcm_obj,'UpdateFcn',@profile_traj_datatip)
end

function txt = profile_traj_datatip(hObject,event)
    % Customizes text of data tips

    % Get the position clicked and the handle to the thing clicked on
    pos = get(event,'Position');
    h=get(event,'target');
    h_data = get(h,'userdata');
    
    % If the position has length 2 then this is the plot of cycle number
    % vs. time and I would just like to reformat the time
    if length(pos)==2
        txt = {['X: ', datestr(pos(1))], ['Y: ', num2str(pos(2))]};
    elseif length(pos)==3
        txt = {['X: ', num2str(pos(1))], ['Y: ', num2str(pos(2))], ...
            ['N: ', num2str(pos(3))], ['acc: ', h_data(get(event, 'DataIndex'))]};
    end
    

end