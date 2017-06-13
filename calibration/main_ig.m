% Main function for the Argo DMQC
%
% Isabelle Gaboury, 23 May 2017, based on Mathieu Ouellet's version dated
% 14 September 2016.

function argu = main_ig(argu)

% Default inputs. See menudmqc_ig.m for options for argu
if nargin < 1, argu = []; end

% Make sure the Seawater and VMS tools toolboxes are on the path
if ~ispc
    addpath('/u01/rapps/argo_dm/calibration');
    addpath('/u01/rapps/seawater');
    addpath('/u01/rapps/vms_tools');
    addpath('/u01/rapps/m_map');
else
    addpath('w:\argo_dm\calibration');
    addpath('w:\seawater');
    addpath('w:\vms_tools');
    addpath('w:\m_map');
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
local_config=load_configuration('local_OW.txt');
if ispc
    local_config=xp1152pc(local_config);
end
lo_system_configuration=load_configuration([local_config.BASE 'config_ow.txt']);
if ispc
    lo_system_configuration=xp1152pc(lo_system_configuration);    
end

% Get files to process
i=1;
floatnames = {};
[filestoprocess,floatnames{i},ow]=menudmqc_ig(local_config,argu);
if ow(1)
    fetch_from_web(local_config.DATA, floatnames{i});
end
while ~isempty(filestoprocess)
    if ow(2)
        presMain(local_config,lo_system_configuration,filestoprocess,floatnames{i}); %find pressure correction
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
        argo_calibration_ig(lo_system_configuration,floatnames(i));% new profiles are mapped and calibrated in this program from Annie Wong
        cd(local_config.BASE)
        close all
    end
    if ow(4)
        set(0,'defaultfigureWindowStyle','normal')
        viewplots(lo_system_configuration,local_config,floatnames{i});
    end
    if ow(5)
        reducehistory(local_config,floatnames{i});
    end
    if ow(6)
        publishtoweb_ig(local_config,lo_system_configuration,floatnames{i},1);
    end
    i=i+1;
    [filestoprocess,floatnames{i},ow]=menudmqc_ig(local_config);
end

if nargout < 1, clear argu; end
