%Programs called:
% pre_wjo
% argo_calibration.m - calls:
%   update_historical_mapping_ron.m
%   set_calib_series_ron.m
%   calculate_running_calib_ron.m
%   plot_diagnostics_ron.m           -these are actually the programs written by Annie Wong, but modified
% viewplotsnew.m 
%warning off MATLAB:mir_warning_variable_used_as_function
%warning off MATLAB:break_outside_of_loop

ncclose;
clear;clc;
lo_system_configuration = load_configuration('CONFIG_WJO.TXT'); %Decide whether you use WJO OR OW
local_config=load_configuration('local_WJO.txt');%Decide whether you use WJO OR OW
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
%2-copies files from a given float from DATA/NEW to DATA/INGESTED
%3-saves MAT file in /float_source/
%4-save /calibration/CurrentFloats.mat with float_dirs and float_names;
%5-move files from calibration\output\to calibration\output\unchanged or
%  calibration\output\changed
%6-backs up files in FLOAT_MAPPED/CALIB/SOURCE/PLOTS_DIRECTORY directories to sub folder "save"
%7-Process one new file at the time, sorted by float number
%{ 1-Reads a NC file from the NEW directory (ncprofile_read_OSAP.m)
%  2-find which floats are grey
%  3-set float count to 1 if it was previously at 0; or if a cycle from the same float has NOT been read previously in this run, increment the float count;
%    the program stops when the float count increases the num_files_to_run
%  4-the float name  (next_name) is being stored in a cell array called
%  float_names; the curent float dir is being stored in float_dirs
%  5-if program is run in intercomparison mode (specified in config file), howard's name becomes PI_namenew; otherwise, it is taken from the NC file
%  6-unusable files are being caught. how? if pmtpnew is NOT empty, AND (if the pi_namenew is the same as the one in the local config file or radhakrishnan or rojas)
%     AND if there are less or equal MAX_DATA (local config) depths AND if PROFILE_NOnew is less than 9000
%  7-Asssign NaNs to pressure values not within depth range (-100 3000), psal range (30 42) or temp range (-2 40); this won't affect the original netcdf values because these new values
%    will only go in the Corrected field
%  8-Pres, Temp and Psal are parsed to N100 (MAX_DATA) values with NaNs
%  9-Old float MAT file name (if any) is stored in old_flnm ; name of mat file corresponding to actual float is stored in flnm
% 10-BIG IF during which the matifle to go in FLOAT_SOURCE_DIRECTORY is created
%    -AA If it is a different float and not the first one, let user edit the old_flnm data (if he chose the option, previously) and resave file with new values
%    -AA It it is a different float and not the first one, sort the old_flnm by PROFILE_NO and save it
%    -AB If it is a different float and there was already a MAT file, load Matfile and append this profile to it; parsing the data to equal dimensions and NanNing the psal of bad temp or/and bad pres values
%    -AC if it is a different float but there wasn't already a MAT file, initialize variables t be saved eventually
%    -BA It if is the same float and the same profile number has already been seen and is in the array, do nothing
%    -BB It if is the same float and the same profile number has NOT YET been seen, add it
% 11-Move the netcdf file to ingested; unless there is a wrong PI or no PTMP
%}

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
%Floats are grouped by dir range for quicker Windows response
%Find dirs which correspond to ranges
dirs=dir(local_config.DATA);
isdir=cat(1,dirs.isdir);
names=char(dirs.name);
ok=find(names(:,1)>='4' &  names(:,4)=='0' & isdir);
I=length(ok);
curdir=[local_config.DATA deblank(names(ok(I),:)) filesep];
dirpath=[curdir filesep '*4900509*.nc'];
NewFiles = dir(dirpath);
%sort by float name; not by first letter which can be D or R
floatnames=lower(char(NewFiles.name));
[tr,newindex]=sortrows(floatnames(:,2:end));
netcdf_names=cellstr(char(NewFiles(newindex).name));
Num_Files_To_Run = length(NewFiles);
if Num_Files_To_Run < 1;
    beep;
    return;
end
Num_Floats_To_Run=size(unique(tr(:,1:7),'rows'),1);
dirpath(dirpath==filesep)='-';
display(['Found ' num2str(Num_Files_To_Run) ' files for ' num2str(Num_Floats_To_Run) ' floats in ' dirpath '.']);
newn=input('How many floats do you want to process (empty for all)?'); 
if ~isempty(Num_Floats_To_Run) Num_Floats_To_Run=newn;
end
EditData = input('Do you want to edit out bad data? (1=yes) '); %Invokes interactive graphic editing
%read float file data into the appropriate matlab source file
%move the original file to the "ingested" folder and move files with no
%salinity or wrong PI into the "NotProcessed" folder.
flnm='';
float_count=0;
tic;
pre_OW;
cd(local_config.MATLAB )
argo_calibration     % new profiles are mapped and calibrated in this program from Annie Wong
cd(local_config.BASE);
display('Now please run Viewplotsnew');