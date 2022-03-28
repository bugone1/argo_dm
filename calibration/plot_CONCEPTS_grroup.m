clear all;
addpath('C:\Users\maz\Desktop\MEDS Project\m_map');
% nax=[-75 -35];
% nay=[30 66];
%nax=[-170 -50];
%nay=[66 86];
nax=[-165 -120];
nay=[36 66];
file='C:\Users\maz\Desktop\MEDS Project\argo_dm\calibration\ETOPO1_Bed_c_gmt4.grd';
nctopo=netcdf.open(file,'NC_NOWRITE');
varid=netcdf.inqVarID(nctopo,'x');
x_topo=netcdf.getVar(nctopo,varid);
varid=netcdf.inqVarID(nctopo,'y');
y_topo=netcdf.getVar(nctopo,varid);
%  klx=find(x_topo<=-30&x_topo>=-80);
%  kly=find(y_topo<=70&y_topo>=20);
%klx=find(x_topo<=-45&x_topo>=-175);
%kly=find(y_topo<=88&y_topo>=64);
 klx=find(x_topo<=-110&x_topo>=-170);
 kly=find(y_topo<=70&y_topo>=30);
[lon_topo1, lat_topo1]=meshgrid(x_topo(klx),y_topo(kly));
varid=netcdf.inqVarID(nctopo,'z');
topo_new1=netcdf.getVar(nctopo,varid,[min(klx)-1 min(kly)-1],[numel(klx) numel(kly)])';
% klx1=find(x_topo<=-120&x_topo>=-160);
% kly1=find(y_topo<=60&y_topo>=35);
% [lon_topo2, lat_topo2]=meshgrid(x_topo(klx1),y_topo(kly1));
% topo_new2=netcdf.getVar(nctopo,varid,[min(klx1)-1 min(kly1)-1],[numel(klx1) numel(kly1)])';
netcdf.close(nctopo);

zx=[50 200 1000:500:5000];
figure('position',[30 30 700 550]);
ax=axes('Position',[0.05 0.05 0.9 0.75]);
% m_proj('miller','lat',[20 70],'lon',[-80 -30]);
%m_proj('miller','lat',[64 88],'lon',[-175 -45]);
m_proj('miller','lat',[30 70],'lon',[-170 -110]);
hold on;
m_grid('fontsize',6,'tickdir','out','yaxislocation','right','xaxislocation','bottom','xlabeldir','middle','ticklen',.01);
hold on;
[cs ch]=m_contourf(lon_topo1, lat_topo1,-topo_new1,zx,'linestyle','none');caxis([50 5000]);
colormap(ax,flipud(m_colmap('blues')));
hold on;
m_gshhs_l('patch',[.7 .7 .7],'edgecolor','none');
hold on;
m_plot([nax(1) nax(1)],[nay(1) nay(2)],'k','linewidth',3);
hold on;
m_plot([nax(1) nax(2)],[nay(2) nay(2)],'k','linewidth',3);
hold on;
m_plot([nax(2) nax(2)],[nay(2) nay(1)],'k','linewidth',3);
hold on;
m_plot([nax(2) nax(1)],[nay(1) nay(1)],'k','linewidth',3);

 [ax_bar h]=m_contfbar([0.2 0.8],1.01,cs,ch,'endpiece','no');
 xlabel(ax_bar,'Topography (m)');
 set(ax_bar,'xtick',[50 200 1000:500:5000]);

