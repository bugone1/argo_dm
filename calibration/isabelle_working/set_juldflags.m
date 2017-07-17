function set_juldflags(nc_dir,floatname,flag,profile_nums)
% SET_JULDFLAGS - Update the JULD_QC flags for a given float
%   INPUTS:
%       local_config_file - DMQC configuration file
%       nc_dir - Directory in which the NetCDF files are found (either "R"
%           or "D" files)
%       floatname - Float number, as a string
%       flag - Flag to which the JULD_QC variable should be set
%       profile_nums - List of profile numbers, as integers; if not
%           provided, all profiles are updated
%   VERSION HISTORY:
%       6 July 2017, Isabelle Gaboury - Created

% Check that the flag is a character
if ~ischar(flag), flag=num2str(flag); end

% Check what files are available in the directory
files_all = dir([nc_dir filesep '*' floatname '*.nc']);
file_names_all={files_all.name};

% Based on the file names found, convert the profile numbers to a cell
% array of strings. We assume the file names have only one underscore and
% one period
n_digits = findstr(file_names_all{1},'.') - findstr(file_names_all{1},'_') - 1;
profile_suffixes = num2str(profile_nums(:),['%0' num2str(n_digits) 'i']);

% Create the list of files to process
files_to_process = cell(1,length(profile_nums));
for ii=1:length(profile_nums)
    ii_file = ~cellfun(@isempty,regexp(file_names_all,['[RD]' floatname '_' profile_suffixes(ii,:) '.nc']));
    files_to_process{ii} = [nc_dir filesep file_names_all{ii_file}];
end
   
% For each file to process, rewrite with the JULD flag altered
for ii=1:length(profile_nums)
    nc_file=netcdf.open(files_to_process{ii},'WRITE');
    var_id = netcdf.inqVarID(nc_file,'JULD_QC');
    netcdf.putVar(nc_file,var_id,flag);
    netcdf.close(nc_file);
end

end