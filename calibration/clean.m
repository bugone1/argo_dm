function clean(dire,files,b_files)
% CLEAN eliminate r versions when d is present
%   DESCRIPTION: 
%       eliminate oldest of r and R or d and D when more than one case is present
%   USAGE: 
%       clean(dire,files,b_files)
%   INPUTS:
%       dire - Root directory
%       files - Array of file structures, as obtained from the dir command
%       b_files - Optional flag indicating that the files to be cleaned are
%           B files; if not, core files are assumed
%   VERSION HISTORY:
%       26 November 2013: Current working version
%       24 July 2017, Isabelle Gaboury: Added b_files flag

if nargin<3, b_files=0; end

filenames=char(files.name);
if b_files
    nums=filenames(:,3:end);
    cyc=str2num(filenames(:,11:13));
    ii_rd=2;
else
    nums=filenames(:,2:end);
    cyc=str2num(filenames(:,10:12));
    ii_rd=1;
end
todel=[];
for i=1:length(cyc)
    ok=find(cyc==cyc(i));
    if length(ok)>1
        firstletter=filenames(ok,ii_rd);
        dfiles=ok(firstletter=='D' | firstletter=='d'); %delete oldest of d and D files
        if length(dfiles)==2
            sdn=cat(1,files(dfiles).datenum);
            [tr,todel1]=min(sdn);
            todel=[todel dfiles(todel1(1))];
        end
        rfiles=ok(lower(firstletter)=='r'); %delete oldest of r and R files
        if length(rfiles)==2
            sdn=cat(1,files(rfiles).datenum);
            [tr,todel2]=min(sdn);
            todel=[todel rfiles(todel2(1))];
        end
        todel=[todel ok(lower(firstletter)=='r')']; %delete r files when d files are present
        firstletter=lower(firstletter);
        drfiles=ok(firstletter=='d' | firstletter=='r');
        if length(drfiles)==2
            todel=[todel ok(lower(firstletter)=='r')'];
        end
    end
end
todel=unique(todel);
for i=1:length(todel)
    delete([dire filesep files(todel(i)).name]);
end