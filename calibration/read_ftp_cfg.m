function ftp_info = read_ftp_cfg(cfg_file,required_hosts)
% READ_FTP_CFG - Read in a comma-delimited file of FTP login information.
% Columns must be ID (unique identifier for the FTP
% site),host,path,user,pwd
%   INPUTS:
%       cfg_file - Path to the configuration file
%   OPTIONAL INPUTS:
%       required_hosts - List of hosts that must be found in the file, used
%           to check that the file is ready to use
%   OUTPUTS:
%       ftp_info - Array of structure of FTP configuration information, one
%           entry per host ID
%   VERSION HISTORY:
%       10 Jan. 2019, Isabelle Gaboury: Written

% Read in the CFG data
fid = fopen(cfg_file,'r');
temp_data = textscan(fid,'%s %s %s %s %s','delimiter',',');
fclose(fid);
% Check that we read in something reasonable
if isempty(temp_data) || any(size(temp_data)~=[1,5])
    error('Problem reading the FTP cfg file')
end

% Parse into a structure, skipping the header line
for ii=2:length(temp_data{1})
    ftp_info.(temp_data{1}{ii}).url = temp_data{2}{ii};
    ftp_info.(temp_data{1}{ii}).path = temp_data{3}{ii};
    ftp_info.(temp_data{1}{ii}).user = temp_data{4}{ii};
    ftp_info.(temp_data{1}{ii}).pwd = temp_data{5}{ii};
end

% Check that we have all the necessary hosts
if nargin==2 && ~isempty(required_hosts) && not(all(ismember(required_hosts,fieldnames(ftp_info))))
    warning('Not all required hosts were defined in the FTP CFG file');
end
    
end