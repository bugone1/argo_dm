function [LAT,LONG,DATES,PRES,SAL,TEMP,PTMP,PROFILE_NO,PI_NAME,WMO_ID,DC_REFERENCE]=ncprofile_read_OSAP(profile_name);
% this routine is used to extract data from a single profile Argo file
%
% e.g. ncprofile_read('R4900142_039.nc');
% open file for reading only ---

f = netcdf(profile_name,'nowrite'); % f is the netcdf object

% general info for each profile, allow qc flags = 0,1  ---

%REFERENCE_DATE_TIME = var(f,'REFERENCE_DATE_TIME'); will also get the value
%REFERENCE_DATE_TIME = REFERENCE_DATE_TIME(:);
try
    test1=name(f{'PI_NAME'}); %sometimes the PI name is not in the file from MEDS
    PI_NAME = f{'PI_NAME'}(:);
catch
    PI_NAME = 'NO_NAME';
end
%<mo> if PI_NAME a column file, make it a row file. ALso trim
if size(PI_NAME,1)~=1
    PI_NAME=deblank(PI_NAME');
end

PROFILE_NO = f{'CYCLE_NUMBER'}(:);
WMO_ID = f{'PLATFORM_NUMBER'}(:);
DC_REFERENCE = f{'DC_REFERENCE'}(:);

REFERENCE_DATE_TIME = f{'REFERENCE_DATE_TIME'}(:); % Jan.1, 1950
if size(REFERENCE_DATE_TIME,2)==1 
REFERENCE_DATE_TIME = REFERENCE_DATE_TIME';
end
year = str2num(REFERENCE_DATE_TIME(1:4));month = str2num(REFERENCE_DATE_TIME(5:6));
day = str2num(REFERENCE_DATE_TIME(7:8));hour = str2num(REFERENCE_DATE_TIME(9:10));
minute = str2num(REFERENCE_DATE_TIME(11:12));
DATES=f{'JULD'}(:)+datenum(year,month,day,hour,minute,0);
JULD_QC = f{'JULD_QC'}(:);
if JULD_QC>'1'
    DATES=NaN;
end

LAT = f{'LATITUDE'}(:);
LONG = f{'LONGITUDE'}(:);
LONG=LONG+360*(LONG<0);
POSITION_QC = f{'POSITION_QC'}(:);
if POSITION_QC>'1'
    [LAT,LONG]=deal(NaN);
end
if abs(LAT)>900
    LAT=NaN;
end
if abs(LONG)>900
    LONG=NaN;
end

% measurements for each profile, allow qc flags = 1,2,3. All others are nan'ed. On output, bad salinities are given qc=4, 
% adjusted salinities; qc=1, so 2&3 disappear.
% qc=0|4|5|6|7|8|9 are passed through from the input to the ouput file with salinity values unchanged.

PRES = f{'PRES'}(:);
PRES_CORRECTED_QC = f{'PRES_QC'}(:);
PRES(PRES_CORRECTED_QC>'3')=nan;

TEMP = f{'TEMP'}(:);
TEMP_CORRECTED_QC = f{'TEMP_QC'}(:);
TEMP(TEMP_CORRECTED_QC(:)>'3')=nan;

SAL = f{'PSAL'}(:);
%PSAL_CORRECTED_QC = f{'PSAL_QC'}(:);
%PSAL(PSAL_CORRECTED_QC(i)>'3')=nan;

if (size(SAL) == size(TEMP)); 
    PTMP = sw_ptmp(SAL,TEMP,PRES,0);
else
    PTMP=[]; 
end %IOTS68/ITS90
% close file ---
ncclose
PRES=PRES(:); SAL=SAL(:); TEMP=TEMP(:); PTMP=PTMP(:);