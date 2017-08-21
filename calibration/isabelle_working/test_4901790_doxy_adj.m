% function test_4901790_doxy_adj
% Simple-purpose script to test DOXY adjustment for float 4901790
% IG, 16 Aug. 2017

% Setup
floatname = '4901790';
params = struct('A0',1.0513, 'A1',-1.5000e-003, 'A2',4.3870e-001, ...
    'B0',-2.3493e-001, 'B1',1.6975, 'C0',9.9072e-002, 'C1',4.2014e-003, ...
    'C2',5.6472e-005, 'E',1.1000e-002, 'pcoef1',0.115, 'pcoef2',0.00022, ...
    'pcoef3',0.0419, 'D0',24.4543, 'D1',-67.4509, 'D2',-4.8489, 'D3',-5.44e-4, ...
    'psal_preset',0, 'solB0',-6.24523e-3, 'solB1',-7.37614e-3, ...
    'solB2',-1.03410e-3, 'solB3',-8.17083e-3, 'solC0',-4.88682e-7);
man_acc_abs = 3.0;
man_acc_perc = 2.0;
ii_cyc_plot = [1,70,77];

% Add a couple of needed paths
if ~ispc
    addpath('/u01/rapps/argo_dm/calibration');
    addpath('/u01/rapps/vms_tools');
    ncdir = '/u01/rapps/argo_dm/calibration/output/changed/';
%     ncdir = '/u01/rapps/argo_dm/calibration/data/4901000/';
else
    addpath('w:\argo_dm\calibration');
    addpath('w:\vms_tools');
    ncdir = 'W:\argo_dm\calibration\output\changed\';
%     ncdir = 'W:\argo_dm\calibration\data\4901000\';
end

% Get the list of files
files_core = dir([ncdir filesep 'D' floatname '*.nc']);
files_b = dir([ncdir filesep 'BD' floatname '*.nc']);
names = char(files_core.name);
names_b = char(files_b.name);
if  any(any(names~=names_b(:,2:end)))
    error('Current version of the code requires that core and b files match exactly');
end

% Read in the adjusted data
% t=read_all_nc(ncdir,files_core,[],[0,0],0);
% t_b=read_all_nc(ncdir,files_b,[],[0,0],1);
lt=length(t);
max_nz = 0;
for ii=1:lt, max_nz = max(max_nz,length(t(ii).pres)); end

% Original DOXY, and check of our routine
[pres,doxy_orig,doxy_orig_recalc,doxy_adj] = deal(zeros(max_nz,lt).*NaN);
doxy_err_mo = zeros(1,lt)*NaN;
for ii=1:lt
    
    ii_temp = 1:length(t(ii).pres);
    
    % Pressure
    pres(ii_temp,ii) = t(ii).pres;
    
    % Original DOXY
    doxy_orig(ii_temp,ii) = t_b(ii).doxy;
    
    % Recalculate doxy using Anh's equation
    doxy_orig_recalc(ii_temp,ii)  = calc_doxy(t(ii).pres,...
        t(ii).temp,t(ii).psal,t_b(ii).temp_doxy,t_b(ii).phase_delay_doxy,params);
    
    % Adjusted version
    doxy_adj(ii_temp,ii) = calc_doxy(t(ii).pres_adjusted,...
        t(ii).temp_adjusted,t(ii).psal_adjusted,t_b(ii).temp_doxy,t_b(ii).phase_delay_doxy,params);
    
    % Mathieu's error calculation
    doxy_temp_1 = calc_doxy(t(ii).pres_adjusted,...
        t(ii).temp_adjusted-t(ii).temp_adjusted_error,...
        t(ii).psal_adjusted-t(ii).psal_adjusted_error, ...
        t_b(ii).temp_doxy,t_b(ii).phase_delay_doxy,params);
    doxy_temp_2 = calc_doxy(t(ii).pres_adjusted,...
        t(ii).temp_adjusted+t(ii).temp_adjusted_error,...
        t(ii).psal_adjusted+t(ii).psal_adjusted_error, ...
        t_b(ii).temp_doxy,t_b(ii).phase_delay_doxy,params);
    doxy_temp_3 = calc_doxy(t(ii).pres_adjusted,...
        t(ii).temp_adjusted-t(ii).temp_adjusted_error,...
        t(ii).psal_adjusted+t(ii).psal_adjusted_error, ...
        t_b(ii).temp_doxy,t_b(ii).phase_delay_doxy,params);
    doxy_temp_4 = calc_doxy(t(ii).pres_adjusted,...
        t(ii).temp_adjusted+t(ii).temp_adjusted_error,...
        t(ii).psal_adjusted-t(ii).psal_adjusted_error, ...
        t_b(ii).temp_doxy,t_b(ii).phase_delay_doxy,params);
    ok = t(ii).pres_adjusted_qc < '3' & t(ii).temp_adjusted_qc < '3' & ...
        t(ii).psal_adjusted_qc <'3';
    doxy_err_mo(ii) = max([max(doxy_temp_1(ok)'-doxy_adj(ok,ii)), max(doxy_temp_2(ok)'-doxy_adj(ok,ii)),...
        max(doxy_temp_3(ok)'-doxy_adj(ok,ii)), max(doxy_temp_4(ok)'-doxy_adj(ok,ii))]);
