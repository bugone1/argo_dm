function [prof_data_qc,but]=qc_window_ig(prof_data,S,prof_data_qc,plot_labels,title_string,...
    platform_string,station_string)
% QC_WINDOW_UI - Get and process user input from the visual QC window
%   USAGE:
%      [prof_data_qc,q]=qc_window_ig(prof_data,S,prof_data_qc,plot_labels,title_string,...
%           platform_string,station_string);
%       Once the GUI window has been displayed, the following options are
%       available:
%           use left button to toggle switch from QC of 1 to 4 to 3
%           use right button to go back to QC of 1
%           press enter or q when done
%           press 1,2,3 or 4 to flag everything to 1,2,3 or 4
%           press x,y if you want flags to apply to the x,y axis (default is x)
%           press z to toggle flags from 1 to 4 or vice versa
%           (flags of 2 can only be set with the keyboard)
%   INPUTS:   
%       prof_data - Profile data. This is a cell array with one element per
%           plot to be generated. For each cell element, there is a 2D
%           array, one row per sampled depth, one column per plot variable.
%       S - Climatology-based error bars; this is a cell array with one
%           element per plot to be generated.
%       prof_data_qc - Profile data QC. Same format as prof_data
%       plot_labels - Cell array of plot labels, one per plot to be generated;
%           for each element, this contains vertically concatenated plot
%           labels
%       title_string - Overall title string
%       platform_string - String describing the platform
%       station_string - String describing the station or cycle
%   OUTPUTS:
%       prof_data_qc - Updated QC data (same format as above)
%       but - Last button selected via ginput
%   VERSION HISTORY:
%       26 May 2017, Isabelle Gaboury: Created, based on code in the
%           vms_tools directory dated 9 January 2017.

% Starting values
n_plots = length(plot_labels);

% If the figure hasn't been set up as our GUI window yet, we clear it.
% Otherwise we just clear the axes
gui_fig = gcf;
if isempty(findobj('parent',gui_fig,'type','uipanel'))
    clf;
    h_axes = zeros(1,n_plots);
else
    h_axes = getappdata(gui_fig,'h_axes');
    for ii_ax=1:length(h_axes), cla(h_axes(ii_ax)); end
end

% Update the application data to be used by the callbacks
setappdata(gui_fig,'but',1);
setappdata(gui_fig,'indxy',1);  % We assume that we're doing QC on the x-variable
setappdata(gui_fig,'plot_labels',plot_labels);
setappdata(gui_fig,'prof_data_qc',prof_data_qc);

for ii_plot = 1:n_plots
    h_axes(ii_plot) = qc_window_plots_ig(prof_data{ii_plot}, S{ii_plot},prof_data_qc{ii_plot},...
        plot_labels{ii_plot},title_string, platform_string, station_string, ...
        [1, length(plot_labels)+1, ii_plot]);
end
% Store the list of axes for later use. We could count on the fact that the
% handles are always in order, but this seems safer
setappdata(gui_fig,'h_axes',h_axes);

% Link the axes to simplify zooming
linkaxes(h_axes(1:end-1),'y');

