% One-time processing file for float 4901193. Because of the way this float
% was worked on, this files is based on a mix of manual and automated
% steps. As such, the processing is broken up into 3 steps, each of which
% ends with a manual operation. See the comments below for details. 
%
% Isabelle Gaboury, 01 August 2017

function float_4901193(step)

% Add a couple of needed paths
if ~ispc
    addpath('/u01/rapps/argo_dm/calibration');
    addpath('/u01/rapps/vms_tools');
else
    addpath('w:\argo_dm\calibration');
    addpath('w:\vms_tools');
end

% Setup
local_config=load_configuration('local_OW.txt');
if ispc, local_config=xp1152pc(local_config); end

if step==1
    % Download via FTP, using the usual routines
    fetch_from_web(local_config.DATA, '4901193');

    % Fix the dimensions
    fix_dimflags(['data' filesep '4901000'],'4901193')

    % Fix the JULD_QC flag
    set_profile_qcflags(['data' filesep '4901000'],'4901193','JULD_QC',1,[97])

    % Manual: Load into visual QC, just create the .mat file
    disp('Please create the .mat files using the visual QC routine')
    main_ig('atlantic',{1,'4901193',1})
end

if step==2
    % Adjust the surface flags
    fix_surface_flags('4901193','nova',2)

    % Manual: Carry out visual QC, make sure nothing got broken, but there 
    % shouldn't be anything to change (although I did end up changing one
    % point on cycle 133).
    disp('Please carry out visual QC')
    main_ig('atlantic',{1,'4901193',1})
end

if step==3
    
    % Load the current structure
    load(['..' filesep 'data' filesep 'temppresraw' filesep '4901193.mat'],'t','presscorrect');
    
    % Get the pressure fill value (the same is used for the other variables
    % anyway)
    f=netcdf.open(['data' filesep '4901000' filesep 'D4901193_000.nc'],'NOWRITE');
    fill_value=netcdf.getAtt(f,netcdf.inqVarID(f,'PRES'),'_FillValue')
    netcdf.close(f);

    % We need to go and undo the fill values for surface flags<4
    for ii=1:length(t)
        if t(ii).pres_qc(1)=='3' % This suggests it used to be a '4'
            if t(ii).pres_adjusted(1)==fill_value
                t(ii).pres_adjusted(1) = t(ii).pres(1) + t(ii).pres_adjusted(2) - t(ii).pres(2);
                t(ii).pres_adjusted_error(1) = t(ii).pres_adjusted_error(2);
            end
            if t(ii).temp_adjusted(1)==fill_value && t(ii).temp_qc(1)<'4'
                t(ii).temp_adjusted(1)=t(ii).temp(1) + t(ii).temp_adjusted(2)-t(ii).temp(2);
                t(ii).temp_adjusted_error(1)=t(ii).temp_adjusted_error(2);
            end
            if t(ii).psal_adjusted(1)==fill_value && t(ii).psal_qc(1)<'4'
                t(ii).psal_adjusted(1)=t(ii).psal(1) + t(ii).psal_adjusted(2)-t(ii).psal(2);
                t(ii).psal_adjusted_error(1)=t(ii).psal_adjusted_error(2);
            end
        end
    end
    % Write the NetCDF files
    for ii=1:length(t)
        write_nc(['data' filesep '4901000' filesep 'D4901193_' num2str(t(ii).cycle_number,'%03i') '.nc'],t(ii),...
            ['output' filesep 'changed' filesep 'D4901193_' num2str(t(ii).cycle_number,'%03i') '.nc'],1); 
    end
    
    % Zip
    display('Zipping...');
    zip('4901193',[local_config.OUT 'changed' filesep '*4901193_*.nc']);
    
    display('Ready to FTP');
    
end