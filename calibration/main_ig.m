% MAIN_IG - Main function for the Argo DMQC
%   OPTIONAL INPUTS:
%       float_name: Name of the float, as a string, without the leading
%           'Q'. May be empty.
%       proc_step: One of the following, or empty to receive a prompt:
%           'update_climatologies', 'calculate_stats',
%           'ftp_download','pres_adj','visual_qc','ow','ow_postprocess'
%           ,'publish', 'update_flags'
%       region: Either 'pacific' or 'atlantic'
%   VERSION HISTORY:
%       23 May 2017, Isabelle Gaboury: Created, based on Mathieu Ouellet's
%           version dated 14 September 2016.
%       Jan 2019, IG: Major rewrite

function main_ig(float_name, proc_step, region)
%% Setup %%

% We start clean, with all figures closed
close all;

% Add the paths to the needed toolboxes, get the base directory
apps_base_dir = set_dmqc_paths;

% Hard-coded parameters
ftp_cfg_file = fullfile(apps_base_dir,'argo_dm','calibration','ftp_logins_ig.txt');
local_cfg_file = fullfile(apps_base_dir,'argo_dm','calibration','local_OW_v3.txt'); % or local_OW_v1_1.txt for the old OW version
ow_cfg_parts = {'config_ow_', '_v3.txt'}; % Prefix and suffix, with the region in between. Again, _v1_1 for the old version
general_processing_steps = {'update_climatologies','calculate_stats'};
float_processing_steps = {'ftp_download','pres_adj','visual_qc','ow','ow_postprocess','publish','update_flags'};

% Process the inputs, prompting the user for additional information
if nargin<1
   float_name=input('Enter float name, or leave blank to continue without one: ','s');
elseif isnumeric(float_name), float_name = num2str(float_name);
end
if nargin<2
    proc_step = '';
    disp('Processing options:')
    if isempty(float_name)
        q = input('Enter 1 to update the reference database from Coriolis, or 2 to calculate GDAC statistics: ');
        if q<=length(general_processing_steps)
            proc_step=general_processing_steps{q};
        end
    else
        disp('Float-specific options:')
        disp('1-Download files from the IFREMER FTP site')
        disp('2-Pressure adjustment')
        disp('3-Visual QC')
        disp('4-Owens-Wong-Cabanes')
        disp('5-OWC post-processing')
        disp('6-Publish to FTP')
        disp('7-Update NetCDF flags from the working MAT file');
        q=input('Selection: ');
        if q<=length(float_processing_steps)
            proc_step = float_processing_steps{q};
        end
    end
end
if isempty(proc_step)
    warning('Unrecognized option selected, no action will be taken');
    return;
end

% Process the region. Note that we only care about the region for some
% processing steps
if nargin < 3
    if ~isempty(float_name)
        region = lower(input('Select region (subpolaratlantic/atlantic/pacific, default is pacific)? ','s'));
        if isempty(region), region='pacific'; end
    else region = '';
    end
end
if ~isempty(float_name) && ~ismember(region,{'atlantic','pacific','subpolaratlantic'})
    error('No parameters exist for this region'); 
end

% Set default plot options
set(0,'defaultaxesnextplot','add')
set(0,'defaultfigurenextplot','add')
% These lines keep the figure from being mid-way between the two screens for
% a dual-mnitor setup
foo1 = get(0,'DefaultFigurePosition');
foo2 = get(0,'MonitorPositions');
set(0,'DefaultFigurePosition',[foo2(3)*0.25, foo1(2:4)]);

% Load Owen & Wong configuration
local_config=load_configuration(local_cfg_file);
if ispc, local_config=xp1152pc(local_config); end
if isempty(region)
    lo_system_configuration=load_configuration([local_config.BASE ow_cfg_parts{1} region ow_cfg_parts{2}(2:end)]);
else
    lo_system_configuration=load_configuration([local_config.BASE ow_cfg_parts{1} region ow_cfg_parts{2}]);
end
if ispc, lo_system_configuration=xp1152pc(lo_system_configuration); end

% Load the FTP configuration
if strcmpi(proc_step,'calculate_stats') || strcmpi(proc_step,'publish')
    ftp_cfg=read_ftp_cfg(ftp_cfg_file,{'ifremer','meds'});
end

%% Processing %%

% Get the list of D files if they will be needed later
if strcmpi(proc_step,'pres_adj') || strcmpi(proc_step,'visual_qc')
    % Get the list of files to visually QC
    nc_dir = fullfile(local_config.DATA,float_name);
    files_to_process=[dir([nc_dir filesep 'D' float_name '*.nc']); dir([nc_dir filesep 'R' float_name '*.nc'])];
    files_to_process_b=[dir([nc_dir filesep 'BD' float_name '*.nc']); dir([nc_dir filesep 'BR' float_name '*.nc'])];
    % TODO: The orderfilsbycycle may be redundant on modern OS's.
    files_to_process = orderfilesbycycle(files_to_process);
    if ~isempty(files_to_process_b)
        files_to_process = [files_to_process orderfilesbycycle(files_to_process_b)];
        for ii_row=1:length(files_to_process_b)
            if ~strcmp(files_to_process(ii_row,1).name(2:end-3), files_to_process(ii_row,2).name(3:end-3))
                error('B and core files do not match');
            end
        end
    end
end

% Finally, it's time to do the processing
if strcmpi(proc_step,'update_climatologies')
    %update_OW_climatologies
    % I usually download and untar separately
    update_ref_dbase(lo_system_configuration);
    display('Edit climatology information in config file');
    edit(lo_system_configuration.CONFIGURATION_FILE);
elseif strcmpi(proc_step,'calculate_stats')
    calculate_server_stats(ftp_cfg.ifremer.url, ftp_cfg.ifremer.user, ...
        ftp_cfg.ifremer.pwd, ftp_cfg.ifremer.path,[local_config.DATA,filesep,'temp'],...
        365.25/2,[],0);
elseif strcmpi(proc_step, 'ftp_download')
    % TODO: Re-add the option to not always overwrite everything
    fetch_from_web(local_config.DATA, float_name, 1);
elseif strcmpi(proc_step, 'pres_adj')
    presMain_ig(local_config,lo_system_configuration,float_name);
elseif strcmpi(proc_step, 'visual_qc')
    fname = interactive_qc_ig(local_config,files_to_process);
    % An empty value for fname indicates that the user quit the
    % process, and source files should not be created.
    if ~isempty(fname)
        create_source_files(local_config,lo_system_configuration,float_name);
    else
        warning('Visual QC exited before the process was complete!');
    end
    close all
elseif strcmpi(proc_step, 'ow')
    cd(local_config.MATLAB)
    argo_calibration(lo_system_configuration,{float_name});% new profiles are mapped and calibrated in this program from Annie Wong
    cd(local_config.BASE)
    close all
elseif strcmpi(proc_step, 'ow_postprocess')
    set(0,'defaultfigureWindowStyle','normal')
    viewplots_ig(lo_system_configuration,local_config,float_name);
    % warning('Using a custom call to viewplots_ig to fix up the DATA_MODE')
    % viewplots_ig(lo_system_configuration,local_config,float_name,0,0,1);
    reducehistory(local_config,float_name);
elseif strcmpi(proc_step, 'publish')
    publishtoweb(local_config,lo_system_configuration,float_name,1,...
        ftp_cfg.meds.user,ftp_cfg.meds.url,ftp_cfg.meds.path);
elseif strcmpi(proc_step, 'update_flags')
    update_qc_flags(local_config,float_name);
end

end
