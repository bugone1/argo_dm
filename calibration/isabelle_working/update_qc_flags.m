function update_qc_flags(float_num, skip_tnpd_adj)
% UPDATE_QC_FLAGS Apply visual QC flags and regenerate NetCDF files
%   DESCRIPTION: Given the original NetCDF files and the output of the
%       visual QC process stored in the usual .mat file, apply QC flags and
%       rewrite the NetCDF files. This does not apply any adjustments or
%       adjust the calibration history; it only updates the QC flags and
%       updates the change history.
%   USAGE: update_qc_flags(float_num)
%   INPUTS: 
%       float_num - String float number
%       skip_tnpd_adj - Set to 1 to skip TNPD evaluation (e.g., if for some
%           reason or another we don't want to change the previous
%           approach)
%   VERSION HISTORY:
%       6 November 2017, Isabelle Gaboury: Created, based loosely on a
%           previously-modified version of viewplots.
%       13 Apr. 2018, IG: Added ability to fill adjusted values previously
%           set to the fill value when upgrading QC flags; added history
%           reduction.
%       9 May 2018, IG: Fixed an issue with the filling of previously-bad
%           values.
%       29 May 2018, IG: Fixed an issue with how adjusted QC flags were
%           set.
%       11 Dec. 2018, IG: Updated call to rewrite_nc

if nargin<2, skip_tnpd_adj=0; end

% Setup
rawflagpres_dir = '/u01/rapps/argo_dm/data/temppresraw/';
nc_dir_raw = '/u01/rapps/argo_dm/calibration/data/';
nc_dir_out = '/u01/rapps/argo_dm/calibration/output/changed/';
addpath('/u01/rapps/vms_tools/')

% Load the updated QC flags from the temppresraw file
load([rawflagpres_dir float_num],'presscorrect','t');

% Get an update time
nowe=now; temptime=nowe+(heuredete(nowe)/24);
temptime_str = datestr(temptime,'yyyymmddHHMMSS');

