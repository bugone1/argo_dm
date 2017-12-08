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
%       Jun.-Aug. 2017, IG: Fairly heavy rework, customising the overall
%           visual QC process.


% Configuration
ui_position = [0.8 0 0.19 1];
x0_gui=0.01;
y0_gui=1.0;
but_width =0.5;
but_height=0.03;
stretch_factor=[1.1,1.1]; % Matlab leaves a lot of space around subplots, so we tighten them up a bit

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

n_doxy=0;
for ii=1:n_plots
    if strfind(plot_labels{ii}(1,:),'doxy')
        n_doxy=n_doxy+1;
    end
end
if n_doxy > 0, subplot_layout = [2, max(n_doxy,n_plots-n_doxy)];
else subplot_layout = [1,n_plots];
end

% Update the application data to be used by the callbacks
setappdata(gui_fig,'but',1);
setappdata(gui_fig,'indxy',1);  % We assume that we're doing QC on the x-variable
setappdata(gui_fig,'plot_labels',plot_labels);
setappdata(gui_fig,'prof_data_qc',prof_data_qc);

if isempty(findobj('parent',gui_fig,'type','uipanel','tag','ax_panel'))
    h_ui_plots = uipanel('tag','ax_panel','position',[0,0,ui_position(1),1]);
else
    h_ui_plots = findobj('parent',gui_fig,'type','uipanel','tag','ax_panel');
end
ii_plot_core=0;
ii_plot_doxy=0;
for ii_plot = 1:n_plots
    if strfind(plot_labels{ii_plot}(1,:),'doxy')
        ii_plot_doxy=ii_plot_doxy+1;
        ii_plot_cur=subplot_layout(2)+ii_plot_doxy;
    else
        ii_plot_core=ii_plot_core+1;
        ii_plot_cur=ii_plot_core;
    end
    h_axes(ii_plot) = qc_window_plots_ig(prof_data{ii_plot}, S{ii_plot},prof_data_qc{ii_plot},...
        plot_labels{ii_plot},title_string, platform_string, station_string, ...
        [subplot_layout(1), subplot_layout(2), ii_plot_cur], h_ui_plots);
    pos_temp=get(h_axes(ii_plot),'position');
    pos_temp = [pos_temp(1) pos_temp(2)-pos_temp(4)*(stretch_factor(2)-1)/2 pos_temp(3)*stretch_factor(1) pos_temp(4)*stretch_factor(2)];
    set(h_axes(ii_plot),'position',pos_temp);
end
% Store the list of axes for later use. We could count on the fact that the
% handles are always in order, but this seems safer
setappdata(gui_fig,'h_axes',h_axes);
% Start with axes linked
linkaxes(h_axes(1:end-1),'y');

