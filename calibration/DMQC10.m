ncclose;
clear;clc;
local_config=load_configuration('local_WJO.txt');%Decide whether you use WJO OR OW
filestoprocess=menudmqc(local_config);
N100=eval(local_config.MAX_DATA);
limSAL=eval(local_config.limSAL);
limTEMP=eval(local_config.limTEMP);
limPRES=eval(local_config.limPRES);
minmaxSAL=eval(local_config.minmaxSAL);
min_err_global=eval(local_config.MIN_MAP_ERR);
output_dir=local_config.OUT;
cd(local_config.BASE);

lo_system_configuration = load_configuration('CONFIG_WJO.TXT'); %Decide whether you use WJO OR OW
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