for ii_prof=1:length(t)
    
    % Input and output file names
    flnmp=[float_num '_' num2str(t(ii_prof).cycle_number,'%03d') '.nc'];
    ingested_flnm=dir([nc_dir_raw findnameofsubdir(float_num,listdirs(nc_dir_raw)) filesep '*' flnmp]); 
    clear flnm flnm_b
    if length(ingested_flnm)==2
        if strfind(ingested_flnm(1).name,'B')==1
            flnm.input=[nc_dir_raw findnameofsubdir(float_num,listdirs(nc_dir_raw)) filesep ingested_flnm(2).name];
            flnm.output=[nc_dir_out filesep ingested_flnm(2).name];
            flnm_b.input=[nc_dir_raw findnameofsubdir(float_num,listdirs(nc_dir_raw)) filesep ingested_flnm(1).name];
            flnm_b.output=[nc_dir_out filesep ingested_flnm(1).name];
        else error('Possible problem with file names');
        end
    else
        flnm.input=[nc_dir_raw findnameofsubdir(float_num,listdirs(nc_dir_raw)) filesep ingested_flnm(1).name];
        flnm.output=[nc_dir_out filesep ingested_flnm(1).name];
        flnm_b.input=[];
        flnm_b.output=[];
    end
    
    % Old flags. We don't want to update files where the flags have
    % changed, and in some casese we need to be careful about the adjusted
    % flags.
    t_old=read_nc(flnm.input);
    if ~isempty(flnm_b.input), t_old_doxy = read_nc(flnm_b.input); end
    
    % If none of the flags have changed, then we don't need to do anything.
    % Otherwise we prepare to adjust the flags
    if not(all(t(ii_prof).pres_qc==t_old.pres_qc) && all(t(ii_prof).temp_qc==t_old.temp_qc) && ...
            all(t(ii_prof).psal_qc==t_old.psal_qc) && (~isfield(t(ii_prof),'doxy') || ...
            all(t(ii_prof).doxy_qc==t_old_doxy(ii_prof).doxy_qc)))
         
        % Raw flags are taken directly from the temppresraw file
        [qc.PRES.ADJ,qc.PRES.RAW]=deal(char(t(ii_prof).pres_qc));
        [qc.TEMP.ADJ,qc.TEMP.RAW]=deal(char(t(ii_prof).temp_qc));
        [qc.PSAL.ADJ,qc.PSAL.RAW]=deal(char(t(ii_prof).psal_qc));
        if isfield(t(ii_prof),'doxy')
            [qc.DOXY.ADJ,qc.DOXY.RAW]=deal(char(t(ii_prof).doxy_qc));
            % TODO: Currently assuming the intermediate variables will not
            % have adjusted versions
            if isfield(t(ok),'temp_doxy')
                qc.TEMP_DOXY.RAW=char(t(ii_prof).temp_doxy_qc);
            end
            if isfield(t(ok),'phase_delay_doxy')
                qc.PHASE_DELAY_DOXY.RAW = char(t(ok).phase_delay_doxy_qc(x));
            end
            if isfield(t(ok),'molar_doxy')
                qc.MOLAR_DOXY.RAW = char(t(ok).molar_doxy_qc(x));
            end
        end
        
        % If we've changed a flag from '3' or '4' to '1', we need to reset
        % the adjusted values
        tem={};
        for temp_var = {'pres','temp','psal'}
            tem.(upper(temp_var{1})) = t(ii_prof).([temp_var{1},'_adjusted']);
            ii_improved = t(ii_prof).([temp_var{1},'_qc'])=='1' & t_old.([temp_var{1},'_qc'])>='3';
            if any(ii_improved)
                if all(ii_improved)
                    disp('Unable to fill in the adjusted values, can try to do it manually')
                    keyboard
                else
                    ii_temp = t_old.([temp_var{1},'_qc'])=='1';
                    if strcmp(temp_var,'psal')
                        temp_offsets = t_old.([temp_var{1},'_adjusted'])(ii_temp)./t_old.(temp_var{1})(ii_temp);
                    else
                        temp_offsets = t_old.([temp_var{1},'_adjusted'])(ii_temp)-t_old.(temp_var{1})(ii_temp);
                    end
                    if any(temp_offsets)>0 && max(temp_offsets)-min(temp_offsets) >= abs(median(temp_offsets))*0.01
                        disp('Unable to fill in the adjusted values, please fix temp_offsets')
                        keyboard
                        if any(temp_offsets)>0 && max(temp_offsets)-min(temp_offsets) >= abs(median(temp_offsets))*0.01
                            error('Still have different offsets')
                        end
                    end
                    if strcmp(temp_var,'psal')
                        tem.(upper(temp_var{1}))(ii_improved) = ...
                            t(ii_prof).(temp_var{1})(ii_improved)*median(temp_offsets);
                    else
                        tem.(upper(temp_var{1}))(ii_improved) = ...
                            t(ii_prof).(temp_var{1})(ii_improved) + median(temp_offsets);
                    end
                end
            end
        end
        
        % Apply TNPD-related flags
        if ~skip_tnpd_adj
            if presscorrect.tnpd(ii_prof)>0 &&  presscorrect.tnpd(ii_prof)<=4 %if this is a TNPD without T/S symptoms
                qc.PRES.ADJ(qc.PRES.ADJ<'2')='2';
                qc.TEMP.ADJ(qc.TEMP.ADJ<'2')='2';
                qc.PSAL.ADJ(qc.PSAL.ADJ<'2')='2';
            elseif presscorrect.tnpd(ii_prof)==5 %this is a TNPD with severe symptoms
                qc.PRES.ADJ(qc.PRES.ADJ<'4')='4';
                qc.TEMP.ADJ(qc.TEMP.ADJ<'4')='4';
                qc.PSAL.ADJ(qc.PSAL.ADJ<'4')='4';
            elseif any(t_old.pres_adjusted_qc~=t_old.pres_qc) || any(t_old.temp_adjusted_qc~=t_old.temp_qc) || ...
                    any(t_old.psal_adjusted_qc~=t_old.psal_adjusted_qc) || ...
                    (isfield(t(ii_prof),'doxy') && any(t_old_doxy.doxy_adjusted_qc~=t_old_doxy.doxy_qc))
                disp('WARNING: Non-TNPD differences in adjusted vs raw QC flags found, need manual adjustment');
                keyboard;
            end
        end
        
        % Rewrite the NC file
        rewrite_nc(flnm,tem,qc,[],temptime_str,[],[],[],'R');
        reducehistory_i(flnm.output)
        if ~isempty(flnm_b.input)
            rewrite_nc(flnm_b,tem,qc,[],temptime_str,[],[],[],'R');
            reducehistory_i(flnm_b.output)
        end
    end
 
end


end