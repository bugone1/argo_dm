function s=read_traj_nc(profile_name)
% READ_NC Read an Argo profile NetCDF file
%   DESCRIPTION: 
%       Reads an Argo trajectory netCDF file, return a structure s with lower
%       case fields corresponding to most netCDF variables 
%   USAGE: 
%       s=read_nc(profile_name)
%   INPUTS:
%       profile_name - Input file name
%   VERSION HISTORY:
%       Isabelle Gaboury, 4 Jan. 2018: Written, but may still need some
%           testing
%       IG, 10 Apr. 2018: Tried to fix reading of QC flags, might not be
%           right yet.

%TODO: I'm still figuring out which of these I need...
vars = {'REFERENCE_DATE_TIME','JULD','JULD_STATUS','JULD_QC','JULD_ADJUSTED','JULD_ADJUSTED_QC',...
    'LATITUDE','LONGITUDE','POSITION_ACCURACY','POSITION_QC','CYCLE_NUMBER','CYCLE_NUMBER_ADJUSTED',...
    'MEASUREMENT_CODE','JULD_DESCENT_START','JULD_ASCENT_START','JULD_DEEP_ASCENT_START','JULD_ASCENT_END',...
    'PRES','PRES_QC','PRES_ADJUSTED','PRES_ADJUSTED_QC','PRES_ADJUSTED_ERROR',};
% These are the variables I'm still debating (i.e., not yet either included
% or definitely discounted)
% vars = {
%     'TEMP','TEMP_QC','TEMP_ADJUSTED','TEMP_ADJUSTED_QC','TEMP_ADJUSTED_ERROR',...
%     'PSAL','PSAL_QC','PSAL_ADJUSTED','PSAL_ADJUSTED_QC','PSAL_ADJUSTED_ERROR',...
%     'AXES_ERROR_ELLIPSE_MAJOR','AXES_ERROR_ELLIPSE_MINOR',...
%     'AXES_ERROR_ELLIPSE_ANGLE','SATELLITE_NAME','JULD_DESCENT_START','JULD_FIRST_STABILIZATION',...
%     'JULD_FIRST_STABILIZATION_STATUS','JULD_DESCENT_END','JULD_DESCENT_END_STATUS',...
%     'JULD_PARK_START','JULD_PARK_START_STATUS','JULD_PARK_END','JULD_PARK_END_STATUS',...
%     'JULD_DEEP_DESCENT_END','JULD_DEEP_DESCENT_END_STATUS','JULD_DEEP_PARK_START',...
%     'JULD_DEEP_PARK_START_STATUS','JULD_ASCENT_START_STATUS',...
%     'JULD_DEEP_ASCENT_START_STATUS',...
%     'JULD_ASCENT_END_STATUS','JULD_TRANSMISSION_START','JULD_TRANSMISSION_START_STATUS',...
%     'JULD_FIRST_MESSAGE','JULD_FIRST_MESSAGE_STATUS','JULD_FIRST_LOCATION',...
%     'JULD_FIRST_LOCATION_STATUS','JULD_LAST_LOCATION','JULD_LAST_LOCATION_STATUS',...
%     'JULD_LAST_MESSAGE','JULD_LAST_MESSAGE_STATUS','JULD_TRANSMISSION_END',...
%     'JULD_TRANSMISSION_END_STATUS','CLOCK_OFFSET','GROUNDED','REPRESENTATIVE_PARK_PRESSURE',...
%     'REPRESENTATIVE_PARK_PRESSURE_STATUS'};

f = netcdf.open(profile_name,'nowrite'); % f is the netcdf object
for i=1:length(vars)
    try
        s.(lower(vars{i}))=netcdf.getVar(f,netcdf.inqVarID(f,vars{i}))';
    catch
        warning(['missing ' vars{i}]);
    end
end
s.dates=netcdf.getVar(f,netcdf.inqVarID(f,'JULD'))+datenum(s.reference_date_time,'yyyymmddHHMM');
[trash,N_HISTORY]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_HISTORY'));
history_action=squeeze((netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'),ones(1,2)-1,[4 N_HISTORY])))';
if str2double(netcdf.getVar(f,netcdf.inqVarID(f,'FORMAT_VERSION'))') > 3
    history_qctest=squeeze((netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),ones(1,2)-1,[10 N_HISTORY])))';
else
    [trash,N_HISTORY2]=netcdf.inqDim(f,netcdf.inqDimID(f,'N_HISTORY2'));
    history_qctest=squeeze((netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),ones(1,3)-1,[10 N_HISTORY2 N_HISTORY])))';
end

% Replace fill values in the latitude and longitude with NaNs
fv = netcdf.getAtt(f,netcdf.inqVarID(f,'LONGITUDE'),'_FillValue');
s.longitude(s.longitude==fv)=NaN;
s.latitude(s.latitude==fv)=NaN;
netcdf.close(f);

% QC flags
qcp=strmatch('QCP$',history_action);
%qcf=strmatch('QCF$',history_action);
tests=dec2bin(hex2dec(history_qctest(qcp,:)));
if length(tests) < 22
    %display ([profile_name  tests]);
    numZeros = 22- length(tests);
   for i = 1:numZeros
       tests = strcat(tests,'0');
   end
end

tests=tests(:,end-1:-1:1); %remove bit 0 and invert bytes
% TODO: I'm not entirely sure this is correct. It has failed on some
% floats...
if size(tests,2)>=17, s.qc=tests(:,17)=='1';  
else s.qc = tests(:,end)=='1';  % TODO: This is where I'm kind of guessing...
end 
