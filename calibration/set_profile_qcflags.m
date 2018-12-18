function set_profile_qcflags(nc_dir,float_name,var_name,flag,profile_nums,apply_to_core,apply_to_bfiles,apply_to_trajfile,traj_nc_dir)
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
%       apply_to_bfiles - Set to 0 to not apply to b-files
%       apply_to_trajfile - Set to 1 to apply to the trajectory file
%   VERSION HISTORY:
%       17 July 2017, Isabelle Gaboury - Created to deal with position QC
%           flags
%       26 July 2017, IG: Generalized to deal with both POSITION_QC and
%           JULD_QC (and to make it possible to expand to other variables
%           later)
%       14-17 Aug. 2017, IG: Expanded to handle
%           var_name='PARAMETER_DATA_MODE', added apply_to_core and
%           apply_to_bfiles flags
%       28 Aug. 2018, IG: Now updating the update date and history
%       

% By default we process all the files
if nargin<6, apply_to_core=1; end
if nargin<7, apply_to_bfiles=1; end
if nargin<8, apply_to_trajfile=0; end
if nargin<9
    if nargin==8, error('Please supply the trajectory NetCDF directory');
    else traj_nc_dir='';
    end
end

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
if apply_to_trajfile==1
    foo = dir([traj_nc_dir filesep '*' float_name '*.nc']);
    if isempty(foo)
        file_traj=[];
    elseif length(foo)>1
        error('Problem finding trajectory files');
    else
        file_traj = [traj_nc_dir filesep foo.name];
    end
        
end

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

% Prepare the update time
nowe=now;temptime=nowe+(heuredete(nowe)/24);
DATE_CAL = sprintf('%4.4i%2.2i%2.2i%2.2i%2.2i%2.2i',round(datevec(date)));

% For each file to process, rewrite with the QC flag altered (as well as
% the update date)
for ii=1:length(files_to_process)
    nc_file=netcdf.open(files_to_process{ii},'WRITE');
    % Get the old flag
    old_flag = netcdf.getVar(nc_file,netcdf.inqVarID(nc_file,var_name));   
    % Write the new flag
    var_id = netcdf.inqVarID(nc_file,var_name);
    netcdf.putVar(nc_file,var_id,flag);
    netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'DATE_UPDATE'),datestr(temptime,'yyyymmddHHMMSS'));
    % Add to the history
    update_history(nc_file,var_name,old_flag,flag,DATE_CAL);
    netcdf.close(nc_file);
end

% % Optionally also modify the trajectory file
% I had started experimenting with this, but for now Anh regenerates these,
% so temporarily set aside
% if apply_to_trajfile==1
%    nc_file=netcdf.open(file_traj,'WRITE');
%    cycle_numbers = netcdf.getVar(nc_file,netcdf.inqVarID(nc_file,'CYCLE_NUMBER'))';
%    var_id = netcdf.inqVarID(nc_file,var_name);
%    traj_flags = netcdf.getVar(nc_file,var_id)';
%    ii_to_change = ismember(cycle_numbers,profile_nums);
%    traj_flags(ii_to_change)=flag;
%    netcdf.putVar(nc_file,var_id,traj_flags);
%    netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'DATE_UPDATE'),datestr(temptime,'yyyymmddHHMMSS'));
%    update_nc_history(nc_file,'set_flag',DATE_CAL,var_name);
%    netcdf.close(nc_file);
% end

end

function update_history(nc_file,var_name,old_flag,new_flag,DATE_CAL)

    % Get the HISTORY_ACTION, get the number of existing records
    historyactionid=netcdf.inqVarID(nc_file,'HISTORY_ACTION');
    [varname,xtype,dimids]=netcdf.inqVar(nc_file,historyactionid);
    clear di dj
    for i=1:length(dimids)
        [tr,di(i)]=netcdf.inqDim(nc_file,dimids(i));
        if strcmp(tr,'N_HISTORY')
            i_history=i;
        elseif strcmp(tr,'N_PROF')
            i_prof=i;
        else
            i_parlen=i;
        end
    end
    dj=di*0;
    n_history=di(i_history);
       
    % Note the changes to the time or position QC
    if strcmp(var_name,'JULD_QC'), history_vars={'TIME'};
    elseif strcmp(var_name,'POSITION_QC'), history_vars={'LAT$','LON$'};
    else history_vars = {};
    end
    if ~strcmp(old_flag,new_flag)
        for ii_var=1:length(history_vars)
            n_history=n_history+1;
            dj(i_history)=n_history-1;
            di(i_history)=1;
            di(i_parlen)=4;
            netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'HISTORY_INSTITUTION'),dj,di,netstr('ME',4));
            netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'HISTORY_STEP'),dj,di,netstr('ARSQ',4));
            netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'HISTORY_ACTION'),dj,di,netstr('CF',4));
            netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'HISTORY_SOFTWARE'),dj,di,netstr('',4));
            netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'HISTORY_SOFTWARE_RELEASE'),dj,di,netstr('',4));
            di(i_parlen)=14;
            netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'HISTORY_DATE'),dj,di,netstr(DATE_CAL,di(i_parlen)));
            di(i_parlen)=16;
            try
                netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'HISTORY_PARAMETER'),dj,di,netstr(history_vars{ii_var},di(i_parlen)));
            catch
                di(i_parlen)=4;
                netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'HISTORY_PARAMETER'),dj,di,netstr(history_vars{ii_var},di(i_parlen)));
            end
            ok=[i_prof i_history];
            netcdf.putVar(nc_file,netcdf.inqVarID(nc_file,'HISTORY_PREVIOUS_VALUE'),dj(ok),di(ok),single(str2num(old_flag)));
        end
    end

end
