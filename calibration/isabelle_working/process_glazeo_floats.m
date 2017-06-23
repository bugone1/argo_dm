% Single-purpose (mostly) routine to apply the results of GlazeO processing
% to the float data. Note that user input is required throughout.
%
% WARNING: This routine doesn't actually seem to work, as not all the
% necessary information is found in the GlazeO .mat files. I'm keeping it
% on hand for possible recycling while I work through the floats, but once
% this is done this routine can be deleted.
%
% Isabelle Gaboury, 12 June 2017

function process_glazeo_floats(float_name)

error('This routine does not work');

%%%%%% Setup %%%%%%

% Path configurations
local_config=load_configuration('local_OW.txt');
lo_system_configuration=load_configuration([local_config.BASE 'config_ow.txt']);

% GlazeO paths
glazeo_source_directory = 'DMQC-Canada2-2017/05_calibration_s/data/float_source/';
glazeo_visualqc_directory = 'DMQC-Canada2-2017/03_Controles_RTFlags/';
glazeo_mapped_directory = 'DMQC-Canada2-2017/05_calibration_s/data/float_mapped/CONFIG129/';
glazeo_calib_directory = 'DMQC-Canada2-2017/05_calibration_s/data/float_calib/CONFIG129/';

% Field names to check for the visual QC
qc_fields_meds = {'pres_qc','temp_qc','psal_qc'};
qc_fields_glazeo = {'PRES_FLAG', 'TEMP_FLAG', 'SAL_FLAG'};

%%%%%% Processing %%%%%%

% Processing
    
% Fetch the data
foo = input('Fetch data from the FTP site (y/n, default=n)?','s');
if isempty(foo), foo='n'; end
if strcmpi(foo,'y'), fetch_from_web(local_config.DATA, float_name); end

% There doesn't seem to be a direct replacement for the pressure
% correction, and GlazeO generally accepts the computed replacement, so we
% redo this step
presMain(local_config,lo_system_configuration,[],float_name);

% Load the NetCDF data
fname_pres=[local_config.RAWFLAGSPRES_DIR float_name];
dire=[local_config.DATA findnameofsubdir(float_name,listdirs(local_config.DATA))];
files = dir([dire filesep '*' float_name '*.nc']);
t=read_all_nc(dire,files,[],[0 0]);

% Load the GlazeO flags, apply to the profile and update the pressure file.
% We do this fairly noisily for QC purposes
qc_data = load([glazeo_visualqc_directory float_name]);
for ii_prof=1:length(t)
    for ii_field=1:length(qc_fields_meds)
        % Convert the GlazeO flag field to the same format as in the MEDS
        % structure. Note that the GlazeO data are in a matrix, and so have
        % padding at the end
        n_z = length(t(ii_prof).(qc_fields_meds{ii_field}));
        temp_qc = num2str(qc_data.(qc_fields_glazeo{ii_field})(ii_prof,1:n_z),'%d');
        n_changed = find(temp_qc ~= t(ii_prof).(qc_fields_meds{ii_field}));
        if ~isempty(n_changed)
            display(['Updating ' num2str(len(n_changed)) ' flags for ' qc_fields_meds{ii_field}]); 
            t(ii_prof).(qc_fields_meds{ii_field}) = qc_data.(qc_fields_glazeo{ii_field})(ii_prof,:);
        end
    end
end
save(fname_pres,t,'-append');

% Copy the files from the GlazeO directory to the expected places in
% the current file structure
[success, message, messageid] = copyfile([glazeo_source_directory float_name '.mat'], ...
    [lo_system_configuration.FLOAT_SOURCE_DIRECTORY float_name '.mat']);
if success==0, warning(messageid, message); end
[success, message, messageid] = copyfile([glazeo_mapped_directory 'map_' float_name '.mat'], ...
    [lo_system_configuration.FLOAT_MAPPED_DIRECTORY 'map_' float_name '.mat']);
if success==0, warning(messageid, message); end
[success, message, messageid] = copyfile([glazeo_calib_directory 'calseries_' float_name '.mat'], ...
    [lo_system_configuration.FLOAT_CALIB_DIRECTORY 'calseries_' float_name '.mat']);
if success==0, warning(messageid, message); end
[success, message, messageid] = copyfile([glazeo_calib_directory 'cal_' float_name '.mat'], ...
    [lo_system_configuration.FLOAT_CALIB_DIRECTORY 'cal_' float_name '.mat']);
if success==0, warning(messageid, message); end

% Generate and view the plots. The GlazeO files include plots, but they're
% in EPS format, and it seems safer to regenerate them anyway
cd(local_config.MATLAB);
plot_diagnostics_ow('',float_name,lo_system_configuration);
cd(local_config.BASE)
viewplots(lo_system_configuration,local_config,float_name);

% Prepare to publish to web
reducehistory(local_config,float_name);
publishtoweb_ig(local_config,lo_system_configuration,float_name,1);

end