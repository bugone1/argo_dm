function summarize_qc_flags(float_directory, float_name, is_mat)
% SUMMARIZE_FLAGS - Summarize QC flags for a given float, and save to
%   files. Three files are generated; one for each of the pressure,
%   temperature, and salinity.
%   USAGE:
%       summarize_qc_flags(float_directory, float_number, is_mat)
%   INPUTS:  
%       float_directory - Directory in which float *.nc files are located
%       float_number - Float name/number
%       is_mat - Set to 1 if getting the data from a .mat file, otherwise a
%           NetCDF file is assumed
%   VERSION HISTORY:
%       June 2017, Isabelle Gaboury: Created
%       21 Aug. 2017, IG: Expanded to include DOXY flags
%       4 Jan. 2018, IG: Fixed bug with reading of B files
%       15 May 2018, IG: Fixed issue with B files that do not have
%           temp_doxy

if nargin < 3, is_mat = 0; end

% Load the data
if is_mat  % MAT file
    load([float_directory filesep float_name '.mat'],'t');   
else  % In this case we assume NetCDF
    % Find the .nc files
    file_names=[dir([float_directory filesep 'D*' float_name '*.nc']); dir([float_directory filesep 'R*' float_name '*.nc'])];
    t=read_all_nc(float_directory,file_names,[],[0 0]);
    file_names_b=[dir([float_directory filesep 'BD*' float_name '*.nc']); dir([float_directory filesep 'BR*' float_name '*.nc'])];
    t_b=read_all_nc(float_directory,file_names_b,[],[0 0],1);
    if ~isempty(t_b)
        bfields=fieldnames(t_b);
        for ii=1:length(t)
            for ii_field=1:length(bfields)
                if ismember(bfields{ii_field},cfields) && any(t_b(ii).(bfields{ii_field})~=t(ii).(bfields{ii_field}))
                    error(['Mismatch for ii=',num2str(ii),',field ',bfields{ii_field}]);
                else
                    t(ii).(bfields{ii_field}) = t_b(ii).(bfields{ii_field});
                end
            end
        end
    end
end
n_z = 0;
n_cyc = length(t);
for ii=1:n_cyc
    if length(t(ii).pres)>n_z, n_z=length(t(ii).pres); end
end
    
% Initialize output matrices
[qc_pres, qc_temp, qc_psal] = deal(repmat(' ',n_z,n_cyc));
if isfield(t,'doxy'), qc_doxy = qc_pres; end
if isfield(t,'temp_doxy'), qc_temp_doxy=qc_pres; end
if isfield(t,'phase_delay_doxy'), qc_phase_delay_doxy = qc_pres; end
if isfield(t,'molar_doxy'), qc_molar_doxy = qc_pres; end

% Generate the summary
for ii=1:n_cyc
    qc_pres(1:length(t(ii).pres_qc),ii) = t(ii).pres_qc;
    qc_temp(1:length(t(ii).temp_qc),ii) = t(ii).temp_qc;
    qc_psal(1:length(t(ii).psal_qc),ii) = t(ii).psal_qc;
    if isfield(t,'doxy'), qc_doxy(1:length(t(ii).doxy_qc),ii) = t(ii).doxy_qc; end
    if isfield(t,'temp_doxy'), qc_temp_doxy(1:length(t(ii).temp_doxy_qc),ii) = t(ii).temp_doxy_qc; end
    if isfield(t,'phase_delay_doxy'), qc_phase_delay_doxy(1:length(t(ii).phase_delay_doxy_qc),ii) = t(ii).phase_delay_doxy_qc; end
    if isfield(t,'molar_doxy'), qc_molar_doxy(1:length(t(ii).molar_doxy_qc),ii) = t(ii).molar_doxy_qc; end
end

% % Output to file--full report. Not currently used, as this was kind of
% long to sort through
% header=[t.cycle_number];
% dlmwrite([float_name '_pres_qc.csv'], header);
% dlmwrite([float_name '_pres_qc.csv'], qc_pres, '-append');
% dlmwrite([float_name '_temp_qc.csv'], header);
% dlmwrite([float_name '_temp_qc.csv'], qc_temp, '-append');
% dlmwrite([float_name '_psal_qc.csv'], header);
% dlmwrite([float_name '_psal_qc.csv'], qc_psal, '-append');

% Output to file--brief report, only non-1 flags
fid=fopen([float_name '_qc.csv'],'w');
fprintf(fid, 'cycle,depth,variable(s),flag\n');
for ii_cyc=1:n_cyc
    for ii_z=1:n_z
        if qc_pres(ii_z,ii_cyc) > '1'
            fprintf(fid,'%d,%f,%c,%c\n',t(ii_cyc).cycle_number,t(ii_cyc).pres(ii_z),'P',qc_pres(ii_z,ii_cyc));
        end
        if qc_temp(ii_z,ii_cyc) > '1'
            fprintf(fid,'%d,%f,%c,%c\n',t(ii_cyc).cycle_number,t(ii_cyc).pres(ii_z),'T',qc_temp(ii_z,ii_cyc));
        end
        if qc_psal(ii_z,ii_cyc) > '1'
            fprintf(fid,'%d,%f,%c,%c\n',t(ii_cyc).cycle_number,t(ii_cyc).pres(ii_z),'S',qc_psal(ii_z,ii_cyc));
        end
        if isfield(t,'doxy') && qc_doxy(ii_z,ii_cyc) > '1'
            fprintf(fid,'%d,%f,%s,%c\n',t(ii_cyc).cycle_number,t(ii_cyc).pres(ii_z),'DOXY',qc_doxy(ii_z,ii_cyc));
        end
        if isfield(t,'temp_doxy') && qc_temp_doxy(ii_z,ii_cyc) > '1'
            fprintf(fid,'%d,%f,%s,%c\n',t(ii_cyc).cycle_number,t(ii_cyc).pres(ii_z),'TEMP_DOXY',qc_temp_doxy(ii_z,ii_cyc));
        end
        if isfield(t,'phase_delay_doxy') && qc_phase_delay_doxy(ii_z,ii_cyc) > '1'
            fprintf(fid,'%d,%f,%s,%c\n',t(ii_cyc).cycle_number,t(ii_cyc).pres(ii_z),'PHASE_DELAY_DOXY',qc_phase_delay_doxy(ii_z,ii_cyc));
        end
        if isfield(t,'molar_doxy') && qc_molar_doxy(ii_z,ii_cyc) > '1'
            fprintf(fid,'%d,%f,%s,%c\n',t(ii_cyc).cycle_number,t(ii_cyc).pres(ii_z),'MOLAR_DOXY',qc_molar_doxy(ii_z,ii_cyc));
        end
    end
end
fclose(fid);