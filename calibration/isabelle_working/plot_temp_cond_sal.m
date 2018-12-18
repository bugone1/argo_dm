function plot_temp_cond_sal(mat_dir,float_num,cycle_num)
% Quick and dirty script to plot temperature, conductivity, and salinity
% for a float
% Isabelle Gaboury, 01 Nov. 2018

% Parameters
ITS90toIPTS68=1.00024;

% Load the data, find the desired cycle index
load([mat_dir,filesep,float_num,'.mat'])
ii_cyc=find([t.cycle_number]==cycle_num);

% Calculate the conductivity, adjust the salinity for the corrected
% pressure.
cndc = sw_cndr(t(ii_cyc).psal,t(ii_cyc).temp*ITS90toIPTS68,t(ii_cyc).pres);

% Plots
subplot(1,3,1);
h(1)=plot(t(ii_cyc).temp,t(ii_cyc).pres);
xlabel('temperature'); ylabel('pres'); grid on; set(gca,'ydir','rev');
subplot(1,3,2);
h(2)=plot(cndc,t(ii_cyc).pres);
xlabel('conductivity'); ylabel('pres'); grid on; set(gca,'ydir','rev');
title([float_num,' cycle ',num2str(cycle_num)],'fontweight','bold');
subplot(1,3,3);
h(3)=plot(t(ii_cyc).psal,t(ii_cyc).pres);
xlabel('salinity'); ylabel('pres'); grid on; set(gca,'ydir','rev');
set(h,'linewidth',2,'marker','.','markersize',20)
end