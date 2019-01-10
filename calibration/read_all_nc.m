function t=read_all_nc(dire,files,t,dokeep,is_b_file)
% READ_ALL_NC Net Argo NetCDF files
%   DESCRIPTION: Read all netCDF files within directory "dire" and stores
%       them in structure "t". If a previous version of "t" existed:
%       If dokeep(1)==1, Qc parms from struct t will be kept
%       If dokeep(2)==1, other parms from struct t will be kept
%   USAGE: 
%       t=read_all_nc(dire,files,t,dokeep)
%   INPUTS:
%       dire - Base directory
%       files - Array of file structures
%       t - Existing data, as an array of structures identical to that
%           returned by this routine.
%       dokeep - 2-element vector indicating whether or not to keep the
%           data in the input structure t, as in the DESCRIPTION above.
%       is_b_file - Optional flag, set to 1 to indicate that these are
%           B-files. Otherwise they are assumed to be core files.
%   OUTPUTS: Array of structures containing the variables of interest from
%       the NetCDF file.
%
% VERSION HISTORY:
%   Isabelle Gaboury, 30 May 2017: After discussion with Mathieu Ouellet,
%       fixed a bug where dokeep was being interpreted incorrectly.
%   IG, 24 July 2017: Expanded documentation, added is_b_file flag
%   IG, 10 Jan 2019: Fixed issue whereby undefined at is not allowed in
%       more recent versions of Matlab

% Default is core-Argo files
if nargin < 5, is_b_file=0; end

at=struct();
for i=1:length(files)
    if i==1, at=[read_nc([dire filesep files(i).name], is_b_file)];
    else at(i)=read_nc([dire filesep files(i).name], is_b_file);
    end
end
if ~isempty(t)
    cyc1=cat(1,at.cycle_number);
    cyc2=cat(1,t.cycle_number);
    fn=fieldnames(t);
    for j=1:length(at)
        for i=1:length(fn)
            pos=strfind(fn{i},'_qc');
            ok=find(cyc2==cyc1(j));
            if ~isempty(pos) && dokeep(1)
                at(j).(fn{i})=t(ok).(fn{i});
            end
            if isempty(pos) && dokeep(2)
                at(j).(fn{i})=t(ok).(fn{i});
            end
        end        
    end
end
t=at;