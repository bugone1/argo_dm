% Main function for the Argo DMQC
%
% Isabelle Gaboury, 23 May 2017, based on Mathieu Ouellet's version dated
% 14 September 2016.

function argu = main_ig(region, argu)

close all;

% FTP user name (for Isabelle)
ftp_user = 'igabouryi@sshreadwrite';

% Default inputs. See menudmqc_ig.m for options for argu
if nargin < 1 
    region = input('Select region (atlantic/pacific, default is pacific)? ','s');
end
region = lower(region);
if ~ismember(region,{'atlantic','pacific',''}), error('No parameters exist for this region'); 
%elseif strcmp(region,'pacific'), region=''; % This is currently the default case
elseif ~isempty(region), region = ['_' lower(region)];
end
ow_version=2;

if nargin < 1, argu = []; end

% Make sure the Seawater and VMS tools toolboxes are on the path
if ~ispc
    addpath('/u01/rapps/argo_dm/calibration');
    if ow_version==2, addpath('/u01/rapps/argo_dm/matlab_codes/ow_v2_x');
    else addpath('/u01/rapps/argo_dm/matlab_codes/ow_v1_1');
    end
    addpath('/u01/rapps/seawater');
    addpath('/u01/rapps/vms_tools');
    if ow_version==2, addpath('/u01/rapps/m_map_1_4');
    else addpath('/u01/rapps/m_map_1_3');
    end
    addpath('/u01/rapps/gsw/');
    addpath('/u01/rapps/gsw/library');
else
    addpath('w:\argo_dm\calibration');
    addpath('W:\argo_dm\matlab_codes\ow_v2_x');
    addpath('w:\seawater');
    addpath('w:\vms_tools');
    addpath('w:\m_map_1_4');
    addpath('w:\gsw');
    addpath('w:\gsw\library');
end

% Set default plot options
set(0,'defaultaxesnextplot','add')
set(0,'defaultfigurenextplot','add')
% These lines keep the figure from being mid-way between the two screens for
% a dual-mnitor setup
foo1 = get(0,'DefaultFigurePosition');
foo2 = get(0,'MonitorPositions');
set(0,'DefaultFigurePosition',[foo2(3)*0.25, foo1(2:4)]);

% Tidy up variables from previous session, load Owen & Wong configuration
if ow_version==2, local_config=load_configuration('local_OW_v2.txt');
else local_config=load_configuration('local_OW_v1_1.txt');
end
if ispc
    local_config=xp1152pc(local_config);
end
if ow_version==2, lo_system_configuration=load_configuration([local_config.BASE 'config_ow' region '_v2.txt']);
else lo_system_configuration=load_configuration([local_config.BASE 'config_ow' region '_v1_1.txt']);
end
if ispc
    lo_system_configuration=xp1152pc(lo_system_configuration);    
end

% Get files to process
i=1;
% floatnames = {};
[filestoprocess,floatnames{i},ow]=menudmqc_ig(local_config,lo_system_configuration,argu);
% if ow(1)
%     fetch_from_web(local_config.DATA, floatnames{i});
% end
% i=0;
% filestoprocess=1;
% ow = zeros(1,6);
while ~isempty(filestoprocess) || ow(1)
    if ow(1)
        try fetch_from_web(local_config.DATA, floatnames{i}); 
        catch
            display('Oops');
        end
    end
    if ow(2)
        presMain_ig(local_config,lo_system_configuration,filestoprocess(:,1),floatnames{i}); %find pressure correction
        fname = interactive_qc_ig(local_config,filestoprocess); %visual qc
        % An empty value for fname indicates that the user quit the
        % process, and source files should not be created.
        if ~isempty(fname)
            create_source_files(local_config,lo_system_configuration,floatnames{i});
        else
            warning('Visual QC exited before the process was complete!');
            break;
        end
        close all
    end
    if ow(3)
        cd(local_config.MATLAB)
        argo_calibration(lo_system_configuration,floatnames(i));% new profiles are mapped and calibrated in this program from Annie Wong
        cd(local_config.BASE)
        close all
    end
    if ow(4)
        set(0,'defaultfigureWindowStyle','normal')
        viewplots_ig(lo_system_configuration,local_config,floatnames{i});
    end
    if ow(5)
        reducehistory(local_config,floatnames{i});
        publishtoweb(local_config,lo_system_configuration,floatnames{i},1,ftp_user);
    end
%     if ow(7)
%         % I've jotted down the paths here, but haven't yet tested them
%         % carefully to make sure there's no colateral damage; this must be
%         % done before the error message is removed
%         error('Cleanup code still under construction, please debug and test carefully before removing this error.');
%         delete([local_config.RAWFLAGSPRES_DIR floatnames{i} '.mat']);
%         delete([lo_system_configuration.FLOAT_SOURCE_DIRECTORY floatnames{i} lo_system_configuration.FLOAT_SOURCE_POSTFIX]);
%         delete([lo_system_configuration.FLOAT_MAPPED_DIRECTORY lo_system_configuration.FLOAT_MAPPED_PREFIX floatnames{i} lo_system_configuration.FLOAT_MAPPED_POSTFIX]);
%         delete([lo_system_configuration.FLOAT_CALIB_DIRECTORY lo_system_configuration.FLOAT_CALIB_PREFIX floatnames{i} lo_system_configuration.FLOAT_CALIB_POSTFIX]);
%         delete([lo_system_configuration.FLOAT_CALIB_DIRECTORY lo_system_configuration.FLOAT_CALSERIES_PREFIX floatnames{i} lo_system_configuration.FLOAT_CALIB_POSTFIX]);
%         delete([lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep 'pres_*_' floatnames{i} '.png']);
%         delete([lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep floatnames{i} '*.png']);
%         delete([lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep floatnames{i} 'calib.htm']);
%         delete([lo_system_configuration.FLOAT_PLOTS_DIRECTORY floatnames{i} '*.png']);
%         delete([local_config.BASE floatnames{i} '.zip']);
%         delete([local_config.BASE floatnames{i} '.kml']);
%         delete([local_config.OUT 'D' floatnames{i} '.nc']);
%         delete([local_config.OUT 'D' floatnames{i} '.nc.old']);
%     end
    i=i+1;
    [filestoprocess,floatnames{i},ow]=menudmqc_ig(local_config);
end

if nargout < 1, clear argu; end
