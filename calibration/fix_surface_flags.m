function fix_surface_flags(floatname, floattype, preserve_existing_flags)
% FIX_SURFACE_FLAGS Fix flags for floats with lots of pressures very near
%   the surface
%   DESCRIPTION Some Argo floats may have large numbers of points at or
%       near the surface, which may or may be flagged during RT QC. This
%       routines adjusts flags based on the float_type and Argo QC rules.
%       Pressures <=0 are set to 3 (might be fixed via the pressure
%       adjustment). T,S for pressures less than the float-specific
%       cut-offs are similarly marked as 3 if there is no significant
%       density inversion, or 4 if there is an inversion >0.03 kg/m^3. 
%       The routine assumes that presMain.m has already been used to create
%       a .mat file of float data.
%   INPUTS:
%       floatname - Float number, as a string
%       floattype - Must currently be 'NOVA', and this is the default.
%       preserve_existing_flags - Set this to 1 to only change flags where
%           the level will be increased; set to 2 to only preserve flags on
%           T,S, but not P. Should normally be left as 0 (the default), but
%           can be useful in reprocessing files that have already undergone
%           visual QC.
%   OUTPUTS:
%       None, but the .mat file is updated
%   VERSION HISTORY:
%       07 June 2017, Isabelle Gaboury: Created
%       14 July 2017, IG: floattype parameter updated, flagging rules
%           updated based on the QC manual.
%       26 July 2017, IG: Added option for preserve_existing_flags=2
%       3 Apr. 2018, IG: Added handling for single-element pressure vectors
%       26 Feb. 2019, IG: Added check for depth related to unpumped samples

% Default is NOVA floats, no existing flags to preserve
if nargin < 3, preserve_existing_flags = 0; end
if nargin<2, floattype='NOVA'; end

% Add the GSW toolbox to the path
addpath('/u01/rapps/gsw/');
addpath('/u01/rapps/gsw/library');

% Get the float path, based on the name and the local configuration
local_config=load_configuration('local_OW_v2.txt');
fname=[local_config.RAWFLAGSPRES_DIR floatname];

% Load the data. The .mat file must already have been created
if exist([fname '.mat'],'file')
    load(fname,'t','presscorrect');
else
    error('File name not found');
end

% Determine the depth cutoff to use. The first element is for the air/water
% mix, the second is for the unpumped sample. For now we assume the second
% element is the larger of the two
% TODO: Add cutoffs for other float types, consider cutoff depth in a
% configuration file.
if strcmpi(floattype,'NOVA'), p_co = [1,4];
else error('This routine can currently only handle NOVA floats');
end

% Iterate through the profiles, looking for near-surface flags. We assume
% that any density inversions greater than the threshold of 0.03 kg/m^3
% have already been correctly flagged in RTQC, and should not be unflagged.
% However, any points flagged merely because of the pressure being near
% zero can have the flag "downgraded" from 4 to 3.
for ii_prof=1:length(t)
    if t(ii_prof).pres(1) <= p_co(2)
        if length(t(ii_prof).pres)==1 
            if t(ii_prof).pres(1)<=0 && (t(ii_prof).pres_qc(1)<'4' || preserve_existing_flags==0)
                t(ii_prof).pres_qc(1) = '3'; 
            end
            if t(ii_prof).pres(1)<=p_co(1) && t(ii_prof).temp_qc(1) < '4' || preserve_existing_flags==0
                t(ii_prof).temp_qc(1) = '3';
            end
            if t(ii_prof).psal_qc(1) < '4' || preserve_existing_flags==0
                t(ii_prof).psal_qc(1) = '3';
            end
        else
            for iiz=find(t(ii_prof).pres<=p_co(2))
                % Get the current flags
                old_flags = [t(ii_prof).pres_qc(iiz) t(ii_prof).temp_qc(iiz) t(ii_prof).psal_qc(iiz); ...
                    t(ii_prof).pres_qc(iiz+1) t(ii_prof).temp_qc(iiz+1) t(ii_prof).psal_qc(iiz+1)];
                new_flags = old_flags;
                if strcmp(t(ii_prof).psal_qc(iiz),'4') && strcmp(t(ii_prof).temp_qc(iiz),'4')
                    % Calculate the potential densities
                    [sal_abs, foo] = gsw_SA_from_SP(t(ii_prof).psal(iiz:iiz+1),t(ii_prof).pres(iiz:iiz+1),...
                        t(ii_prof).longitude,t(ii_prof).latitude);
                    temp_cons = gsw_CT_from_t(sal_abs,t(ii_prof).temp(iiz:iiz+1),t(ii_prof).pres(iiz:iiz+1));
                    dens_ct = gsw_rho_CT(sal_abs,temp_cons,mean(t(ii_prof).pres(iiz:iiz+1)));
                    if dens_ct(1)-dens_ct(2) < 0.03
                        if t(ii_prof).pres(iiz)<=p_co(1), new_flags = [old_flags(1,1) '3' '3'; '1' '1' '1'];
                        else new_flags = [old_flags(1,1) '1' '3'; '1' '1' '1'];
                        end
                    end
                else
                    if t(ii_prof).pres(iiz)<=p_co(1), new_flags = [old_flags(1,1) '3' '3'; '1' '1' '1'];
                    else new_flags = [old_flags(1,1) '1' '3'; '1' '1' '1'];
                    end
                end
                % Also set the pressure to '3' if it's at or less than 0. 
                if t(ii_prof).pres(iiz) <= 0
                    new_flags(1,1) = '3';
                end
                % Preserve existing flags if requested
                if preserve_existing_flags==1   % Keep the higher flag for all 3 variables
                    new_flags = char(max(old_flags,new_flags)); 
                elseif preserve_existing_flags==2 % Keep the higher flag for only T,S, new flags for P
                    new_flags(:,2:3) = char(max(old_flags(:,2:3),new_flags(:,2:3))); 
                end
                % Deal to the orginal structure
                t(ii_prof).pres_qc(iiz:iiz+1) = new_flags(:,1)';
                t(ii_prof).temp_qc(iiz:iiz+1) = new_flags(:,2)';
                t(ii_prof).psal_qc(iiz:iiz+1) = new_flags(:,3)';
            end
        end
    end
end

% Save back to file
save(fname,'t','presscorrect');

end