function plot_potential_density(float_directory,float_num,profile_num, is_mat)
% PLOT_POTENTIAL_DENSITY - Plot the profile of potential density for a
%   given float and profile. 
%   USAGE:
%       plot_potential_density(float_num,profile_num)
%   INPUTS:
%       float_directory - Directory in which the data are located
%       float_num - Float number, as a string
%       profile_num - Profile number
%       is_mat - Set to 1 if getting the data from a .mat file, otherwise a
%           NetCDF file is assumed
%   VERSION HISTORY:
%       22 June 2017, Isabelle Gaboury: Created

% Add the GSW toolbox to the path
addpath('/u01/rapps/gsw/');
addpath('/u01/rapps/gsw/library');

% Load the data
if nargin < 3 && is_mat  % MAT file
    load([float_directory filesep float_num '.mat'],'t');   
    cycle_nums = [t.cycle_number];
    ii=find(cycle_nums==profile_num);
    if isempty(ii), error('Requested profile not found'); end
    t = t(ii);
else  % In this case we assume NetCDF
    t = read_nc([float_directory filesep 'R' float_num '_' num2str(profile_num,'%03d') '.nc']);
end

% Calculate the potential density
[sal_abs, foo] = gsw_SA_from_SP(t.psal,t.pres,t.longitude,t.latitude);
temp_cons = gsw_CT_from_t(sal_abs,t.temp,t.pres);
dens_ct = gsw_rho_CT(sal_abs,temp_cons,mean(t.pres));

% Plot the potential density
plot(dens_ct-1000.0,t.pres,'. -');
set(gca,'ydir','rev');
grid on;
xlabel('Potential density (kg/m^3)');
ylabel('Pressure (dBar)');
title([float_num ' cycle ' num2str(t.cycle_number)]);

end
