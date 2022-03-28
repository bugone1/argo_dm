function set_deep_flags(floatname, var_names, flag_values, force_flags)
% SET_DEEP_FLAGS Flag variables for depths greater than 2000m. This is an
%   optional step, and is not always needed; please see the QC manuals for
%   details. This routines operates on the .mat file
%   INPUTS:
%       floatname - Float number, as a string
%       var_names - Names of the variables to alter
%       flag_values - Values to use, one per element of var_names. If only
%           a single value is provided then it is used for all variables
%       force_flags - Overwrite existing values even if they're greater than
%           the flag_values
%   OUTPUTS:
%       None, but the .mat file is updated
%   VERSION HISTORY:
%       03 Aug. 2017, Isabelle Gaboury: Created
%       13 Sep. 2017, IG: Expanded to handle both core and b-files
%       12 Feb. 2018, IG: Added the force_flags option

if nargin<4, force_flags=0; end

% Get the float path, based on the name and the local configuration
local_config=load_configuration('local_OW_v2.txt');
fname=[local_config.RAWFLAGSPRES_DIR floatname];

% Check the flag_values
if length(flag_values)==1 && length(var_names)>1
    foo = flag_values;
    flag_values = cell(1,length(var_names));
    [flag_values{:}] = deal(foo);
end

% Load the data. The .mat file must already have been created
if exist([fname '.mat'],'file')
    load(fname,'t','presscorrect');
else
    error('File name not found');
end

% % Find the doxy fields
% fields = fieldnames(t);
% fields_doxy = fields(~cellfun(@isempty,strfind(fields,'doxy')) & ...
%     cellfun(@isempty,strfind(fields,'adjusted')) & cellfun(@isempty,strfind(fields,'qc')));

% Iterate through the profiles, looking for points greater than 2000 m
for ii_prof=1:length(t)
    ok = t(ii_prof).pres > 2000;
    if any(ok)
        for ii_var=1:length(var_names)
            temp_qc_field = [var_names{ii_var} '_qc'];
            if force_flags==1
                t(ii_prof).(temp_qc_field)(ok) = flag_values{ii_var};
            else
                t(ii_prof).(temp_qc_field)(ok & t(ii_prof).(temp_qc_field)<flag_values{ii_var}) = flag_values{ii_var};
            end
%             if strcmp(fields_doxy{ii_var},'temp_doxy')
%                 t(ii_prof).temp_doxy_qc(ok & t(ii_prof).temp_doxy_qc<'2') = '2';
%             else
%                 t(ii_prof).(temp_qc_field)(ok & t(ii_prof).(temp_qc_field) < '3') = '3';
%             end
        end
    end
end

% Save back to file
save(fname,'t','presscorrect');

end