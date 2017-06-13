function fix_0dBar_flags(floatname)
% FIX_0DBAR_FLAGS - Fix flags for floats with lots of pressures <= 0 dBar
%   DESCRIPTION - For some Argo floats, a large number of profiles have the
%       following features for the near-surface samples: Surface pressure
%       <=0 dBar flagged to 4; upper 1-2 T,S samples flagged to 4 also.
%       Based on discussion with Mathieu, have opted to change the pressure
%       and conductivity flags for these to 3 (could possibly be fixed via
%       the pressure adjustment), and if the salinity seems reasonable then
%       flag this to 1. This routines does this automatically, assuming
%       that the data have already been saved to a .mat file.
%   INPUTS:
%       rawflagpres_dir - Directory in which the output of presMain is
%           stored
%       floatname - Float number, as a string
%   OUTPUTS:
%       None, but the .mat file is updated
%   VERSION HISTORY:
%       07 June 2017, Isabelle Gaboury: Created

% Get the float path, based on the name and the local configuration
local_config=load_configuration('local_OW.txt');
fname=[local_config.RAWFLAGSPRES_DIR floatname];

% Load the data. The .mat file must already have been created
if exist([fname '.mat'],'file')
    load(fname,'t','presscorrect');
else
    error('File name not found');
end

% Iterate through the profiles, lookin for near-surface flags
for ii_prof=1:length(t)
    if strcmp(t(ii_prof).pres_qc(1),'4') && strcmp(t(ii_prof).psal_qc(1),'4') && ...
            strcmp(t(ii_prof).temp_qc(1),'4') && t(ii_prof).pres(1) <= 0
        % Set the surface values for the pressure and conductivity to 3
        % rather than 4
        t(ii_prof).pres_qc(1)='3';
        t(ii_prof).psal_qc(1)='3';
        % We assume that the temperature at the surface is OK, although
        % this needs to be confirmed by visual QC later
        t(ii_prof).temp_qc(1)='1';
        % Similarly, we assume that the second value from the surface is
        % OK for all values, but this also needs to be confirmed
        t(ii_prof).pres_qc(2)='1';
        t(ii_prof).temp_qc(2)='1';
        t(ii_prof).psal_qc(2)='1';
    end
end

% Save back to file
save(fname,'t','presscorrect');

end