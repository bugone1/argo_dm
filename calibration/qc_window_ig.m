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
but=1;     % Prepare to initialize the figure
indxy=1;   % We assume that we're doing QC on the x-variable

% Clear the figure
gui_fig = clf;

% TODO: Temporarily just adding an extra subplot to ensure enough room for
% the label, but I don't much like this; fix soon.
h_axes = zeros(1,n_plots);
h_qc_flags = cell(1,n_plots);
for ii_plot = 1:n_plots
    [h_axes(ii_plot),h_qc_flags{ii_plot}] = qc_window_plots_ig(prof_data{ii_plot},...
        S{ii_plot},prof_data_qc{ii_plot},plot_labels{ii_plot},title_string, platform_string, ...
        station_string, [1, length(plot_labels)+1, ii_plot]);
end

% Add the GUI elements
% TODO: The following positions are all quite quick-and-dirty; need to
% clean up to allow for varying window size.
% Get the right edge of the right-most plot
foo = get(h_axes(end),'position');
x0_gui = foo(1)+foo(3)*1.03;
y0_gui = foo(2)+foo(4);
y_cur=y0_gui-0.04;
% Select individual points
flag_button = uicontrol('parent',gui_fig,'style','pushbutton','string','Flag points (q to stop)', ...
    'units','normalized', 'position', [x0_gui,y_cur,0.1,0.03], 'callback', @flag_points);
y_cur=y_cur-0.04;
% Select polygon
flag_button_poly = uicontrol('parent',gui_fig,'style','pushbutton','string','Flag points by polygon', ...
    'units','normalized', 'position', [x0_gui,y_cur,0.1,0.03], 'callback', @flag_points_poly);
y_cur=y_cur-0.05;
% Toggle flags for the entire profile
tog_flag_bg = uibuttongroup('position',[x0_gui,y_cur,0.09,0.04], ...
    'title','Flag all to #', 'SelectionChangeFcn',@toggle_profile_flags);
for ii=1:4
    uicontrol(tog_flag_bg,'style','radiobutton','string',num2str(ii),...
        'units','normalized','position',[(ii-1)*0.25,0,0.25,1]);
end
set(tog_flag_bg,'selectedobject','');
flag_allplots_checkbox = uicontrol('parent',gui_fig,'style','checkbox','string','Apply to all plots', ...
    'units','normalized','position',[x0_gui+0.11,y_cur,0.1,0.03]);
y_cur=y_cur-0.04;
% Swap flags 1 and 4
swap_but = uicontrol('Parent',gui_fig,'Style','pushbutton', 'String', 'Invert 1 to 4 and 4 to 1', ...
    'Units', 'normalized', 'Position', [x0_gui,y_cur,0.1,0.03], ...
    'callback', @swap_flags_1_and_4);
y_cur=y_cur-0.05;
% Select axes to select on
tog_ax_bg = uibuttongroup('position',[x0_gui,y_cur,0.08,0.04], ...
    'title', 'Axes to flag', 'SelectionChangeFcn', @toggle_select_axes);
uicontrol(tog_ax_bg,'style','radiobutton','string','x','units','normalized','position',[0,0,0.5,1]);
uicontrol(tog_ax_bg,'style','radiobutton','string','y','units','normalized','position',[0.5,0,0.5,1])
y_cur=y_cur-0.11;
% Skip button group
skip_bg = uibuttongroup('position',[x0_gui,y_cur,0.18,0.1], ...
    'title', 'Skip to another profile');
skip_to_next_button = uicontrol(skip_bg,'Style','pushbutton','String','Next profile', ...
    'Units','normalized', 'Position',[0,0.5,0.5,0.4], 'callback', @update_but_and_resume);
skip_to_prev_button = uicontrol(skip_bg,'Style','pushbutton','String','Previous profile', ...
    'Units','normalized', 'Position',[0.5,0.5,0.5,0.4], 'callback', @update_but_and_resume);
skip_to_flagged_button = uicontrol(skip_bg,'Style','pushbutton','String','Next profile with flag>1', ...
    'Units','normalized', 'Position',[0,0,0.75,0.4], 'callback', @update_but_and_resume);
skip_button = uicontrol(skip_bg,'Style','pushbutton','String','End', 'Units','normalized',...
    'Position',[0.75,0,0.25,0.4], 'callback', @update_but_and_resume);
