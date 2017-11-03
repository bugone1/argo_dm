function check_densities(float_num)
% CHECK_DENSITIES Quick check for density inversions
% Routine assumes the mat file has already been created
% Isabelle Gaboury, 12 Sep. 2017

% Required paths
addpath('/u01/rapps/gsw');
addpath('/u01/rapps/gsw/library');

% Setup
data_dir = '../data/temppresraw';

% Load the data
load([data_dir filesep float_num '.mat'],'t');

% Calculate the potential density
for ii_prof=1:length(t)
    [sal_abs,foo] = gsw_SA_from_SP(t(ii_prof).psal,t(ii_prof).pres,t(ii_prof).longitude,t(ii_prof).latitude);
    temp_cons = gsw_CT_from_t(sal_abs,t(ii_prof).temp,t(ii_prof).pres);
    dens_ct = gsw_rho_CT(sal_abs,temp_cons,mean(t(ii_prof).pres));
    dens_ct_diff = diff(dens_ct);
    ii_inv = find(dens_ct_diff<=-0.03);
    if ~isempty(ii_inv)
        t(ii_prof).temp_qc(ii_inv) = '4';
        t(ii_prof).psal_qc(ii_inv) = '4';
        t(ii_prof).temp_qc(ii_inv+1) = '4';
        t(ii_prof).psal_qc(ii_inv+1) = '4';
        if isfield(t,'doxy_qc')
            t(ii_prof).doxy_qc(ii_inv) = '4';
            t(ii_prof).doxy_qc(ii_inv+1) = '4';
        end
    end
    save([data_dir filesep float_num '.mat'],'t','-append');
end