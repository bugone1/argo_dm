po_system_configuration=load_configuration('../calibration/config.txt');
fn=dir('C:\z\argo_DM\data\float_plots\freeland\*_1.ps');
fnum=char(fn.name);
sf=size(fnum);
for i=15:sf(1)
    [i sf]
    calculate_running_calib_mat('freeland\', strtok(fnum(i,:),'_'), po_system_configuration );
    plot_diagnostics_mat('freeland\',strtok(fnum(i,:),'_'), po_system_configuration )
end