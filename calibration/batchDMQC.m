%Programs called:
% pre_wjo
% argo_calibration.m - calls:
%   update_historical_mapping_ron.m
%   set_calib_series_ron.m
%   calculate_running_calib_ron.m
%   plot_diagnostics_ron.m           -these are actually the programs written by Annie Wong, but modified

%This version was designed to generate a new PSAL_ADJUSTED_ERROR field in Aug., 2003, now Nov., 2003.
%Criteria from the new version2.0 User's Manual are:
%   The PSAL_ADJUSTED_QC is 1 unless the PI cannot accept the adjustments
%   (2 or 3) or the PSAL is unadjusstable (4 PSAL=FILLVALUE). This means
%   that the
%   uncertainties in the data must all be expressed by the size of the
%   _ERROR. The statistical uncertainty decided on at the meeting is
%   2 x the standard deviation that comes out of Annie's routine.
% Data will be published from two categories after the Nov., 2003 meeting: 1.
%   Float data are good; 2. Float data are adjusted and accepted by the PI.
%
%Program to create data files for Annie Wong's argo_calibration system on Howard Freeland's floats.
%The program, config.txt and local_config.txt and data directories are at e:\rapps\ooi\argo_DM\calibration.
%input is from netcdf files provided by MEDS and are one profile per file.
%
%The .mat files contain all profiles for a given float and are padded to a
%length of 100 depths using NaN's and LEVELS WITH UNREASONABLE DATA ARE padded with NaN's.
%Nov.18, 2004: Implemented the handling of PI judgements on doubtful
%profiles with ViewPlotsNew.m which stores its information in the CellK,
%min_err and comment fields in the calseries_xxxxx.mat files. DO_FLOAT_GDAC
%handles greylisted floats by nan-ing their salinities and the greylist is
%kept in local.txt for the purpose of this program.
%The official greylist is downloaded and kept in the FLOAT_SOURCE_DIRECTORY.
%
%After calling out the AW programs, the program generates a NC file with adjusted fields based on the AW analysis
%Viewplotsnew.m must then be called to review those changes.
%After a file is being processed, it is moved to /changed

%warning off MATLAB:mir_warning_variable_used_as_function
%warning off MATLAB:break_outside_of_loop
ncclose;
clear;clc;
lo_system_configuration = load_configuration('CONFIG_OW.TXT'); %Decide whether you use WJO OR OW
local_config=load_configuration('local_OW.txt');%Decide whether you use WJO OR OW
N100=eval(local_config.MAX_DATA);
limSAL=eval(local_config.limSAL);
limTEMP=eval(local_config.limTEMP);
limPRES=eval(local_config.limPRES);
minmaxSAL=eval(local_config.minmaxSAL);
min_err_global=eval(local_config.MIN_MAP_ERR);
output_dir=local_config.OUT;
cd(local_config.BASE);

%Update files in float_source directory from files found in NEW directory
%This program here does:
%1-Reads the Grey file
%2a-calls GRAB_NEW_NC if chosen, which copies files from /DATA/MEDSFTP to
%NEW
%2b-copies files from DATA/NEW/REDO if chosen
%3-copies files from a give float from DATA/NEW to DATA/INGESTED
%4-saves MAT file in /float_source/
%5-save /calibration/CurrentFloats.mat with float_dirs and float_names;
%6-move files from calibration\output\to calibration\output\unchanged or
%calibration\output\changed


%3-backs up files in FLOAT_MAPPED/CALIB/SOURCE/PLOTS_DIRECTORY directories to sub folder "save"
%4-Process one new file at the time, sorted by float number
%{ 5-Reads a NC file from the NEW directory (ncprofile_read_OSAP.m)
%  6-find which floats are grey
%  7-set float count to 1 if it was previously at 0; or if a cycle from the same float has NOT been read previously in this run, increment the float count;
%    the program stops when the float count increases the num_files_to_run
%  8-the float name  (next_name) is being stored in a cell array called float_names; the curent float dir is being stored in float_dirs
%  9-if program is run in intercomparison mode (specified in config file), howard's name becomes PI_namenew; otherwise, it is taken from the NC file
% 10-unusable files are being caught. how? if pmtpnew is NOT empty, AND (if the pi_namenew is the same as the one in the local config file or radhakrishnan or rojas)
%     AND if there are less or equal MAX_DATA (local config) depths AND if PROFILE_NOnew is less than 9000
% 11-Asssign NaNs to pressure values not within depth range (-100 3000), psal range (30 42) or temp range (-2 40); this won't affect the original netcdf values because these new values
%    will only go in the Corrected field
% 12-Pres, Temp and Psal are parsed to N100 (MAX_DATA) values with NaNs
% 13-Old float MAT file name (if any) is stored in old_flnm ; name of mat file corresponding to actual float is stored in flnm
% 14-BIG IF during which the matifle to go in FLOAT_SOURCE_DIRECTORY is created
%    -AA If it is a different float and not the first one, let user edit the old_flnm data (if he chose the option, previously) and resave file with new values
%    -AA It it is a different float and not the first one, sort the old_flnm by PROFILE_NO and save it
%    -AB If it is a different float and there was already a MAT file, load Matfile and append this profile to it; parsing the data to equal dimensions and NanNing the psal of bad temp or/and bad pres values
%    -AC if it is a different float but there wasn't already a MAT file, initialize variables t be saved eventually
%    -BA It if is the same float and the same profile number has already been seen and is in the array, do nothing
%    -BB It if is the same float and the same profile number has NOT YET been seen, add it
% 15-Move the netcdf file to ingested; unless there is a wrong PI or no PTMP
%}

