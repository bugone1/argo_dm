function fix_dimflags(floatdir, floatname)
% FIX_DIMFLAGS: For a float with N_HISTORY set to a fixed number, restore the correct
%   UNLIMITED dimension
%   USAGE: fix_dimflags(floatdir,floatname)
%   VERSION HISTORY:
%       Created by Isabelle Gaboury, 12 July 2017

% Check what files are available in the directory
files = dir([floatdir filesep '*' floatname '*.nc']);

% For each file, check the dimension, and if necessary change it
for ii_file=1:length(files)
    % Check the contents of the file
    temp_file = [floatdir filesep files(ii_file).name];
    f1=netcdf.open(temp_file,'NOWRITE');
    [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(f1);
    netcdf.close(f1);
    % If there's no unlimited dimension we need to redimension the history
    if unlimdimid == -1
        display(['Fixing the dimension on ' files(ii_file).name]); 
        copy_nc_redim(temp_file,[temp_file '.temp'],'N_HISTORY','unlimited');
        movefile([temp_file '.temp'], temp_file);
    end
end

end