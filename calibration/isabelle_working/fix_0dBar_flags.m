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

% Add the GSW toolbox to the path
addpath('/u01/rapps/gsw/');
addpath('/u01/rapps/gsw/library');

% Get the float path, based on the name and the local configuration
local_config=load_configuration('local_OW.txt');
fname=[local_config.RAWFLAGSPRES_DIR floatname];

% Load the data. The .mat file must already have been created
if exist([fname '.mat'],'file')
    load(fname,'t','presscorrect');
else
    error('File name not found');
end

% Iterate through the profiles, looking for near-surface flags. We assume
% that any density inversions greater than the threshold of 0.03 kg/m^3
% have already been correctly flagged in RTQC, and should not be unflagged.
% However, any points flagged merely because of the pressure being near
% zero can have the flag "downgraded" from 4 to 3.
for ii_prof=1:length(t)
    if strcmp(t(ii_prof).pres_qc(1),'4') && strcmp(t(ii_prof).psal_qc(1),'4') && ...
            strcmp(t(ii_prof).temp_qc(1),'4') && t(ii_prof).pres(1) <= 0
%     if strcmp(t(ii_prof).pres_qc(1),'3') &&
%     strcmp(t(ii_prof).psal_qc(1),'3') && t(ii_prof).pres(1) <= 0
        % Calculate the potential densities
        [sal_abs, foo] = gsw_SA_from_SP(t(ii_prof).psal(1:2),t(ii_prof).pres(1:2),...
            t(ii_prof).longitude,t(ii_prof).latitude);
        temp_cons = gsw_CT_from_t(sal_abs,t(ii_prof).temp(1:2),t(ii_prof).pres(1:2));
        dens_ct = gsw_rho_CT(sal_abs,temp_cons,mean(t(ii_prof).pres(1:2)));
        if dens_ct(1)-dens_ct(2) > 0.03
            display(['Flags for profile ' num2str(t(ii_prof).cycle_number) ' checked and left as-is']);
        else
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
            display(['Flags for profile ' num2str(t(ii_prof).cycle_number) ' altered']);
        end
    end
end

% Save back to file
save(fname,'t','presscorrect');

end