% Add the GUI elements
if isempty(findobj('parent',gui_fig,'type','uipanel'))
    % Get the right edge of the right-most plot
    foo = get(h_axes(end),'position');
    h_ui = uipanel('Title','Visual QC','Position',[foo(1)+foo(3)*1.05,0.05,(0.99-(foo(1)+foo(3)*1.05)),0.9]);
    x0_gui=0.02;
    y0_gui=1.0;
    y_cur=y0_gui-0.04;
    but_width =0.4;
    but_height=0.03;
    % Select individual points
    uicontrol('parent',h_ui,'style','pushbutton','string','Flag points (q to stop)', ...
        'units','normalized', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @flag_points);
    y_cur=y_cur-0.04;
    % Select polygon
    uicontrol('parent',h_ui,'style','pushbutton','string','Flag points by polygon', ...
        'units','normalized', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @flag_points_poly);
    y_cur=y_cur-0.05;
    % Toggle flags for the entire profile
    tog_flag_bg = uibuttongroup('parent',h_ui,'tag','tog_flag_bg', ...
        'position',[x0_gui,y_cur,but_width,but_height+0.01], ...
        'title','Flag all to #', 'SelectionChangeFcn',@flag_whole_profile);
    for ii=1:4
        uicontrol(tog_flag_bg,'style','radiobutton','string',num2str(ii),...
            'units','normalized','position',[(ii-1)*0.25,0,0.25,1]);
    end
    set(tog_flag_bg,'selectedobject','');
    uicontrol('parent',h_ui,'style','checkbox','tag','flag_allplots_checkbox', 'string','Apply to all profile plots', ...
        'units','normalized','position',[x0_gui+but_width+0.01,y_cur+but_height*.75,but_width,but_height*0.75]);
    uicontrol('parent',h_ui,'style','checkbox','tag','flag_bothaxes_checkbox', 'string','Apply to both axes', ...
        'units','normalized','position',[x0_gui+but_width+0.01,y_cur,but_width,but_height*0.75]);
    % y_cur=y_cur-0.04;
    % % Swap flags 1 and 4 (commented out because I've never needed it)
    % swap_but = uicontrol('Parent',gui_fig,'Style','pushbutton', 'String', 'Invert 1 to 4 and 4 to 1', ...
    %     'Units', 'normalized', 'Position', [x0_gui,y_cur,0.1,0.03], ...
    %     'callback', @swap_flags_1_and_4);
    y_cur=y_cur-0.05;
    % Select axes to select on
    tog_ax_bg = uibuttongroup('parent',h_ui,'tag','tog_ax_bg','position',[x0_gui,y_cur,but_width,but_height+0.01], ...
        'title', 'Axes to flag', 'SelectionChangeFcn', @toggle_select_axes);
    uicontrol(tog_ax_bg,'style','radiobutton','tag','tog_ax_bg_x','string','x','units','normalized','position',[0,0,0.5,1]);
    uicontrol(tog_ax_bg,'style','radiobutton','tag','tog_ax_bg_y','string','y','units','normalized','position',[0.5,0,0.5,1])
    % y_cur=y_cur-0.04;
    % % Zoom to the surface layer
    % zoom_but = uicontrol('Parent',gui_fig,'style','pushbutton','string','Zoom to upper 200m',...
    %     'units','normalized','position',[x0_gui,y_cur,0.9,0.03],'callback',@zoom_to_surface);
    y_cur=y_cur-0.11;
    % Skip button group
    skip_bg = uibuttongroup('parent',h_ui,'position',[x0_gui,y_cur,but_width*2,0.1],...%0.18,0.1], ...
        'title', 'Skip to another profile');
    uicontrol(skip_bg,'Style','pushbutton','String','Next profile', ...
        'Units','normalized', 'Position',[0,0.5,0.5,0.4], 'tag', 'skip_to_next_button', ...
        'callback', @update_but_and_resume);
    uicontrol(skip_bg,'Style','pushbutton','tag','skip_to_prev_button','String','Previous profile', ...
        'Units','normalized', 'Position',[0.5,0.5,0.5,0.4], 'callback', @update_but_and_resume);
    uicontrol(skip_bg,'Style','pushbutton','tag','skip_to_flagged_button','String','Next profile with flag>1', ...
        'Units','normalized', 'Position',[0,0,0.75,0.4], 'callback', @update_but_and_resume);
    uicontrol(skip_bg,'Style','pushbutton','tag','skip_button','String','End', 'Units','normalized',...
        'Position',[0.75,0,0.25,0.4], 'callback', @update_but_and_resume);
    % Quit visual QC, either saving progress or not
    y_cur=y_cur-0.04;
    uicontrol('parent',h_ui,'tag','quit_button','string','Quit visual QC', ...
        'units','normalized', 'position',[x0_gui,y_cur,but_width,but_height], ...
        'callback', @update_but_and_resume);
    % % Figure keypress callback
    set(gui_fig,'KeyPressFcn', @qc_window_keypress);
    % Restore the figure toolbar
    set(gui_fig,'toolbar','figure');
else
    % For now we always start by showing the x-flags, selecting one plot at
    % a time
    set(findobj('tag','flag_allplots_checkbox'),'value',0);
    set(findobj('tag','flag_bothaxes_checkbox'),'value',0);
    set(findobj('tag','tog_ax_bg_x'),'value',1);
    setappdata(gcf,'indxy',1);
