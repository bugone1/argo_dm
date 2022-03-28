function filestoprocess=orderfilesbycycle(filestoprocess)
% ORDERFILESBYCYCLE - Order files by the cycle number
%   DESCRIPTION Ensure that files in a list of files to process are ordered
%       by cycle number
%   INPUTS
%       filestoprocess - Structure of files to process, including the field
%           "name"
%   OUTPUTS
%       filestoprocess - Sorted list of files
%   VERSION HISTORY:
%       Created by Mathieu Ouellet, before May 2017
%       21 May 2019, Isabelle Gaboury - Added documentation, case to deal
%           with descending files

a=char(filestoprocess.name);
% Sort by the cycle number, keeping in mind that some cycle numbers may
% have a "D" prefix if descending.
% TODO: I currently don't worry about whether the ascending or descending
% profile comes first, this will probably eventually be needed.
for i=1:size(a,1)
    unders=find(a(i,:)=='_');
    dot=find(a(i,:)=='.');
    if strcmpi(a(i,dot-1),'D')==1, cyc(i)=str2num(a(i,unders(1)+1:dot(1)-2));
    else cyc(i)=str2num(a(i,unders(1)+1:dot(1)-1));
    end
end
[cyc,i]=sort(cyc);
filestoprocess=filestoprocess(i);