end

% Some possible errors
err_adjdiff = max(doxy_adj-doxy_orig_recalc);
err_man = max(doxy_adj*man_acc_perc/100.0);
err_man(err_man<man_acc_abs)=man_acc_abs;

% Plot the result for the first and final profiles
n_plots = length(ii_cyc_plot);
for ii=1:n_plots
    subplot(1,n_plots+1,ii);
    plot(t_b(ii_cyc_plot(ii)).doxy,t_b(ii_cyc_plot(ii)).pres,'b',...
        doxy_orig_recalc(1:length(t_b(ii_cyc_plot(ii)).pres),ii_cyc_plot(ii)), t_b(ii_cyc_plot(ii)).pres,'r');
    xlabel('DOXY'); ylabel('PRES'); title(['Cycle ' num2str(t(ii_cyc_plot(ii)).cycle_number)]);
    legend('Original','Recalculated','location','southeast');
    set(gca,'ylim',[0 2000],'ydir','rev'); grid on;
    disp(['Cycle ' num2str(t(ii_cyc_plot(ii)).cycle_number) ' max abs difference: ' ...
        num2str(max(abs(t_b(ii_cyc_plot(ii)).doxy'-doxy_orig_recalc(1:length(t_b(ii_cyc_plot(ii)).pres),ii_cyc_plot(ii)))))])
end
adj_diffs = doxy_adj(:,ii_cyc_plot) - doxy_orig_recalc(:,ii_cyc_plot);
subplot(1,n_plots+1,n_plots+1);
plot(adj_diffs,pres(:,ii_cyc_plot));
set(gca,'ylim',[0,2000],'ydir','rev'); grid on;
xlabel('DOXY\_ADJUSTED-DOXY'); ylabel('PRES');
title('Adjusted vs. original');
legend(num2str([t(ii_cyc_plot).cycle_number]'),'location','southeast')

% Plot the errors
figure
plot([t.cycle_number],err_man,[t.cycle_number],err_adjdiff,[t.cycle_number],doxy_err_mo);
legend('Manufacturer default','Adjusted-original','TS errors');
xlabel('Cycle number'); ylabel('Error'); title('DOXY errors');
grid on

% end

function doxy = calc_doxy(pres,temp,psal,temp_doxy,phase_delay_doxy,params)

    % Calculate DOXY in uMol/m^3
    V = (phase_delay_doxy + params.pcoef1 * pres/1000)/39.457071;
    Ksv = params.C0 + params.C1*temp_doxy + params.C2 * temp_doxy.^2;
    ro_water_s = 1013.25 * exp(params.D0 + params.D1 * (100./(temp + 273.15)) ...
            + params.D2 * log((temp + 273.15)/100) + params.D3 * psal);
    ro_water_spreset = 1013.25 * exp(params.D0 + params.D1 * (100./(temp + 273.15)) ... 
            + params.D2 * log((temp + 273.15)/100) + params.D3 * params.psal_preset);
    A = (1013.25 - ro_water_spreset)./(1013.25 - ro_water_s);
    Ts = log((298.15-temp)./(273.15+temp));
    Scorr = A .* exp(psal .*(params.solB0 +params.solB1*Ts + params.solB2* Ts.^2 ... 
            + params.solB3*Ts.^3) + params.solC0 * psal.^2);
    Pcorr = 1 + (((params.pcoef2 *temp + params.pcoef3).*pres)/1000);
    doxy = ((((params.A0 + params.A1*temp_doxy + params.A2 * V.^2)./ ...
        (params.B0 +params.B1*V)) - 1)./Ksv).*Scorr .*Pcorr * 44.6596;
    
    % Convert to uMol/kg
    % Calculating density of pure water
    dw = 0.999842594 + 6.793952e-5 *temp - 9.095290e-6*temp.^2 + ...
        1.001685e-7*temp.^3 - 1.120083e-9*temp.^4 + 6.536332e-12*temp.^5;
    A = 8.24493e-4 - 4.0899e-6*temp + 7.6438e-8*temp.^2 - ...
        8.2467e-10*temp.^3 + 5.3875e-12 *temp.^4;
    B = -5.72466e-6 + 1.0227e-7*temp - 1.6546e-9*temp.^2;
    C = 4.8314e-7;
    dsw = dw + A.*psal + B.*psal.^1.5 + C .* psal.^2;
    doxy = doxy./(dsw*1000)*1000;
end