end

% Wait for user input
uiwait(gui_fig);

% Get the current QC data
prof_data_qc = getappdata(gcf,'prof_data_qc');

% Make sure the QC matrix contains only chars
for ii_plot=1:length(plot_labels)
    prof_data_qc{ii_plot}=char(prof_data_qc{ii_plot});
end

but = getappdata(gui_fig,'but');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI functions. We nest them here so they can access the main function
% variables

% Flag individual points by clicking
function flag_points(hObject, event, handles)
    indxy = getappdata(gcf,'indxy');
    prof_data_qc = getappdata(gcf,'prof_data_qc');
    but_ptsel=1;
    while but_ptsel~='q'
        [xi,yi,but_ptsel]=ginput(1);
        % Find the closest point to where the user clicked
        % (Pythagoras). Note that ginput automatically changes the
        % current axis.
        if but_ptsel~='q'
            ii_plot_fn = find(getappdata(gcf,'h_axes')==gca);
            if strncmp(get(get(gca,'xlabel'),'string'),'dens',4), warning('Cannot select points from the density plot'); 
            else
                prof_data_x = get(findobj('parent',gca,'type','line','tag','profile'),'xdata');
                prof_data_y = get(findobj('parent',gca,'type','line','tag','profile'),'ydata');
                pdif=(prof_data_x-xi)/diff(get(gca,'xlim')); 
                idif=(prof_data_y-yi)/diff(get(gca,'ylim'));
                [tr,i]=min(pdif.^2+idif.^2);
                if but_ptsel==1
                    if prof_data_qc{ii_plot_fn}(i,indxy)=='1'
                        prof_data_qc{ii_plot_fn}(i,indxy)='4';
                    elseif prof_data_qc{ii_plot_fn}(i,indxy)=='4'
                        prof_data_qc{ii_plot_fn}(i,indxy)='3';
                    elseif prof_data_qc{ii_plot_fn}(i,indxy)=='3'
                        prof_data_qc{ii_plot_fn}(i,indxy)='1';
                    end
                elseif but_ptsel==3
                    prof_data_qc{ii_plot_fn}(i,indxy)='1';
                end
                setappdata(gcf,'prof_data_qc',prof_data_qc);
                update_related_profiles(ii_plot_fn);
                update_qc_flag_curves;
            end
        end
    end
end

% Flag points by polygon
% TODO: I would like to make this a bit clearer
function flag_points_poly(hObject, event, handles)
    indxy = getappdata(gcf,'indxy');
    prof_data_qc = getappdata(gcf,'prof_data_qc');
    [xy1,xy2,fla]=ginput(4);
    xy=[xy1 xy2];
    fla=fla(end);
    if fla > 1, fla = fla+1; end
    if fla>=0 && fla<5, fla=char(fla+'0'); end
    ii_plot_fn = find(getappdata(gcf,'h_axes')==gca);
    if strncmp(get(get(gca,'xlabel'),'string'),'dens',4), warning('Cannot select points from the density plot'); 
    else
        xlims = minmax(xy(:,1));
        ylims = minmax(xy(:,2));
        prof_curve = findobj('parent',gca,'type','line','tag','profile');
        prof_data_x = get(prof_curve,'xdata');
        prof_data_y = get(prof_curve,'ydata');
        ok1=inpolygon(prof_data_x,prof_data_y,...
            [xlims, fliplr(xlims)], [ylims(1),ylims(1),ylims(2),ylims(2)]);
        prof_data_qc{ii_plot_fn}(ok1,indxy)=char(fla);
        setappdata(gcf,'prof_data_qc',prof_data_qc);
        update_related_profiles(ii_plot_fn);
        update_qc_flag_curves;
    end
end

