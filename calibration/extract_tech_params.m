function data = extract_tech_params(techfile);
% EXTRACT_TECH_PARAMS Extract parameters from a tech file and optionally
%   write to CSV
%   USAGE: data = extract_tech_params(techfile, outfile)
%   INPUTS:
%       techfile - name (including path) of the techfile to read
%   OUTPUTS:
%       data - structure of technical data
%   VERSION HISTORY:
%       Isabelle Gaboury, 28 Nov. 2017: Created

% Load the data from the file
nc=netcdf.open(techfile,'nowrite');
cyc_all=netcdf.getVar(nc,netcdf.inqVarID(nc,'CYCLE_NUMBER'))';
names=lower(netcdf.getVar(nc,netcdf.inqVarID(nc,'TECHNICAL_PARAMETER_NAME')))';
values=lower(netcdf.getVar(nc,netcdf.inqVarID(nc,'TECHNICAL_PARAMETER_VALUE')))';
netcdf.close(nc);

% Reformat into the output structure
data = struct('cycle_number', unique(cyc_all));
ncyc = length(data.cycle_number);
for ii_cyc = 1:ncyc
    cyc_data_ii = find(cyc_all==data.cycle_number(ii_cyc));
    param_names_temp = unique(names(cyc_data_ii,:),'rows');
    for ii_param = 1:size(param_names_temp,1)
        temp_field = deblank(param_names_temp(ii_param,:));
        val_ii = strmatch(temp_field,names(cyc_data_ii,:));
        if ~isfield(data,temp_field)
            data.(temp_field) = zeros(length(val_ii),ncyc)*NaN;
        end
        data.(temp_field)(:,ii_cyc) = str2double(values(cyc_data_ii(val_ii),:));
    end
end 

end