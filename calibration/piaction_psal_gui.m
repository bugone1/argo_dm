function [CellK,slope,offset,start,ende,psalflag,adjpsalflag]=piaction_psal_gui(profile_no,condslope,oldcoeff)
    % PIACTION_PSAL_gui Select a salinity adjustment based on OW output; GUI
    % version

    % Parameters
    fig_position = [100,100,1000,600];
    ui_position = [0.8 0 0.22 1];
    but_width =190;
    but_height=20;
    x0_gui=5;
    piaction_file = 'piaction'; % TODO: This really should have a full path...
    
    % Make sure we have only one piaction GUI window open
    close(findobj('tag','piaction_fig'));

    % Set up a GUI window. Note that to deal kind-of-reasonably with
    % resizing I'm starting from the layout in terms of the button
    % positions
    gui_fig = figure('units','pixels','position',fig_position);
    set(gui_fig,'tag','piaction_fig');
    h_ui_plot = uipanel('tag','ax_panel','position',[0,0,ui_position(1),1]);
    h_ax=subplot(1,1,1,'parent',h_ui_plot,'tag','h_ax');
    h_ui = uipanel('tag','gui_panel','Position',ui_position);
    y_cur = but_height;
    % Hint texts
    uicontrol('parent',h_ui,'style','text','string','Left-click points to add, right-click when done',...
        'Units','pixels','position',[x0_gui,y_cur,but_width,but_height*1.5],'backgroundcolor','y',...
        'visible','off','tag','h_select_hint');
    uicontrol('parent',h_ui,'style','text','string','Click the start and end cycles',...
        'Units','pixels','position',[x0_gui,y_cur,but_width,but_height],'backgroundcolor','y',...
        'visible','off','tag','h_poly_hint');
    y_cur=y_cur+but_height*2;
    % Quit without doing anything
    uicontrol('parent',h_ui,'style','pushbutton','string','Quit without correcting', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @quit_correction);
    y_cur=y_cur+but_height*1.5;
    % Finalize the correction
    uicontrol('parent',h_ui,'style','pushbutton','string','Accept and continue', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', 'uiresume(gcf)');
    y_cur=y_cur+but_height*1.5;
    % Escape to the keyboard
    uicontrol('parent',h_ui,'style','pushbutton','string','Edit at the keyboard', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @pi_edit);
    y_cur=y_cur+but_height*1.5;
    % QC flags
    qc_flag_bg = uibuttongroup('parent',h_ui,'tag','qc_flag_bg', ...
        'units','pixels','position',[x0_gui,y_cur,but_width,but_height*3], ...
        'title','Edit QC flags');%, 'SelectionChangeFcn',@flag_whole_profile);
    uicontrol(qc_flag_bg,'style','popupmenu','string',{'0','1','2','3','4'},...
        'units','pixels','position',[x0_gui,but_height*1.2,but_width/4,but_height],'tag','qc_flag_select');
    uicontrol(qc_flag_bg,'style','pushbutton','string','Select points...',...
        'units','pixels','position',[x0_gui*2+but_width/4,but_height*1.2,but_width*0.75-x0_gui*3,but_height],...
        'callback',@select_qc_flag);
    uicontrol(qc_flag_bg,'style','checkbox','tag','qc_raw_checkbox', 'string','Raw', ...
        'units','pixels','position',[x0_gui,x0_gui/2,but_width/3,but_height]);
    uicontrol(qc_flag_bg,'style','checkbox','tag','qc_adj_checkbox', 'string','Adjusted', ...
        'units','pixels','position',[but_width/3,x0_gui/2, but_width/2-x0_gui,but_height]);
    y_cur=y_cur+but_height*3.5;
     % Clear the curve points and start over
    uicontrol('parent',h_ui,'style','pushbutton','string','Clear all points', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @clear_fitline);
    y_cur=y_cur+but_height*1.5;
    % Load the current piaction file
    uicontrol('parent',h_ui,'style','pushbutton','string','Load piaction file', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @load_piaction);
    y_cur=y_cur+but_height*1.5;
    % Accept old coefficients
    uicontrol('parent',h_ui,'style','pushbutton','string','Set points to old coefficients', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @set_to_oldcoeffs);
    y_cur=y_cur+but_height*1.5;
    % Accept climatology
    uicontrol('parent',h_ui,'style','pushbutton','string','Set points to OW output', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @set_to_ow);
    y_cur=y_cur+but_height*1.5;
     % Set r=1
    uicontrol('parent',h_ui,'style','pushbutton','string','Set points to 1', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @set_to_one);
    y_cur=y_cur+but_height*1.5;
     % Delete points
    uicontrol('parent',h_ui,'style','pushbutton','string','Delete points', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @delete_points);
    y_cur=y_cur+but_height*1.5;    
    % Select points
    uicontrol('parent',h_ui,'style','pushbutton','string','Add points', ...
        'units','pixels', 'position', [x0_gui,y_cur,but_width,but_height], 'callback', @add_points);
    
    % Store the profile numbers and the location of the piaction file
    setappdata(gui_fig,'profile_no',profile_no);
    setappdata(gui_fig,'piaction_file',piaction_file);
    setappdata(gui_fig,'condslope',condslope);
    
    % Force the incoming condslope to the range of 0.85-1.15, ensure that
    % the profile numbers, conductivity slope, and old ocefficients are all
    % doubles
    condslope(isnan(condslope(:)) | condslope(:)>1.15 | condslope(:)<.85)=nan;
    profile_no=double(profile_no);
    condslope=double(condslope);
    oldcoeff=double(oldcoeff);
    
    % Initialize and store the salinity flags
    psalflag=ones(size(profile_no));
    psalflag(isnan(condslope))=4;
    adjpsalflag=psalflag;
    setappdata(gui_fig,'psalflag',psalflag);
    setappdata(gui_fig,'adjpsalflag',adjpsalflag);

