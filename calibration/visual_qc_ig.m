function [s,q,h_axes,h_ui]=visual_qc_ig(s,q,h_axes,h_ui)
% VISUAL_QC_IG Visual QC of a single Argo profile (Isabelle's version)
%   DESCRIPTION:
%       Interactively QC a single Argo profile. Display the profile, and
%       handle user interactions
%       See qc_window_ig.m for available functions
%   USAGE:
%      [s,q] = visual_qc_ig(s,q)
%   INPUTS:   
%       s - Structure of profile data
%       q - Last user input
%   OUTPUTS:
%       s, q - Updated versions of the inputs
%   VERSION HISTORY:
%       26 May 2017, Isabelle Gaboury: Created, based on the version in
%           vms_tools dated 09 January 2017.

% By default, we assume no existing axes or UI elements
if nargin < 4, h_ui = []; end
if nargin < 3, h_axes = []; end

% If there's a "deph" field, rename to "pres"
if isfield(s,'deph')
    s.pres=s.deph;
    s.pres_qc=s.deph_qc;
    s=rmfield(s,'deph');
    s=rmfield(s,'deph_qc');
end

% Fetch a list of fieldnames other than the pressures
fn=setdiff(fieldnames(s),{'pres','ptmp'});

% If there's a pressure, we can perform QC on this profile. Otherwise
% nothing will happen.
if strmatch('temp',fieldnames(s))
    %remove adjusted fields and fields without a corresponding qc field
    torem=[];
    for i=1:length(fn)
        if ~isempty(findstr(fn{i},'_adjusted'))
            torem=[torem i];
        elseif isempty(findstr(fn{i},'_qc')) && i<length(fn)
            j=0;        notfound=1;
            while j<length(fn) && notfound
                j=j+1;
                notfound=~strcmp(fn{j},[fn{i} '_qc']);
            end
            if notfound
                torem=[torem i];
            end
        elseif ~isempty(findstr(fn{i},'_qc'))
            j=0;        notfound=1;
            while j<length(fn) && notfound
                j=j+1;
                notfound=~strcmp(fn{j},fn{i}(1:end-3));
            end
            if notfound
                torem=[torem i];
            end
        end
    end
    fn=fn(setdiff(1:length(fn),unique(torem)));
    i=1;
    while i<=length(fn)
        if findstr(fn{i},'_qc')
            fn=fn([1:i-1 i+1:end]);
        else
            i=i+1;
        end
    end
    
    % Figure out what plots we can create. Typically psal vs. pres, temp
    % vs. pres, and psal vs. temp
    plots = cell(1,length(fn));
    for i=1:length(fn)
        plots{i}=char({fn{i},'pres'}); %TP
    end
    if ~isempty(strmatch('psal',fn))
        plots{end+1}=char({'dens','pres'}); % Density
        plots{end+1}=char({'psal','temp'}); % TS
    end
    
    % Fetch the profile data for all available plots
    prof_data = cell(1,length(plots));
    prof_data_qc = cell(1,length(plots));
    for ii_plot=1:length(plots)
        jj=0;
        jj2=0;
        for j=1:size(plots{ii_plot},1)
            % Fetch the profile and QC data
            if strncmp(plots{ii_plot}(j,:),'dens',4)
                jj=jj+1;
                jj2=jj2+1;
                % Calculate the potential density
                try
                    [sal_abs,foo] = gsw_SA_from_SP(s.psal,s.pres,s.longitude,s.latitude);
                    temp_cons = gsw_CT_from_t(sal_abs,s.temp,s.pres);
                    dens_ct = gsw_rho_CT(sal_abs,temp_cons,mean(s.pres));
                    prof_data{ii_plot}(:,jj)=dens_ct'-1000.0;
                catch ex
                    warning(ex.identifier, ['Failed to calculate the potential density: ' ex.message]);
                    prof_data{ii_plot}=nan*ones(size(s.pres))';
                end
                prof_data_qc{ii_plot}(:,jj2:jj2+2)=[s.pres_qc; s.temp_qc; s.psal_qc]';
                jj2=jj2+2;
            elseif ~strncmp(plots{ii_plot}(j,:),'ptmp',4)
                temp_fieldname = deblank(plots{ii_plot}(j,:));
                jj=jj+1;
                jj2=jj2+1;
                prof_data{ii_plot}(:,jj)=s.(temp_fieldname);
                % If necessary, add a field to s for the QC data
                if ~isfield(s,([temp_fieldname '_qc'])) || isempty(s.([temp_fieldname '_qc']))
                    s.([temp_fieldname '_qc'])=char('1'*ones(size(s.pres))');
                end
                prof_data_qc{ii_plot}(:,jj2)=(s.([temp_fieldname '_qc']));
            else
                prof_data{ii_plot} = [];
                prof_data_qc{ii_plot} = [];
            end
            % Checks for invalid values in the profile data QC flags
            prof_data_qc{ii_plot}(isnan(prof_data_qc{ii_plot}))=' ';
            prof_data_qc{ii_plot}(prof_data_qc{ii_plot}<'1')='1';
        end
    end
    
    % If the last user input was 's' (skip to the next profile with flags)
    % and there are no QC flags greater than 1 in the current profile then
    % we don't do anything further; otherwise we launch visual QC of the
    % current profile.
    if ~strcmpi(q,'s') || any(prof_data_qc{ii_plot}(:)>'1')
        % Get the climatologies
        S_clim = cell(length(plots));
        for ii_plot=1:length(plots)
            if (strcmp(plots{ii_plot}(1,:),'psal') || strcmp(plots{ii_plot}(1,:),'temp')) && ...
                    strcmp(plots{ii_plot}(2,:),'pres') && length(s.longitude)==1
                S_clim{ii_plot}=getClimGTSPP(s.longitude,s.latitude,datestr(s.dates,'mm'),plots{ii_plot}(1,:));
            elseif ((strcmp(plots{ii_plot}(1,:),'psal') && strcmp(plots{ii_plot}(2,:),'temp')) || ...
                    (strcmp(plots{ii_plot}(2,:),'psal') && strcmp(plots{ii_plot}(1,:),'temp'))) && ...
                    length(s.longitude)==1
                % A bit of a cheat on getClimGTSPP for the purposes of the
                % TS plot
                foo = getClimGTSPP(s.longitude,s.latitude,datestr(s.dates,'mm'),plots{ii_plot}(1,:));
                S_clim{ii_plot}.temp = foo.temp;
                foo = getClimGTSPP(s.longitude,s.latitude,datestr(s.dates,'mm'),plots{ii_plot}(2,:));
                S_clim{ii_plot}.pres = foo.temp;
            else
                S_clim{ii_plot}=[];
            end
        end
        % Get the platform and station/cycle number for the purposes of
        % creating titles
        if isfield(s,'crn') 
            platform_string = s.crn;      % This is not usually available, but may exist from other processing
        elseif isfield(s, 'platform_number')
            platform_string = s.platform_number;
        else
            platform_string = '';
        end
        if isfield(s, 'pfn')
            station_string = s.pfn;       % This is not usually available, but may exist from other processing
        elseif isfield(s, 'cycle_number')
            station_string = num2str(s.cycle_number);
        else
            station_string = '';
        end
%         display('Profile data:')
%         prof_data_qc{1}(1:3,:)
        [prof_data_qc,q]=qc_window_ig(prof_data,S_clim,prof_data_qc,plots,[s.longitude s.latitude s.dates],...
            platform_string,station_string);
        % Update the original data structure for return to the calling
        % program. We don't need to do anything with the density or TS
        % plots
        for ii_plot=1:length(plots)
            % Skip the dens and TS plots
            % TODO: Generalize this
            if strcmp(plots{ii_plot}(2,1:4),'pres') && ~strcmp(plots{ii_plot}(1,1:4),'dens')
                s.([deblank(plots{ii_plot}(1,:)) '_qc'])(:,:)=prof_data_qc{ii_plot}(:,1);
                s.([deblank(plots{ii_plot}(2,:)) '_qc'])(:,:)=prof_data_qc{ii_plot}(:,2);
            end
        end
    end
       
end
end % end of visual_qc_ig function

