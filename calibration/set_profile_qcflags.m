function set_profile_qcflags(nc_dir,float_name,var_name,flag,profile_nums,apply_to_core,apply_to_bfiles)
% SET_PROFILE_QCFLAGS Update QC flags for the position or date for a
%   given float
%   INPUTS:
%       nc_dir - Directory in which the NetCDF files are found (either "R"
%           or "D" files)
%       float_name - Float number, as a string
%       var_name - Variable name. Currently only supports 'POSITION_QC',
%           'JULD_QC', and'PARAMETER_DATA_MODE' (case-sensitive)
%       flag - Value to which the variable should be set
%       profile_nums - List of profile numbers, as integers; if not
%           provided, all profiles are updated
%       apply_to_core - Set to 0 to not apply to core files
%       apply_to_bfiles -Set to 0 to not apply to b-files
%   VERSION HISTORY:
%       17 July 2017, Isabelle Gaboury - Created to deal with position QC
%           flags
%       26 July 2017, IG: Generalized to deal with both POSITION_QC and
%           JULD_QC (and to make it possible to expand to other variables
%           later)
%       14-17 Aug. 2017, IG: Expanded to handle
%           var_name='PARAMETER_DATA_MODE', added apply_to_core and
%           apply_to_bfiles flags

% By default we process all the files
if nargin<6, apply_to_core=1; end
if nargin<7, apply_to_bfiles=1; end

% Check that we're only setting one of the two variables that this routine
% is currently tested for. The script should be pretty general, so this
% reflects testing rather than expected usability.
if ~ismember(var_name, {'POSITION_QC','JULD_QC','PARAMETER_DATA_MODE'})
    error('Script only tested for POSITION_QC, JULD_QC, and PARAMETER_DATA_MODE');
end

% Check that the flag is a character
if ~ischar(flag), flag=num2str(flag); end

% Check what files are available in the directory
files_all = dir([nc_dir filesep '*' float_name '*.nc']);
file_names_all={files_all.name};

% Based on the file names found, convert the profile numbers to a cell
% array of strings. We assume the file names have only one underscore and
% one period
n_digits = strfind(file_names_all{1},'.') - strfind(file_names_all{1},'_') - 1;
profile_suffixes = num2str(profile_nums(:),['%0' num2str(n_digits) 'i']);

% Create the list of files to process, which may include B-files
foo=findstr(file_names_all{1},'B');
if ~isempty(foo) && foo==1 && apply_to_core==1 && apply_to_bfiles==1
    files_to_process = cell(1,length(profile_nums)*2);
else files_to_process = cell(1,length(profile_nums));
end
lp = length(profile_nums);
if apply_to_core==1, n_b_start=lp;
else n_b_start = 0;
end
for ii=1:lp
    ii_file = find(~cellfun(@isempty,regexp(file_names_all,['[RD]' float_name '_' profile_suffixes(ii,:) '.nc'])));
    if apply_to_core==1
        if length(ii_file)==2
            files_to_process{ii} = [nc_dir filesep file_names_all{ii_file(2)}];
        else
            files_to_process{ii} = [nc_dir filesep file_names_all{ii_file(1)}];
        end
    end
    if apply_to_bfiles==1 && length(ii_file)==2
        files_to_process{n_b_start+ii} = [nc_dir filesep file_names_all{ii_file(1)}];
    end
end
  
% For each file to process, rewrite with the QC flag altered
for ii=1:length(files_to_process)
    nc_file=netcdf.open(files_to_process{ii},'WRITE');
    var_id = netcdf.inqVarID(nc_file,var_name);
    netcdf.putVar(nc_file,var_id,flag);
    netcdf.close(nc_file);
end


end