%     % Get the fitted conductivity from the last portion of the incoming
%     % series
%     if length(condslope)>20
%         condfit=condslope(end-20:end);
%         profit=profile_no(end-20:end);
%     else
%         condfit=condslope;
%         profit=profile_no;
%     end
%     cond_ok=~isnan(condfit);
%     p=polyfit(profit(cond_ok),condfit(cond_ok),1);
%     if sum(abs(p))==0
%         condcalc=(profit*0)+1;
%     else
%         condcalc=p(1)*profit+p(2);
%     end
    
    % Prepare the plot
    h_oldcoeff = plot(profile_no,oldcoeff,'r.', 'tag', 'h_oldcoeff');
    %h_ow = plot(profit(cond_ok),condfit(cond_ok),'r+', 'tag', 'h_ow'); %Red crosses are condfit values between .5 and 1.5
    h_ow = plot(profile_no,condslope,'-bo', 'tag','h_ow');
    %h_fitted = plot(profit,condcalc,'gs','tag','h_fitted'); %green squares are calculated values according to fit
    h_fitline = plot([profile_no(1),profile_no(end)],[1,1],'- o g','Linewidth',4,'tag','h_fitline');
    h_qc = scatter(profile_no,ones(size(profile_no))*min(get(gca,'ylim')),30,max([psalflag;adjpsalflag]),'filled','tag','h_qc');
    colormap([0.5,0.5,0.5;0,0,1;1,1,0;1,0,1;1,0,0]); caxis([0 4]);
    xlabel('Profile Number');
    ylabel('Conductivity Slope Correction');
    set(gca,'xlim',[min(profile_no)-1 max(profile_no)+1]);
    grid on
    legend('Old coefficients (h\_old\_coeff)','OW (h\_ow)','Current correction (h\_fitline)','QC flags (h\_qc)');
    
    % Block execution so the user can interact with the figure
    uiwait(gui_fig);
    
    % Post-process the results
    x_all = get(h_fitline,'xdata');
    y_all = get(h_fitline,'ydata');
    % If we've left these to NaN then we're exiting without doing anything
    % at all
    if length(x_all)==1 && isnan(x_all)
        % TODO: This isn't done yet, and will currently cause an error
        [CellK,slope,offset,start,ende,psalflag,adjpsalflag]=deal(NaN);
        return
    end
    p1=diff(y_all)./diff(x_all);
    p2=y_all(1:end-1)-x_all(1:end-1).*p1;
    v=struct();
    for ii=1:length(x_all)-1
        ok=find(profile_no>=x_all(ii) & profile_no<=x_all(ii+1));
        profit=profile_no(ok);
        condcalc=p1(ii)*profit+p2(ii);
        sigma_err_all(ii)=nansum(sqrt((condcalc-condslope(ok)).^2));
        v(ii).condcalc=condcalc;
        v(ii).start=x_all(ii);
        if ii==length(x_all)-1
            v(ii).end=profit(end);
        else
            v(ii).end=profit(end)-1;
        end
        v(ii).slope=p1(ii);
        v(ii).offset=p2(ii);
        v(ii).err=sigma_err_all(ii);
        v(ii).prof=profit;
        v(ii).ok=ok;
    end
    sprintf('Fit is from %i to %i with maximum error of %f',[min([v.start]) max([v.end]) max([v.err])])
    for j=1:length(v) %rearrange slope information in rows / columns
        [tr,oki,okb]=intersect(profile_no,v(j).prof);
        CellK(oki)=v(j).condcalc(okb);    slope(oki)=v(j).slope;    offset(oki)=v(j).offset;    start(oki)=v(j).start;    ende(oki)=v(j).end;
    end
    CellK=round(CellK*1e8)/1e8;
    set(h_fitline,'xdata',profile_no,'ydata',CellK);
    
    % Finalize QC flags
    psalflag=getappdata(gui_fig,'psalflag');
    adjpsalflag=getappdata(gui_fig,'adjpsalflag');
    psalflag(isnan(CellK))='4';
    adjpsalflag(isnan(CellK))='4';
    set(h_qc,'cdata',max([psalflag; adjpsalflag]));
    % Convert the flags to chars
    psalflag=num2str(psalflag,'%d');
    adjpsalflag=num2str(adjpsalflag,'%d');
