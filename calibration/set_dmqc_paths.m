function apps_base_dir = set_dmqc_paths(apps_base_dir)
% SET_PATHS - Set the paths for Argo DMQC
%   OPTIONAL INPUTS:
%       apps_base_dir: Application base directory. If not provided then
%           it's assumed that the apps are in /u01/rapps if we're on a
%           Linux machine and W:\ if we're on a Windows machine
%   OPTIONAL OUTPUTS:
%       apps_base_dir: base working directory
%   VERSION HISTORY:
%       10 Jan 2019, Isabelle Gaboury: Created, based on the current
%           version of main_ig.m

% We generally use the latest version of the OW code, but this flag is
% included here in the off chance we would want to work with different
% versions
ow_version=2;

% Default application base directory
if nargin<1
%    if ispc, apps_base_dir='W:\';
%    else apps_base_dir='C:\Users\maz\Desktop\MEDS Project\';
apps_base_dir='C:\Users\maz\Desktop\MEDS Project\';
%    end
end

% Create list of paths to add. We do this separately from the calls to
% addpath because this command can get a bit slow, so we try not to call it
% unnecessarily
% Base working directory
dm_paths = {fullfile(apps_base_dir,'argo_dm','calibration')};
% OW code and m_map toolbox
if ow_version==2
    dm_paths{end+1} = fullfile(apps_base_dir, 'argo_dm', 'matlab_codes', 'ow_v2_x');
    dm_paths{end+1} = fullfile(apps_base_dir, 'm_map_1_4');
else
    dm_paths{end+1} = fullfile(apps_base_dir, 'argo_dm', 'matlab_codes', 'ow_v1_1');
    dm_paths{end+1} = fullfile(apps_base_dir, 'm_map_1_3');
end
% Seawater toolbox and VMS tools
 dm_paths{end+1} = fullfile(apps_base_dir, 'seawater');
dm_paths{end+1} = fullfile(apps_base_dir, 'vms_tools');
% GSW toolbox
dm_paths{end+1} = fullfile(apps_base_dir, 'gsw');
dm_paths{end+1} = fullfile(apps_base_dir, 'gsw', 'library');
%sftp library
dm_paths{end+1} = fullfile(apps_base_dir, 'ssh2_v2_m1_r7');
% Now we actually add the paths
for ii=1:length(dm_paths)
    if ~contains(path, [dm_paths{ii} pathsep])
        addpath(dm_paths{ii})
    end
end

if nargout<1, clear apps_base_dir; end

end

