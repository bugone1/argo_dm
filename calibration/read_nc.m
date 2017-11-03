function s=read_nc(profile_name, is_b_file)
% READ_NC Read an Argo profile NetCDF file
%   DESCRIPTION: 
%       Reads an Argo profile netCDF file, return a structure s with lower
%       case fields corresponding to most netCDF variables 
%       qc field==1 if visual QC has already been performed on that cycle
%   USAGE: 
%       s=read_nc(profile_name)
%   INPUTS:
%       profile_name - Input file name
%       is_b_file - Optional flag, set to 1 to indicate that this is a B-file.
%           Otherwise it is assumed to be a core file.
%   VERSION HISTORY:
%       September 2016: Current working version
%       24 July 2017, Isabelle Gaboury: Updated to handle b-files.
%	6 Oct. 2017, IG: Added MOLAR_DOXY variables	


% Default is core-Argo files
if nargin < 2, is_b_file=0; end

if is_b_file
    vars={'PRES','PI_NAME','DC_REFERENCE',...
        'REFERENCE_DATE_TIME','JULD_QC','POSITION_QC',...
        'LATITUDE','LONGITUDE','CYCLE_NUMBER','PLATFORM_NUMBER',...
        'DOXY','DOXY_QC','DOXY_ADJUSTED','DOXY_ADJUSTED_QC','DOXY_ADJUSTED_ERROR',...
        'TEMP_DOXY','TEMP_DOXY_QC','TEMP_DOXY_ADJUSTED','TEMP_DOXY_ADJUSTED_QC','TEMP_DOXY_ADJUSTED_ERROR',...
        'PHASE_DELAY_DOXY','PHASE_DELAY_DOXY_QC','PHASE_DELAY_DOXY_ADJUSTED','PHASE_DELAY_DOXY_ADJUSTED_QC','PHASE_DELAY_DOXY_ADJUSTED_ERROR',...
        'MOLAR_DOXY','MOLAR_DOXY_QC','MOLAR_DOXY_ADJUSTED','MOLAR_DOXY_ADJUSTED_QC','MOLAR_DOXY_ADJUSTED_ERROR'};
else
    vars={'PRES','PSAL','TEMP','PI_NAME','DC_REFERENCE',...
        'REFERENCE_DATE_TIME','JULD_QC','POSITION_QC','PRES_QC','TEMP_QC',...
        'LATITUDE','LONGITUDE','PSAL_QC','CYCLE_NUMBER','PLATFORM_NUMBER',...
        'PSAL_ADJUSTED','TEMP_ADJUSTED','PRES_ADJUSTED',...
        'PSAL_ADJUSTED_QC','TEMP_ADJUSTED_QC','PRES_ADJUSTED_QC',...
        'PSAL_ADJUSTED_ERROR','TEMP_ADJUSTED_ERROR','PRES_ADJUSTED_ERROR'};
end

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
history_action=squeeze((netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_ACTION'),ones(1,3)-1,[4 1 N_HISTORY])))';
history_qctest=squeeze((netcdf.getVar(f,netcdf.inqVarID(f,'HISTORY_QCTEST'),ones(1,3)-1,[10 1 N_HISTORY])))';
qcp=strmatch('QCP$',history_action);
qcf=strmatch('QCF$',history_action);
if length(qcf)>2 || length(qcp)>2 || isempty(qcf) || isempty(qcp)
    dbstop if error
    error(['QCP$/QCF$ problem in ' profile_name]);
end

tests=dec2bin(hex2dec(history_qctest(qcp,:)));
if length(tests) < 22
    %display ([profile_name  tests]);
    numZeros = 22- length(tests);
   for i = 1:numZeros
       tests = strcat(tests,'0');
   end
end
    


tests=tests(:,end-1:-1:1); %remove bit 0 and invert bytes
s.qc=any(tests(:,17)=='1');
netcdf.close(f);