end

function add_points(hObject, event, handles)

    % Get the current curve and hint text
    h_fitline = findobj('tag','h_fitline');
    x_all = get(h_fitline,'xdata');
    y_all = get(h_fitline,'ydata');
    if length(x_all)==1 && isnan(x_all)
        x_all = [];
        y_all = [];
    end
    h_select_hint = findobj('tag','h_select_hint');
    
    % Make the hint text visible
    set(h_select_hint,'visible','on');

    but_ptsel=1;
    while but_ptsel ~= 3
        [x_temp,y_temp,but_ptsel]=ginput(1);
        if but_ptsel==1
            x_all=[x_all round(x_temp)];
            y_all=[y_all y_temp];
            [x_all,ii]=sort(x_all);
            y_all=y_all(ii);
            set(h_fitline,'xdata',x_all,'ydata',y_all);
        end
    end
    set(h_select_hint,'visible','off');
    
    % Final update on the line
    update_fitline(x_all,y_all)
end

function delete_points(hObject, event, handles)

    % Get the current fit curve
    h_fitline = findobj('tag','h_fitline');
    x_all = get(h_fitline,'xdata');
    y_all = get(h_fitline,'ydata');
    
    % Get the range of points to  delete
    x_sel = select_cycle_range;
    
    % Delete the points within the range
    ii_temp = find(x_all >= x_sel(1) & x_all <=x_sel(2));
    x_all(ii_temp)=[];
    y_all(ii_temp)=[];
    %set(h_fitline,'xdata',x_all,'ydata',y_all);
    
    % Update the line
    update_fitline(x_all,y_all)