% Quit visual QC, either saving progress or not
y_cur=y_cur-0.04;
quit_button = uicontrol('parent',gui_fig,'string','Quit visual QC', ...
    'units','normalized', 'position',[x0_gui,y_cur,0.08,0.03], ...
    'callback', @update_but_and_resume);
% TODO: This doesn't currently work, will need to put it back later
% % Figure keypress callback
% set(gui_fig,'KeyPressFcn', @qc_window_keypress);
% Restore the figure toolbar
set(gui_fig,'toolbar','figure');

% Wait for user input
uiwait(gui_fig);

% Make sure the QC matrix contains only chars
for ii_plot=1:length(plot_labels)
    prof_data_qc{ii_plot}=char(prof_data_qc{ii_plot});
end

% GUI functions. We nest them here so they can access the main function
% variables

    % Flag individual points by clicking
    function flag_points(hObject, event, handles)
        but_ptsel=1;
        while but_ptsel~='q'
            [xi,yi,but_ptsel]=ginput(1);
            % Find the closest point to where the user clicked
            % (Pythagoras). Note that ginput automatically changes the
            % current axis.
            if but_ptsel~='q'
                ii_plot_fn = find(h_axes==gca);
                if strcmp(plot_labels{ii_plot_fn}(1,1:4),'dens'), warning('Cannot select points from the density plot'); 
                else
                    pdif=(prof_data{ii_plot_fn}(:,1)-xi)/diff(get(gca,'xlim')); 
                    idif=(prof_data{ii_plot_fn}(:,2)-yi)/diff(get(gca,'ylim'));
                    [tr,i]=min(pdif.^2+idif.^2);
                    if but==1
                        if prof_data_qc{ii_plot_fn}(i,indxy)=='1'
                            prof_data_qc{ii_plot_fn}(i,indxy)='4';
                        elseif prof_data_qc{ii_plot_fn}(i,indxy)=='4'
                            prof_data_qc{ii_plot_fn}(i,indxy)='3';
                        elseif prof_data_qc{ii_plot_fn}(i,indxy)=='3'
                            prof_data_qc{ii_plot_fn}(i,indxy)='1';
                        end
                    elseif but==3
                        prof_data_qc{ii_plot_fn}(i,indxy)='1';
                    end
                    update_related_profiles(ii_plot_fn);
                    update_qc_flag_curves;
                end
            end
        end
    end

    % Flag points by polygon
    % TODO: I would like to make this a bit clearer
    function flag_points_poly(hObject, event, handles)
        [xy1,xy2,fla]=ginput(4);
        xy=[xy1 xy2];
        fla=fla(end);
        if fla > 1, fla = fla+1; end
        if fla>=0 && fla<5, fla=char(fla+'0'); end
        ii_plot_fn = find(h_axes==gca);
        if strcmp(plot_labels{ii_plot_fn}(1,1:4),'dens'), warning('Cannot select points from the density plot'); 
        else
            xlims = minmax(xy(:,1));
            ylims = minmax(xy(:,2));
            ok1=inpolygon(prof_data{ii_plot_fn}(:,1),prof_data{ii_plot_fn}(:,2),...
                [xlims, fliplr(xlims)], [ylims(1),ylims(1),ylims(2),ylims(2)]);
    %             minmax(xy(:,1)),minmax(xy(:,2)));
            prof_data_qc{ii_plot_fn}(ok1,indxy)=char(fla);
            update_related_profiles(ii_plot_fn);
            update_qc_flag_curves;
        end
    end

    % Toggle profile flags
    function toggle_profile_flags(hObject, event, handles)
        new_flag = get(event.NewValue,'string');
        if get(flag_allplots_checkbox,'value')==1
            ii_plot_fn = 1:length(h_axes);
        else ii_plot_fn = find(h_axes==gca);
        end
        if isempty(ii_plot_fn), warning('Please select a plot first'); 
        elseif length(ii_plot_fn)==1 && strcmp(plot_labels{ii_plot_fn}(1,1:4),'dens')
            warning('Cannot select points from the density plot'); 
        end
        for ii_fn=1:length(ii_plot_fn)
            if strcmp(plot_labels{ii_plot_fn}(1,1:4),'dens'), continue; end
            prof_data_qc{ii_plot_fn(ii_fn)}(:,indxy) = new_flag;
            update_related_profiles(ii_plot_fn(ii_fn));
            update_qc_flag_curves;
        end
        % Reset control for later reuse
        set(tog_flag_bg,'selectedobject','');
        
    end

    % Switch between QC flags 1 and 4
    function swap_flags_1_and_4(hObject, event, handles)
        ii_plot_fn = find(h_axes==gca);
        if isempty(ii_plot_fn), warning('Please select a plot first'); 
        elseif strcmp(plot_labels{ii_plot_fn}{1},'dens')
            warning('Cannot select points from the density plot'); 
        else
            ok1=prof_data_qc{ii_plot_fn}(:,indxy)=='4';
            ok2=prof_data_qc{ii_plot_fn}(:,indxy)=='1';
            prof_data_qc{ii_plot_fn}(ok1,indxy)='1';
            prof_data_qc{ii_plot_fn}(ok2,indxy)='4';
            update_related_profiles(ii_plot_fn);
            update_qc_flag_curves;
        end
    end

    % Toggle axes for selection
    function toggle_select_axes(hObject, event, handles)
        new_ax = get(event.NewValue,'string');
        indxy=new_ax-'w';  % FIXME: Continue from here
        [xflags,yflags]=deal('');
        if indxy==1
            xflags=' - flags from this axis currently shown';
        else
            yflags=' - flags from this axis currently shown';
        end
        for ii_ax=1:n_plots
            ylabel(h_axes(ii_ax), [plot_labels{ii_ax}(2,:) yflags]);
            xlabel(h_axes(ii_ax), [plot_labels{ii_ax}(1,:) xflags]);
        end
        update_qc_flag_curves;
    end

    % Update the 'but' variable used by the parent routines and resume
    % (thus causing the function to return to its caller)
    function update_but_and_resume(hObject,event,handles)
        switch hObject
            case skip_to_next_button, but=' ';
            case skip_to_prev_button, but=8;  % This is the backspace character
            case skip_button, but='q';
            case skip_to_flagged_button, but='s';
            case quit_button, but='Q';
        end
        uiresume(gui_fig);
    end

    % Keypress handler
    % TODO: What else do we want to add here? Do I want all the original
    % keystrokes?
    % FIXME: I can't use this when some figure options are open
    function qc_window_keypress(hObject, event, handles)
        if event.Character==' ' || event.Character==8
            but = event.Character;
        end
    end

    % Update profiles with the same variable as the current axes
    function update_related_profiles(ii_plot_origin)
        var_to_update = deblank(plot_labels{ii_plot_origin}(indxy,:));
        for ii_plot_fn = 1:length(h_axes)
            if ii_plot_fn == ii_plot_origin, continue;
            else
                for ii_ax=1:2
                    var_dest = deblank(plot_labels{ii_plot_fn}(ii_ax,:));
                    if strcmp(var_dest,var_to_update)
                        prof_data_qc{ii_plot_fn}(:,ii_ax) = prof_data_qc{ii_plot_origin}(:,indxy);
                    elseif strcmp(var_dest,'dens') && ismember(var_to_update,{'pres','temp','psal'})
                        prof_data_qc{ii_plot_fn}(:,strcmp(var_to_update,{'pres','temp','psal'})) = prof_data_qc{ii_plot_origin}(:,indxy);
                    end
                end
            end
        end
    end

    % Function to update the QC flag plots. Again, nested to avoid
    % storing/passing more variables
    function update_qc_flag_curves(ii_plots_all)
        if nargin<1, ii_plots_all=1:n_plots; end
        for ii_fn=1:length(ii_plots_all)
            for ii_flag=1:length(h_qc_flags{ii_plots_all(ii_fn)})
                if size(h_qc_flags{ii_plots_all(ii_fn)},2)>2 && strcmp(plot_labels{ii_fn}(1,1:4),'dens')
                    if indxy==1
                        ok=char(max(prof_data_qc{ii_plots_all(ii_fn)}(:,1:end-1),[],2))==num2str(ii_flag);
                    else
                        ok=prof_data_qc{ii_plots_all(ii_fn)}(:,end)==num2str(ii_flag);
                    end
                else
                    ok=prof_data_qc{ii_plots_all(ii_fn)}(:,indxy)==num2str(ii_flag);
                end
                set(h_qc_flags{ii_plots_all(ii_fn)}{ii_flag},...
                    'xdata', prof_data{ii_plots_all(ii_fn)}(ok,1), ...
                    'ydata', prof_data{ii_plots_all(ii_fn)}(ok,2));
            end
        end
    end   

end