% Toggle profile flags
function flag_whole_profile(hObject, event, handles)
    plot_labels = getappdata(gcf,'plot_labels');
    new_flag = get(event.NewValue,'string');
    h_axes = getappdata(gcf,'h_axes');
    flag_allplots_checkbox = findobj('type', 'uicontrol', 'tag', 'flag_allplots_checkbox');
    if get(flag_allplots_checkbox,'value')==1
        ii_plot_fn = 1:length(h_axes);
    else ii_plot_fn = find(h_axes==gca);
    end
    flag_bothaxes_checkbox = findobj('type', 'uicontrol','tag','flag_bothaxes_checkbox');
    indxy = getappdata(gcf,'indxy');
    if get(flag_bothaxes_checkbox,'value')==1
        % We want to do both axes, but ending with the current one to end
        % up back at the expected plot.
        if indxy==1, indxy = [2,1]; 
        else indxy = [1,2];
        end
    end
    if isempty(ii_plot_fn), warning('Please select a plot first'); 
    elseif length(ii_plot_fn)==1 && strncmp(get(get(h_axes(ii_plot_fn),'xlabel'),'string'),'dens',4)
        warning('Cannot select points from the density plot'); 
    end
    for ii_ax_fn=indxy
        setappdata(gcf,'indxy',ii_ax_fn);
        for ii_fn=1:length(ii_plot_fn)
            if strcmp(plot_labels{ii_plot_fn(ii_fn)}(2,1:4),'pres') && ~strcmp(plot_labels{ii_plot_fn(ii_fn)}(1,1:4),'dens')
                prof_data_qc = getappdata(gcf,'prof_data_qc');            
                prof_data_qc{ii_plot_fn(ii_fn)}(:,ii_ax_fn) = new_flag;
                setappdata(gcf,'prof_data_qc',prof_data_qc);
                update_related_profiles(ii_plot_fn(ii_fn));
            end
        end
        update_qc_flag_curves;
    end
    % Reset control for later reuse
    set(findobj('tag','tog_flag_bg'),'selectedobject','');
end

%     % Switch between QC flags 1 and 4
%     % I've never needed this, but am leaving it here just in case
%     function swap_flags_1_and_4(hObject, event, handles)
%         ii_plot_fn = find(h_axes==gca);
%         if isempty(ii_plot_fn), warning('Please select a plot first'); 
%         elseif strcmp(plot_labels{ii_plot_fn}(1,1:4),'dens')
%             warning('Cannot select points from the density plot'); 
%         else
%             ok1=prof_data_qc{ii_plot_fn}(:,indxy)=='4';
%             ok2=prof_data_qc{ii_plot_fn}(:,indxy)=='1';
%             prof_data_qc{ii_plot_fn}(ok1,indxy)='1';
%             prof_data_qc{ii_plot_fn}(ok2,indxy)='4';
%             update_related_profiles(ii_plot_fn);
%             update_qc_flag_curves;
%         end
%     end

% Toggle axes for selection
function toggle_select_axes(hObject, event, handles)
    new_ax = get(event.NewValue,'string');
    indxy=new_ax-'w';
    setappdata(gcf,'indxy',indxy);
    [xflags,yflags]=deal('');
    if indxy==1
        xflags=' - flags from this axis currently shown';
    else
        yflags=' - flags from this axis currently shown';
    end
    h_axes = getappdata(gcf,'h_axes');
    for ii_ax=1:length(h_axes)
        foo = get(get(h_axes(ii_ax),'xlabel'),'string');
        set(get(h_axes(ii_ax),'xlabel'), 'string', [foo(1:4) xflags]);
        foo = get(get(h_axes(ii_ax),'ylabel'),'string');
        set(get(h_axes(ii_ax),'ylabel'), 'string', [foo(1:4) yflags]);
    end
    update_qc_flag_curves;
end

% Update the 'but' variable used by the parent routines and resume
% (thus causing the function to return to its caller)
function update_but_and_resume(hObject, event, handles)
    but=getappdata(gcf,'but');
    switch get(hObject,'tag')
        case 'skip_to_next_button', but=' ';
        case 'skip_to_prev_button', but=8;  % This is the backspace character
        case 'skip_button', but='q';
        case 'skip_to_flagged_button', but='s';
        case 'quit_button', but='Q';
    end
    setappdata(gcf,'but',but);
    uiresume(gcf);
end

% Keypress handler
% TODO: What else do we want to add here? Do I want all the original
% keystrokes?
function qc_window_keypress(hObject, event, handles)
    if event.Character==' ' || event.Character==8
        setappdata(gcf,'but',event.Character);
        uiresume(gcf);
    end
