function summarize_qc_flags(float_directory, float_name, is_mat)
% SUMMARIZE_FLAGS - Summarize QC flags for a given float, and save to
%   files. Three files are generated; one for each of the pressure,
%   temperature, and salinity.
%   USAGE:
%       summarize_qc_flags(float_directory, float_number, output_file)
%   INPUTS:  
%       float_directory - Directory in which float *.nc files are located
%       float_number - Float name/number
%       is_mat - Set to 1 if getting the data from a .mat file, otherwise a
%           NetCDF file is assumed
%   VERSION HISTORY:
%       June 2017, Isabelle Gaboury: Created

if nargin < 3, is_mat = 0; end

% Load the data
if is_mat  % MAT file
    load([float_directory filesep float_name '.mat'],'t');   
else  % In this case we assume NetCDF
    % Find the .nc files
    file_names=dir([float_directory filesep '*' float_name '*.nc']);
    t=read_all_nc(float_directory,file_names,[],[0 0]);
end
n_z = 0;
n_cyc = length(t);
for ii=1:n_cyc
    if length(t(ii).pres)>n_z, n_z=length(t(ii).pres); end
end
    
% Initialize output matrices
qc_pres = repmat(' ',n_z,n_cyc);
qc_temp = qc_pres;
qc_psal = qc_pres;

% Generate the summary
for ii=1:n_cyc
    qc_pres(1:length(t(ii).pres_qc),ii) = t(ii).pres_qc;
    qc_temp(1:length(t(ii).temp_qc),ii) = t(ii).temp_qc;
    qc_psal(1:length(t(ii).psal_qc),ii) = t(ii).psal_qc;
end

% Output to file
header=[t.cycle_number];
dlmwrite([float_name '_pres_qc.csv'], header);
dlmwrite([float_name '_pres_qc.csv'], qc_pres, '-append');
dlmwrite([float_name '_temp_qc.csv'], header);
dlmwrite([float_name '_temp_qc.csv'], qc_temp, '-append');
dlmwrite([float_name '_psal_qc.csv'], header);
dlmwrite([float_name '_psal_qc.csv'], qc_psal, '-append');

end