% Add the GUI elements
if isempty(findobj('parent',gui_fig,'type','uipanel','tag','gui_panel'))
    h_ui = uipanel('tag','gui_panel','Position',ui_position);
    y_cur=y0_gui-0.04;
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
    uicontrol('parent',h_ui,'style','checkbox','tag','flag_allplots_checkbox', 'string','Apply to all plots', ...
        'units','normalized','position',[x0_gui+but_width+0.01,y_cur+but_height*.75,1-but_width-2*x0_gui,but_height*0.75],...
        'callback',@store_check_status);
    uicontrol('parent',h_ui,'style','checkbox','tag','flag_bothaxes_checkbox', 'string','Apply to both axes', ...
        'units','normalized','position',[x0_gui+but_width+0.01,y_cur,1-but_width-2*x0_gui,but_height*0.75],...
        'callback',@store_check_status);
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
    % Option to link the axes. This is useful when looking at variables
    % together, but slows down drawing considerably.
    y_cur=y_cur-0.04;
    uicontrol(h_ui,'style','checkbox','tag','link_axes_checkbox','string','Link axis y-extents',...
        'units','normalized','position',[x0_gui,y_cur,but_width,but_height],...
        'callback',@toggle_link_axes);
    y_cur=y_cur-but_height*4;
    % Skip button group
    skip_bg = uibuttongroup('parent',h_ui,'position',[x0_gui,y_cur,but_width*2,but_height*4],...%0.18,0.1], ...
        'title', 'Skip to another profile');
    uicontrol(skip_bg,'Style','pushbutton','String','Next profile', ...
        'Units','normalized', 'Position',[0,0.67,0.5,0.28], 'tag', 'skip_to_next_button', ...
        'callback', @update_but_and_resume);
    uicontrol(skip_bg,'Style','pushbutton','tag','skip_to_prev_button','String','Previous profile', ...
        'Units','normalized', 'Position',[0.5,0.67,0.5,0.28], 'callback', @update_but_and_resume);
    uicontrol(skip_bg,'Style','pushbutton','tag','skip_to_flagged_button','String','Next profile with flag>1', ...
        'Units','normalized', 'Position',[0,0.33,0.75,0.28], 'callback', @update_but_and_resume);
    uicontrol(skip_bg,'Style','pushbutton','tag','skip_button','String','End', 'Units','normalized',...
        'Position',[0.75,0.33,0.25,0.28], 'callback', @update_but_and_resume);
    uicontrol(skip_bg,'style','text','string','Cycle number','units','normalized',...
        'position',[0,0,0.3,0.28],'horizontalalignment','left');
    uicontrol(skip_bg,'style','edit','tag','skip_to_cycle_field','units','normalized',...
        'position',[0.3,0,0.3,0.28]);
    uicontrol(skip_bg,'style','pushbutton','tag','skip_to_cycle_button','String','Go',...
        'units','normalized','position',[0.6,0,0.3,0.28],'callback', @update_but_and_resume);
    % Escape to the keyboard
    y_cur=y_cur-0.04;
    uicontrol('parent',h_ui,'tag','keyboard_button','string','Escape to keyboard',...
        'units','normalized','position',[x0_gui,y_cur,but_width,but_height],...
        'callback','keyboard');
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
    foo = getappdata(gcf,'flag_allplots_checkbox_value');
    if isempty(foo), foo=0; end
    set(findobj('tag','flag_allplots_checkbox'),'value',foo);
    foo = getappdata(gcf,'flag_bothaxes_checkbox_value');
    if isempty(foo), foo=0; end
    set(findobj('tag','flag_bothaxes_checkbox'),'value',foo);
    set(findobj('tag','link_axes_checkbox'),'value',1);
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
                        prof_data_qc{ii_plot_fn}(i,indxy)='2';
                    elseif prof_data_qc{ii_plot_fn}(i,indxy)=='2'
                        prof_data_qc{ii_plot_fn}(i,indxy)='1';
                    end
                elseif but_ptsel==3
                    prof_data_qc{ii_plot_fn}(i,indxy)='1';
                end
                setappdata(gcf,'prof_data_qc',prof_data_qc);
                prof_data_qc=update_related_profiles(gca);
                update_qc_flag_curves(prof_data_qc);
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
        update_related_profiles(gca);
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
                update_related_profiles(h_axes(ii_plot_fn(ii_fn)));
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
%     [xflags,yflags]=deal('');
%     if indxy==1
%         xflags=' - flags shown';
%     else
%         yflags=' - flags shown';
%     end
    h_axes = getappdata(gcf,'h_axes');
    for ii_ax=1:length(h_axes)
        if indxy==1, 
            set(get(h_axes(ii_ax),'xlabel'),'fontweight','bold');
            set(get(h_axes(ii_ax),'ylabel'),'fontweight','normal');
        else
            set(get(h_axes(ii_ax),'xlabel'),'fontweight','normal');
            set(get(h_axes(ii_ax),'ylabel'),'fontweight','bold');
        end
%         foo = get(get(h_axes(ii_ax),'xlabel'),'string');
%         set(get(h_axes(ii_ax),'xlabel'), 'string', [foo(1:4) xflags]);
%         foo = get(get(h_axes(ii_ax),'ylabel'),'string');
%         set(get(h_axes(ii_ax),'ylabel'), 'string', [foo(1:4) yflags]);
    end
    update_qc_flag_curves;
end

% Toggle axis linking
function toggle_link_axes(hObject,event,handles)
    h_axes=getappdata(gcf,'h_axes');
    if get(findobj('tag','link_axes_checkbox'),'value')==1
        linkaxes(h_axes(1:end-1),'y');
    else
        linkaxes(h_axes(1:end-1),'off');
    end
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
        case 'skip_to_cycle_button'
            foo=get(findobj('tag','skip_to_cycle_field'),'string');
            if isempty(foo), return; 
            else but=['s' foo];
            end;
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

% Update profiles with the same variable as the current axes
function prof_data_qc=update_related_profiles(h_ax)
	h_axes = getappdata(gcf,'h_axes');
    ii_plot_origin = find(h_axes==h_ax);
    indxy = getappdata(gcf,'indxy');
    prof_data_qc=getappdata(gcf,'prof_data_qc');
    plot_labels = getappdata(gcf,'plot_labels');
    var_to_update = deblank(plot_labels{ii_plot_origin}(indxy,:));
    for ii_plot_fn = 1:length(getappdata(gcf,'h_axes'))
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
                end
            end
        end
    end
    setappdata(gcf,'prof_data_qc',prof_data_qc);
    if nargout < 1, clear prof_data_qc; end
end

% Function to update the QC flag plots
function update_qc_flag_curves(prof_data_qc)
    % Sometimes the application data aren't updated as fast as we'd like,
    % and it's more convenient to get the QC flags via arguments
    if nargin < 1, prof_data_qc = getappdata(gcf,'prof_data_qc'); end
    indxy = getappdata(gcf,'indxy');
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

% Store the status of the checkboxes
function store_check_status(hObject,event,handles)
    setappdata(gcf,[get(hObject,'tag') '_value'], get(hObject,'value'));
end

