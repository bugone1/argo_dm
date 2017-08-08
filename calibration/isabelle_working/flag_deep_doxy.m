function flag_deep_doxy(floatname)
% FLAG_DEEP_DOXY Flag DOXY variables for depths greater than 2000m, as
%   recommended in the biogeochemical QC manual. This should be done at the
%   user's discretion, however, as this test seems to have been taken out
%   of the oxygen QC manual.
%   INPUTS:
%       floatname - Float number, as a string
%   OUTPUTS:
%       None, but the .mat file is updated
%   VERSION HISTORY:
%       03 Aug. 2017, Isabelle Gaboury: Created

% Get the float path, based on the name and the local configuration
local_config=load_configuration('local_OW.txt');
fname=[local_config.RAWFLAGSPRES_DIR floatname];

% Load the data. The .mat file must already have been created
if exist([fname '.mat'],'file')
    load(fname,'t','presscorrect');
else
    error('File name not found');
end

% Find the doxy fields
fields = fieldnames(t);
fields_doxy = fields(~cellfun(@isempty,strfind(fields,'doxy')) & ...
    cellfun(@isempty,strfind(fields,'adjusted')) & cellfun(@isempty,strfind(fields,'qc')));

% Iterate through the profiles, looking for points greater than 2000 m
for ii_prof=1:length(t)
    ok = t(ii_prof).pres > 2000;
    if any(ok)
        for ii_var=1:length(fields_doxy)
            temp_qc_field = [fields_doxy{ii_var} '_qc'];
            if strcmp(fields_doxy{ii_var},'temp_doxy')
                t(ii_prof).temp_doxy_qc(ok & t(ii_prof).temp_doxy_qc<'2') = '2';
            else
                t(ii_prof).(temp_qc_field)(ok & t(ii_prof).(temp_qc_field) < '3') = '3';
            end
        end
    end
end

% Save back to file
save(fname,'t','presscorrect');

end