end

% Zoom to the upper 200m
%     function zoom_to_surface(hObject,event,handles)
%         % TODO: This should eventually check that it's adjusting only axes
%         % with pressure on the y-axis, but this is usually the case for all
%         % for the last (TS) plot
%         set(h_axes(1:end-1),'ylim',[0,200]);
%     end

% Update profiles with the same variable as the current axes
function update_related_profiles(ii_plot_origin)
    indxy = getappdata(gcf,'indxy');
    prof_data_qc=getappdata(gcf,'prof_data_qc');
    plot_labels = getappdata(gcf,'plot_labels');
    var_to_update = deblank(plot_labels{ii_plot_origin}(indxy,:));
    for ii_plot_fn = 1:length(findobj('parent',gcf,'type','axes'))
        if ii_plot_fn == ii_plot_origin, continue;
        else
            for ii_ax=1:2
                var_dest = deblank(plot_labels{ii_plot_fn}(ii_ax,:));
                if strcmp(var_dest,var_to_update)
                    if ii_ax==2 && size(prof_data_qc{ii_plot_fn},2) > 2
                        prof_data_qc{ii_plot_fn}(:,end) = prof_data_qc{ii_plot_origin}(:,indxy);
                    else
                        prof_data_qc{ii_plot_fn}(:,ii_ax) = prof_data_qc{ii_plot_origin}(:,indxy);
                    end
                elseif strcmp(var_dest,'dens') && ismember(var_to_update,{'pres','temp','psal'})
                    prof_data_qc{ii_plot_fn}(:,strcmp(var_to_update,{'pres','temp','psal'})) = prof_data_qc{ii_plot_origin}(:,indxy);
%                     if strcmp(var_to_update,'pres')
%                         prof_data_qc{ii_plot_fn}(:,end) = prof_data_qc{ii_plot_origin}(:,indxy);
%                     end
                end
            end
        end
    end
    setappdata(gcf,'prof_data_qc',prof_data_qc);
end

% Function to update the QC flag plots. Again, nested to avoid
% storing/passing more variables
function update_qc_flag_curves
    indxy = getappdata(gcf,'indxy');
    prof_data_qc = getappdata(gcf,'prof_data_qc');
    plot_labels = getappdata(gcf,'plot_labels');
    h_axes = getappdata(gcf,'h_axes');
    for ii_fn=1:length(h_axes)
        % Get the profile data for this plot
        prof_curve = findobj('parent',h_axes(ii_fn),'type','line','tag','profile');
        prof_data_x = get(prof_curve,'xdata');
        prof_data_y = get(prof_curve,'ydata');
        foo = get(h_axes(ii_fn),'xlim');
        xmin=foo(1);
        foo = get(h_axes(ii_fn),'ylim');
        ymin = foo(2);
        for ii_flag=1:4  % Iterate through the plot levels
            % Get the QC flag indices
            if size(prof_data_qc{ii_fn},2)>2 && strcmp(plot_labels{ii_fn}(1,1:4),'dens')
                ok_x=find(char(max(prof_data_qc{ii_fn}(:,1:end-1),[],2))==num2str(ii_flag));
            else ok_x=find(prof_data_qc{ii_fn}(:,1)==num2str(ii_flag));
            end
            ok_y=find(prof_data_qc{ii_fn}(:,end)==num2str(ii_flag));
            h_temp_x = findobj('parent',h_axes(ii_fn),'tag',['x' num2str(ii_flag)]);
            h_temp_y = findobj('parent',h_axes(ii_fn),'tag',['y' num2str(ii_flag)]);
            if indxy==2
                set(h_temp_x, 'xdata', prof_data_x(ok_y), 'ydata', prof_data_y(ok_y));
                set(h_temp_y, 'xdata', prof_data_x(ok_x), 'ydata', ones(1,length(ok_x))*ymin);
            else
                set(h_temp_x, 'xdata', prof_data_x(ok_x), 'ydata', prof_data_y(ok_x));
                set(h_temp_y, 'xdata', ones(1,length(ok_y))*xmin, 'ydata', prof_data_y(ok_y));
            end
                
        end
    end
end   


