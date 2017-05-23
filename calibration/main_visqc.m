local_config=load_configuration('local_OW.txt');
if ispc
    local_config=xp1152pc(local_config);
end
[filestoprocess,floatname]=download_manager(local_config);
interactive_qc(local_config,filestoprocess)