end

function set_to_one(hObject, event, handles)

    % Get the fitline and profile numbers
    h_fitline = findobj('tag','h_fitline');
    profile_no = getappdata(gcf,'profile_no');

    % Get the range of points to update
    x_sel = select_cycle_range;
    x_fit = get(h_fitline,'xdata');
    y_fit = get(h_fitline,'ydata');
    ii_p1 = find(x_fit<x_sel(1));
    ii_p2 = find(profile_no>=x_sel(1) & profile_no<=x_sel(2));
    ii_p3 = find(x_fit>x_sel(2));
    
    % Update the line
    x_all = [x_fit(ii_p1), profile_no(ii_p2), x_fit(ii_p3)];
    y_all = [y_fit(ii_p1), ones(1,length(ii_p2)), y_fit(ii_p3)];
    set(h_fitline,'xdata',x_all,'ydata',y_all);
    
end

function set_to_ow(hObject,event,handles)

    % Get the fitline, profile numbers, and OW curve
    h_fitline = findobj('tag','h_fitline');
    h_ow = findobj('tag','h_ow');

    % Get the range of points to update
    x_sel = select_cycle_range; 
    x_fit = get(h_fitline,'xdata');
    y_fit = get(h_fitline,'ydata');
    x_ow = get(h_ow,'xdata');
    y_ow = get(h_ow,'ydata');
    ii_p1 = find(x_fit<x_sel(1));
    ii_p2 = find(x_ow>=x_sel(1) & x_ow<=x_sel(2));
    ii_p3 = find(x_fit>x_sel(2));

    % Update the line
    x_all = [x_fit(ii_p1), x_ow(ii_p2), x_fit(ii_p3)];
    y_all = [y_fit(ii_p1), y_ow(ii_p2), y_fit(ii_p3)];
    set(h_fitline,'xdata',x_all,'ydata',y_all);
end

function set_to_oldcoeffs(hObject,event,handles)

    % Get the fitline, profile numbers, and old coefficients
    h_fitline = findobj('tag','h_fitline');
    h_oldcoeff = findobj('tag','h_oldcoeff');

    % Get the range of points to update
    x_sel = select_cycle_range;
    x_fit = get(h_fitline,'xdata');
    y_fit = get(h_fitline,'ydata');
    x_old = get(h_oldcoeff,'xdata');
    y_old = get(h_oldcoeff,'ydata');
    ii_p1 = find(x_fit<x_sel(1));
    ii_p2 = find(x_old>=x_sel(1) & x_old<=x_sel(2));
    ii_p3 = find(x_fit>x_sel(2));

    % Update the line
    x_all = [x_fit(ii_p1), x_old(ii_p2), x_fit(ii_p3)];
    y_all = [y_fit(ii_p1), y_old(ii_p2), y_fit(ii_p3)];
    set(h_fitline,'xdata',x_all,'ydata',y_all);
end

