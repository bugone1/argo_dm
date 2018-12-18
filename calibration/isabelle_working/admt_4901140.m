% Single-use function to plot a couple of examples for the DMQC session of
% the 2018 Argo DMQC workshop
% IG, 26 November 2018

% Setup
float_num = '4901140';
cycle_nums = [2,11];
plot_vars = {'temp','psal','dens'};
n_vars = length(plot_vars);
plot_labels = {'Temperature (^{\circ}C)', 'Salinity (psu)', 'Density (kg/m^3)'};
qc_flags = ['2','3','4'];
qc_flag_colours = ['y','m','r'];
max_z=300;

% Load the data
load('/u01/rapps/argo_dm/data/temppresraw/4900494.mat','t')

% Plots
for ii=1:length(cycle_nums)
    
    % Create the figure
    figure
    
    % Find the index
    ii_temp = find([t.cycle_number]==cycle_nums(ii));
    
    % Calculate the density
    [sal_abs,foo] = gsw_SA_from_SP(t(ii_temp).psal,t(ii_temp).pres,t(ii_temp).longitude,t(ii_temp).latitude);
    temp_cons = gsw_CT_from_t(sal_abs,t(ii_temp).temp,t(ii_temp).pres);
    dens_ct = gsw_rho_CT(sal_abs,temp_cons,mean(t(ii_temp).pres));
    
    % Plots
    for ii_plot = 1:n_vars
        subplot(1,n_vars,ii_plot)
        if strcmp(plot_vars{ii_plot},'dens')
            h=plot(dens_ct, t(ii_temp).pres,'b. -');
            ii_inv = find(dens_ct(2:end)-dens_ct(1:end-1)<=-0.01);
            ht=text(double(dens_ct(ii_inv+1))'-0.02,double(t(ii_temp).pres(ii_inv+1))',cellstr(num2str(dens_ct(ii_inv+1)'-dens_ct(ii_inv)','%0.03f')));
            set(ht,'horizontalalignment','right')
        else
            h=plot(t(ii_temp).(plot_vars{ii_plot}), t(ii_temp).pres,'b. -');
        end
        leg_text = {'QC=1'};
        for ii_qc = 1:length(qc_flags)
            ii_qc_temp = find(t(ii_temp).temp_qc==qc_flags(ii_qc) | t(ii_temp).psal_qc==qc_flags(ii_qc));
            if ~isempty(ii_qc_temp)
                leg_text{end+1} = ['QC=' qc_flags(ii_qc)];
                if strcmp(plot_vars{ii_plot},'dens')
                    h(end+1)=plot(dens_ct(ii_qc_temp), t(ii_temp).pres(ii_qc_temp), [qc_flag_colours(ii_qc) '.']);
                else
                    h(end+1)=plot(t(ii_temp).(plot_vars{ii_plot})(ii_qc_temp), t(ii_temp).pres(ii_qc_temp), [qc_flag_colours(ii_qc) '.']);
                end
            end
        end
        set(gca,'ylim',[0 max_z],'ydir','rev'); grid on; hold on
        set(h(1),'linewidth',2);
        set(h,'markersize',15);
        xlabel(plot_labels{ii_plot}); ylabel('Pressure (dBar)');
        if ii_plot==ceil(n_vars/2)
            title([float_num ' cycle ' num2str(cycle_nums(ii))],'fontweight','bold')
        end
        if ii_plot==n_vars, legend(leg_text,'location','SouthWest'); end
    end
end
    

%end