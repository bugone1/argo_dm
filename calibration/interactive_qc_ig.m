function fname=interactive_qc_ig(local_config,files)
% INTERACTIVE_QC_IG Interactive QC of Argo files (Isabelle's version)
%   DESCRIPTION:
%       Overall handler for interactive QC of the Argo data. Prompt user
%       for information on the steps to be performed, load the data from an
%       existing .mat file and/or original .nc, and launch the interactive
%       QC window.
%   USAGE:
%      fname=interactive_qc_ig(local_config,files)
%   INPUTS:   
%       local_config - Structure with various configuration parameters,
%          e.g. paths
%       files - List of files to process. This is an nx1 or nx2 array of
%           structures of file data (as obtained from the dir command),
%           depending on whether or not b-files are present.
%   OUTPUTS:
%       fname - Filename with a structure "t" containing t&s data with
%           flags for all cycles for a given float
%   VERSION HISTORY:
%       26 May 2017, Isabelle Gaboury: Created, based on original version
%           dated 13 September 2016.
%       July, 2017, IG: KML files now being stored in the kml directory.

ITS90toIPTS68=1.00024;

floatname=files(1).name(2:8);
fname=[local_config.RAWFLAGSPRES_DIR floatname]; %presscorrect file
dire=[local_config.DATA findnameofsubdir(floatname,listdirs(local_config.DATA))];
clean(dire,files(:,1));
if size(files,2)>1, clean(dire,files(:,2),1); end

%Load working file if exists
t=[];
dokeep=[0 0];
if exist([fname '.mat'],'file')
    tem=load(fname);
    if isfield(tem,'t') %presscorrect file
        cyn1=cat(1,tem.t.cycle_number);
        fnames=char(files(:,1).name);
        cyn2=int32(str2num(fnames(:,10:12)));
        [a,b]=setdiff(cyn2,cyn1);
        t=tem.t;
        if ~isempty(b)
            t_new = read_all_nc(dire,files(b,1),[],[0 0]);
            if size(files,2)==2
                % Biogeochemical data
                cfields=fieldnames(t_new);
                t_b = read_all_nc(dire,files(b,2),[],[0 0],1);
                if ~isempty(t_b)
                    bfields=fieldnames(t_b);
                    for ii=1:length(t_new)
                        for ii_field=1:length(bfields)
                            if ismember(bfields{ii_field},cfields) && any(t_b(ii).(bfields{ii_field})~=t_new(ii).(bfields{ii_field}))
                                error(['Mismatch for ii=',num2str(ii),',field ',bfields{ii_field}]);
                            else
                                t_new(ii).(bfields{ii_field}) = t_b(ii).(bfields{ii_field});
                            end
                        end
                    end
                end
            end
            t=aggstruct(t,t_new);
        end
        [tr,j]=unique(cat(1,t.cycle_number));
        t=t(j);
    end
    ynn=input('Do you want to reload QC flags from the netCDF files? (y/n, default=n) ','s');
    if isempty(ynn),ynn='n'; end
    dokeep(1)=lower(ynn(1))=='n';
    ynn=input('Do you want to reload temperature and salinity (and oxygen) values from the netCDF files (y/n, default=n) ','s');
    if isempty(ynn), ynn='n'; end
    dokeep(2)=lower(ynn(1))=='n';
end

% If the pressure correction file contains no data then we need to force
% load
if ~any(dokeep==0) && ~isfield(tem,'t')
    warning('No Argo data found in the pressure correction file; loading from NetCDF');
    dokeep = [0 0];
end

%Read local netCDF files
if any(dokeep==0)
    t=read_all_nc(dire,files(:,1),t,dokeep);
    if size(files,2)==2
        % Biogeochemical data
        cfields=fieldnames(t);
        t_b = read_all_nc(dire,files(:,2),t,dokeep,1);
        if ~isempty(t_b)
            bfields=fieldnames(t_b);
            for ii=1:length(t)
                for ii_field=1:length(bfields)
                    if ismember(bfields{ii_field},cfields) && any(t_b(ii).(bfields{ii_field})~=t(ii).(bfields{ii_field}))
                        error(['Mismatch for ii=',num2str(ii),',field ',bfields{ii_field}]);
                    else
                        t(ii).(bfields{ii_field}) = t_b(ii).(bfields{ii_field});
                    end
                end
            end
        end
    end
end

%Remove redundant cycles
t=remove_redundant_struct(t,'cycle_number'); %this also sorts the structure by cycle number
cyc1=(cat(1,t.cycle_number));
lf=length(t);

% Plot the float positions, dates. Load the coast data, deal with discontinuities
% and wrap-around, display.
fig_traj = figure('units','normalized','position',[0.7 0.25 0.25 0.5]);
subplot(2,1,1);
dates_temp = [t.dates];
cycles_temp = [t.cycle_number];
lon_temp = [t.longitude];
lat_temp = [t.latitude];
plot(lon_temp,lat_temp,'k');
scatter3(lon_temp,lat_temp,[t.cycle_number],30,[t.cycle_number],'filled');
hold on;
ok = [t.position_qc] > '1';
if ~isempty(ok), plot(lon_temp(ok),lat_temp(ok),'ko','markersize',7); end
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

%write KML file for Google Earth
writekml(['kml' filesep floatname '.kml'],[cat(1,t.longitude) cat(1,t.latitude)],cat(1,t.cycle_number));
%actxserver([floatname '.kml'])
display(['Start Google Earth and load ' floatname '.kml']);

if isfield(t,'qc')
    qc=cyc1(cat(1,t.qc)==1);
    display(['Cycles Available: ' collapse_vec(cyc1)])
    display(['At least some level of QC Already Done On ' collapse_vec(qc)])
    nottodo=intersect(cyc1,qc);
    todo=cyc1;
    if ~isempty(nottodo)
        yn=input(['Do you want do perform visual QC on ' collapse_vec(nottodo) 'in addition to un-QCed cycles ? (y/n, default=y)'],'s');
        if isempty(yn), yn='y'; end
        if lower(yn)=='n'
            todo=setdiff(cyc1,qc);
        end
    end
else
    todo=cyc1;
end

% Launch visual QC if there's anything to QC
q=0;
if ~isempty(todo)
    
    % Prepare matrices of profile data
    lt = length(t);
    si = zeros(1,lt);   
    for ii_cyc=1:lt, si(ii_cyc) = length(t(ii_cyc).pres); end
    [PRES,PSAL,TEMP,SAL_QC,TEMP_QC]=deal(nan(max(si),lt)); %preallocate profile with max depths
    if size(files,2)==2, [DOXY,DOXY_QC]=deal(nan(max(si),lt)); end
    for i=1:lt
        PRES(1:si(i),i)=t(i).pres;
        PSAL(1:si(i),i)=t(i).psal;
        TEMP(1:si(i),i)=t(i).temp;
        SAL_QC(1:si(i),i)=t(i).psal_qc;
        TEMP_QC(1:si(i),i)=t(i).temp_qc;
    end
    if isfield(t,'doxy')
        for i=1:lt
            DOXY(1:si(i),i)=t(i).doxy;
            DOXY_QC(1:si(i),i)=t(i).doxy_qc;
            TEMP_DOXY(1:si(i),i)=t(i).temp_doxy;
            TEMP_DOXY_QC(1:si(i),i)=t(i).temp_doxy_qc;
        end
    end
    PTMP = sw_ptmp(PSAL,TEMP*ITS90toIPTS68,PRES,0);  % Calculate the potential temperature
    
    % TS plot
    fig_ts=plot_float_ts([t.cycle_number],PTMP,PSAL,TEMP_QC,SAL_QC);
    
    % Get the first profile to view
    i=input(['start at which profile? (default=', num2str(min(cyc1)), ')']);
    if isempty(i) || i<min(cyc1)
        i=min(cyc1);
    end
    i=find(i==cyc1);
    if i>1
        i=i-1;
    end
    % Create a figure, prepare the axes and UI elements
    % TODO: The passing of h_axes, h_ui is a temporary fix to avoid having
    % to constantly redraw the UI elements, which is hurting performance.
    % The longer-term fix is to redesign the code so that the GUI is more nearly top-level
    fig_gui = figure('units','normalized','position',[0 0 0.5 1]);
    h_axes = [];
    h_ui=[];
    % Iterate through all available cycles, processing those marked
    % previously as needing to be done (i.e., those greater than the
    % starting cycle that still need QC)
    % IG testing
    try
        foo = i<lf || (i==lf && q==8);
    catch
        disp('Problem!!')
    end
    while i<lf || (i==lf && q==8)
        if any(cyc1(i)==todo)
            % Adjust our bookmark forward or backward. Note that q=8 is the
            % backspace
            if length(q)>1  % This indicates we've requested a specific cycle
                foo=find(str2double(q(2:end))==cyc1);
                if isempty(foo)
                    warning('Invalid cycle requested');
                else
                    i=foo;
                end
            elseif (q~=8 || i<2) && q~=0
                i=i+1;
            elseif q~=0 % if user hits backspace
                i=i-1;
            end
            und=find(files(i).name=='_');
            display(files(i).name(und+1:end-3)); %display cycle on command window
            t(i).psal_qc=char(t(i).psal_qc);
            t(i).temp_qc=char(t(i).temp_qc);
            t(i).pres_qc=char(t(i).pres_qc);
            if isfield(t,'doxy_qc')
                t(i).doxy_qc=char(t(i).doxy_qc); 
                t(i).temp_doxy_qc=char(t(i).temp_doxy_qc); 
            end
            tic;
            % Launch visual QC for this cycle
            if ~strcmpi(q,'q')
                [temm,q,h_axes,h_ui]=visual_qc_ig(t(i),q,h_axes,h_ui);
                % Update the overall structures
                t(i)=rmfield(temm,setdiff(fieldnames(temm),fieldnames(t)));
                dura=toc;
                %if more than 1 second is spent on the screen, flag this profile as having been visually QCed
                if dura>1
                    t(i).qc=1;
                end
            elseif strcmp(q,'Q')
                % If the user has opted to quit, do not continue onto other
                % profiles
                break;  
            end
        else
            if q==8
                disp('testing'); 
            else
                i=i+1;
            end
        end
    end
    close(fig_traj,fig_ts,fig_gui);
end

% Proceed to additional flagging, range checks, etc. This is skipped if the
% user has opted to exit the process entirely via the 'Q' option.
if ~strcmp(q, 'Q')
    % If the salinity was unpumped we need to flag additional points
    i=input('Was salinity unpumped? y/n','s');
    if lower(i)=='y'
        for j=1:lf
            ok=find(t(j).pres<=4);
            t(j).psal_qc(ok)='3';
            t(j).temp_qc(ok)='3';
        end
    elseif lower(i)~='n'
        error('Answer must be either y or n');
    end

    %Perform range checks; override visual flags
    trio={'temp','psal','pres'};
    trio2={'TEMP','SAL','PRES'};
    if isfield(t,'doxy')
        trio{end+1}='doxy';
        trio2{end+1}='DOXY';
    end
    if isfield(t,'temp_doxy')
        trio{end+1}='temp_doxy';
        trio2{end+1}='TEMP_DOXY';
    end
    for j=1:length(trio)
        lim.(trio{j})=eval(local_config.(['lim' trio2{j}]));
    end
    for i=1:lf
        for j=1:length(trio)
            flag.(trio{j})=t(i).(trio{j})>lim.(trio{j})(2) | t(i).(trio{j})<lim.(trio{j})(1) | isnan(t(i).(trio{j}));
        end
        tempOrPres=flag.temp | flag.pres & t(i).temp_qc<'3';
        t(i).psal_qc((flag.psal | tempOrPres) & t(i).psal_qc<'3')='3';
        [t(i).temp_qc(tempOrPres),t(i).ptmp_qc(tempOrPres)]=deal('3');
        t(i).pres_qc(flag.pres & t(i).pres_qc<'3')='3';
        if isfield(t,'doxy')
            % Flag out-of-range DOXY/TEMP_DOXY values as '4', as per the
            % biogeochemical QC manual, section 2.2.1
            t(i).doxy_qc(flag.doxy & t(i).doxy_qc<'4')='4';
            t(i).temp_doxy_qc(flag.temp_doxy & t(i).temp_doxy_qc<'4')='4';
        end
    end
end
% If the user has used the 'Q' option they may not want to save their work
if q == 'Q'
    i= input('Save current state to file? y/n (default=n)', 's');
    if strcmpi(i,'y'), save_flag=1; 
    else save_flag=0;
    end
    % Regardless of whether or not we save to the temporary .mat file, we
    % won't update the main files
    fname = [];  
else save_flag=1;
end
if save_flag == 1
    if exist('tem','var') && isfield(tem,'presscorrect')
        presscorrect=tem.presscorrect;
        save(fname,'t','presscorrect');
    else
        save(fname,'t');
    end
end