function load_piaction(hObject,event,handles)

    % Load the file
    piaction_data = load(getappdata(gcf,'piaction_file'));
    psalflag = str2double(cellstr(piaction_data.psalflag'))';
    adjpsalflag = str2double(cellstr(piaction_data.adjpsalflag'))';
    
    % Set the curves
    x_prof=getappdata(gcf,'profile_no');
    set(findobj('tag','h_fitline'),'xdata',x_prof,'ydata',piaction_data.CellK);
    set(findobj('tag','h_qc'),'xdata',x_prof,'cdata',max([psalflag; adjpsalflag]));
    
    % Store the QC flags
    setappdata(gcf,'psalflag',psalflag);
    setappdata(gcf,'adjpsalflag',adjpsalflag);
end

function clear_fitline(hObject,event,handles)
    set(findobj('tag','h_fitline'),'xdata',NaN,'ydata',NaN);
end

function pi_edit(hObject,event,handles)
    disp('Update the curve by editing the line xdata and ydata');
    keyboard
end

function select_qc_flag(hObject,event,handles)

    % Get the QC curve and QC flags, as well as the checkbox handles
    h_qc = findobj('tag','h_qc');
    psalflag = getappdata(gcf,'psalflag');
    adjpsalflag = getappdata(gcf,'adjpsalflag');
    qc_raw_checkbox = findobj('tag','qc_raw_checkbox');
    qc_adj_checkbox = findobj('tag','qc_adj_checkbox');
    
    % Get the target flag
    h_sel = findobj('tag','qc_flag_select');
    foo = get(h_sel,'string');
    qc = str2double(foo{get(h_sel,'value')});

    % Get the range of points to update
    x_sel = select_cycle_range;
    x_qc = get(h_qc,'xdata');
    x_ii = find(x_qc>=x_sel(1) & x_qc<=x_sel(2));
    
    % Update the psalflag vectors  
    c_qc = get(h_qc,'cdata');
    if get(qc_raw_checkbox,'value')==1
        psalflag(x_ii)=qc;
    end
    if get(qc_adj_checkbox,'value')==1
        adjpsalflag(x_ii)=qc;
    end
    
    % Update the curve and application data
    setappdata(gcf,'psalflag',psalflag);
    setappdata(gcf,'adjpsalflag',adjpsalflag);
    set(h_qc,'cdata',max([psalflag; adjpsalflag]));
end

function quit_correction(hObject,event,handles)
    % Set the fitline to NaNs and resume the GUI
    set(findobj('tag','h_fitline'),'xdata',NaN,'ydata',NaN);
    uiresume(gcf);
end

function x_sel = select_cycle_range

    % Display the range selection hint
    h_poly_hint = findobj('tag','h_poly_hint');
    set(h_poly_hint,'visible','on');
    
    % Select the range of points to update
    [x_sel,foo]=ginput(2);
    x_sel = sort(x_sel);
    
    % Hide the hint
    set(h_poly_hint,'visible','off');
end

function update_fitline(x_all,y_all)

    profile_no = getappdata(gcf,'profile_no');
    condslope = getappdata(gcf,'condslope');

    % Update the fitline and informational text. Note that corrected
    % conductivity is not exactly the line as shown, but rather
    % CONDraw*(offset+slope*PROFILE_NO). These two should be the same, but
    % we convert here just to be safe and/or thorough
    p1=diff(y_all)./diff(x_all);
    p2=y_all(1:end-1)-x_all(1:end-1).*p1;
    tit_str={};
    fitligne_x=zeros(1,length(x_all));
    fitligne_y=zeros(1,length(x_all));
    profit_all=[];
    condcalc_all=[];
    sigma_err_all=zeros(1,length(x_all)-1);
    for ii=1:length(x_all)-1
        ok=find(profile_no>=x_all(ii) & profile_no<=x_all(ii+1));
        profit=profile_no(ok);
        condcalc=p1(ii)*profit+p2(ii);
        % FIXME: What should condslope be at this point?
        sigma_err_all(ii)=nansum(sqrt((condcalc-condslope(ok)).^2));
        tit_str{ii}=['From ' num2str(x_all(ii)) ' to ' num2str(profit(end)) '; m=' num2str(p1(ii)) ' b=' num2str(p2(ii)) '; RMS err=' num2str(sigma_err_all(ii))];
        fitligne_x(ii:ii+1)=profit([1 end]);
        fitligne_y(ii:ii+1)=p2(ii)+p1(ii)*profit([1 end]);
        profit_all=[profit_all,profit];
        condcalc_all=[condcalc_all,condcalc];
    end
    
    set(findobj('tag','h_fitline'),'xdata',fitligne_x,'ydata',fitligne_y);
    set(findobj('tag','h_fitted'),'xdata',profit_all,'ydata',condcalc_all,'visible','on');
end