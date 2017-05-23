for i=1:length(floatnames)
    cd(local_config.MATLAB)
    argo_calibration(lo_system_configuration,floatnames(i));% new profiles are mapped and calibrated in this program from Annie Wong
    cd(local_config.BASE)
    exit
end