%calls : GRAB_NEW_NC.m only if LoadNew.m is called
%MO Had to change this because format of grey file changed.. there was a
%comma in the COMMENT field, I removed it manually and removed commas at the end of lines
[GREY,PARAMETER,START_DATE,END_DATE,QC,COMMENT,DAC]=textread([lo_system_configuration.FLOAT_SOURCE_DIRECTORY '..\ar_greylist.txt'],'%s %s %s %s %f %s %s','headerlines',1,'delimiter',','); %QC will be 3
start_date=char(START_DATE);end_date=char(START_DATE);
if size(start_date,2)~=8 || size(end_date,2)~=8 error('Unknown date format'); end
tempo=start_date;START_DAY=datenum(str2num(tempo(:,1:4)),str2num(tempo(:,5:6)),str2num(tempo(:,7:8)));
tempo=end_date;    END_DAY=datenum(str2num(tempo(:,1:4)),str2num(tempo(:,5:6)),str2num(tempo(:,7:8)));
clear tempo start_date end_date
if length(START_DAY)~=size(GREY,1)
    error('Reformat Greylist')
end
if(min_err_global < .004 || min_err_global > .01)
    beep;beep;
    'MIN_MAP_ERR IS OUT OF NORMAL BOUNDS'
end

%strip out the backslash out of PI_name
PI_name=lower(local_config.PI(local_config.PI~=filesep));

%GetArgoFiles
%LoadNew = input('Load new files to the New folder? (0=No 1=from MedsFTP folder(backup data)  2=from "NEW REDO" folder)');
LoadNew=0;
if isempty(LoadNew)    LoadNew=0;
end
if LoadNew==1 || lower(LoadNew)=='y'
    fieldn={'FLOAT_MAPPED_DIRECTORY','FLOAT_CALIB_DIRECTORY','FLOAT_SOURCE_DIRECTORY','FLOAT_PLOTS_DIRECTORY'};
    for i=1:length(fieldn)
        tempDirName=[getfield(lo_system_configuration,fieldn{i}) local_config.PI];
        if isdir(tempDirName)
            if ~isempty(dir([tempDirName '*.nc']))
                if ~isdir([tempDirName 'save\'])
                    system(['mkdir ' tempDirName 'save\']);
                end
                system(['copy ' tempDirName '*.* ' tempDirName 'save\']);
            end
        end
    end
    GRAB_NEW_NC
elseif LoadNew == 2
    copyfile([local_config.REDO '*.nc'],[local_config.NEW '*.nc']);
end
NewFiles = dir([local_config.NEW '*.nc']);

%sort by float name; not by first letter which can be D or R
floatnames=lower(char(NewFiles.name));
[tr,newindex]=sortrows(floatnames(:,2:end));
netcdf_names=cellstr(char(NewFiles(newindex).name));

Num_Files_To_Run = length(NewFiles);
if Num_Files_To_Run < 1;
    beep;
    return;
end
Num_Floats_To_Run = input('How many floats do you want to process from new_MED (999 for all)? '); %Num_Files_To_Run means number of files to run
if isempty(Num_Floats_To_Run) || Num_Floats_To_Run < 1;beep;return;end
EditData = input('Do you want to edit out bad data? (1=yes) '); %Invokes interactive graphic editing

% it looks as if setting CONFIG_MAX_CASTS to 300 saves some time over the
% 600 setting. The April 2003 version uses 300 as the default.

%read float file data into the appropriate matlab source file
%move the original file to the "ingested" folder and move files with no
%salinity or wrong PI into the "NotProcessed" folder.
%Temperatures are converted into IPTS-68 in ncprofile_read_OSAP.m.
flnm='';
float_count=0;
tic;
pre_ow;
cd(local_config.MATLAB )
argo_calibration     % new profiles are mapped and calibrated in this program from Annie Wong
cd(local_config.BASE);
%post_WJO; don't need to do that since we have to review the files anyway!
display('Now please run Viewplotsnew');