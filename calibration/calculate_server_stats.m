function [list,numr,numd,numbr,numbd,dat_dmqc,pre_adj,doxy_visqc,dat_deploy,dat_lastd]=calculate_server_stats(url,login,pass_wd,ftppath,temp_dir,eligible_age,exclude_floats,skip_downloads)
% CALCULATE_SERVER_STATS Calculate D/R file and calibration statistics for
% files on an Argo FTP server
%   USAGE: 
%       [list,numr,numd,numbr,numbd,dat,pre_adj]=calculate_server_stats(url,login,pass_wd,ftppath,temp_dir,eligible_age)
%   INPUTS:
%       url - URL of the FTP site to query
%       login - username for the FTP site
%       pass_wd - password for the FTP site
%       ftppath - path to check for R and D files on the FTP site. Profiles
%           are then assumed to be in a <float name>/profiles sub-directory
%   OPTIONAL INPUTS:
%       temp_dir - temporary working directory to use. If not provided then
%           files are downloaded to the current working directory
%       eligible_age - age, in days, at which a float becomes eligible for
%           DMQC. Default value is 6 months
%   OUTPUTS:
%       list - directory listing, one entry per float directory
%       numr - number of R files in each float directory older than
%           eligible_age
%       numd - number of D files in each float directory older than
%           eligible_age
%       numbr - number of BR files in each float directory older than
%           eligible_age
%       numbd - number of BD files in each float directory older than
%           eligible_age
%       dat - date for each file
%       pre_adj - whether or not each file has been adjusted for pressure
%       doxy_visqc - whether or not each file has had visual QC done on the
%           DOXY
%   VERSION HISTORY:
%       May 2017: Original version, inherited from Mathieu Ouellet
%           (creation date unknown)
%       8 Dec. 2017, Isabelle Gaboury: Assorted minor updates to
%           calculation of the statistics
%       16 Oct. 2018, IG: Added options to specify the temporary directory
%           and eligible age.

if nargin<5, temp_dir=pwd; 
elseif exist(temp_dir,'dir')<=0, mkdir(temp_dir);
end
% By default we assume floats are eligible for DMQC after six months. The
% extra 0.25 allows for leap years.
if nargin < 6, eligible_age=365.25/2; end
if nargin < 7, exclude_floats={}; end
if nargin < 8, skip_downloads=0; end

% Get a directory listing of the FTP site
f=ftp(url,login,pass_wd);
list=dir(f,ftppath);
isdir=cat(1,list.isdir);
list=list(isdir);

% Preallocate matrices
[numr,numd,pre_adj,doxy_visqc,numbr,numbd,dat_deploy,dat_dmqc,dat_lastd]=deal(zeros(size(list)));
pre_adj=logical(pre_adj);
doxy_visqc=logical(doxy_visqc);

% Get information on the files in each float directory
n_connection_retries=0;
i=1;
while i<=length(list)
    try
        list(i).name
        % Get a listing of files in the profiles sub-directory
        rd=dir(f,[ftppath list(i).name '/profiles']);
        if ~isempty(rd) && ~any(strcmp(exclude_floats,list(i).name))
            % From the directory listing, get the number of R and D files
            rd=rd(~cat(1,rd.isdir));
            rrd=lower(char(rd.name));
            ok=rrd(:,1)=='r' | rrd(:,1)=='d';
            rd1=char(rd(ok).name);
            numr(i)=sum(rd1(:,1)=='R' | rd1(:,1)=='r');
            numd(i)=sum(rd1(:,1)=='D' | rd1(:,1)=='d');
            ok=rrd(:,1)=='b';
            if any(ok)
                rd2=char(rd(ok).name);
                numbr(i)=sum(lower(rd2(:,2))=='r');
                numbd(i)=sum(lower(rd2(:,2))=='d');
            end
            % If the profile directory isn't empty, download the files and
            % check the ages
            if numr(i)>0 && numd(i)==0
                cd(f,[ftppath list(i).name '/profiles/']);
                if ~skip_downloads, mget(f,deblank(rd1(1,:)),temp_dir); end
                %rd1(1,:)
                nc=netcdf.open([temp_dir,filesep,deblank(rd1(1,:))],'nowrite');
                % How old is the first profile? If less than the eligible
                % age then we set both numr and numbr to zero
                dat_deploy(i)=netcdf.getVar(nc,netcdf.inqVarID(nc,'JULD'))-datenum(1950,1,0);
                howold=now-netcdf.getVar(nc,netcdf.inqVarID(nc,'JULD'))-datenum(1950,1,0); 
                netcdf.close(nc);
                if howold<eligible_age
                    numr(i)=0;
                    numbr(i)=0;
                end
                %howold
                % Check if the DOXY data were visually QC'd
                if numbr(i)>0
                    if ~skip_downloads, mget(f,deblank(rd2(1,:)),temp_dir); end
                    nc=netcdf.open([temp_dir,filesep,deblank(rd2(1,:))],'nowrite');
                    doxy_qc=netcdf.getVar(nc,netcdf.inqVarID(nc,'DOXY_QC'));
                    netcdf.close(nc);
                    doxy_visqc(i)=any(doxy_qc>'0');
                end
            elseif numd(i)>0
                % If there are D files, get the date of the most recent
                % calibration, and look for evidence of a pressure
                % calibration
                cd(f,[ftppath list(i).name '/profiles/']);
                if ~skip_downloads, mget(f,deblank(rd1(numd(i),:)),temp_dir); end
                %rd1(numd(i),:)
                nc=netcdf.open([temp_dir,filesep,deblank(rd1(numd(i),:))],'nowrite');
                steps=netcdf.getVar(nc,netcdf.inqVarID(nc,'HISTORY_STEP'));steps=squeeze(steps(:,end,:))';
                ok=strmatch('ARSQ',steps);
                tdat=netcdf.getVar(nc,netcdf.inqVarID(nc,'HISTORY_DATE'));tdat=squeeze(tdat(:,end,:))';dat_dmqc(i)=datenum(tdat(ok(end),:),'yyyymmddHHMMSS');
                sce=netcdf.getVar(nc,netcdf.inqVarID(nc,'SCIENTIFIC_CALIB_EQUATION'));
                netcdf.close(nc);
                pre_adj(i)=~isempty(findstr('procedure 3.2',strtrim(sce(:)'))) || ~isempty(findstr('surface_pres_offset',strtrim(sce(:)')));
%                 if ~pre_adj(i)
%                     tdat
%     %                         pause
%                 end
                if numbd(i)>0, doxy_visqc(i)=1; end
                if numr(i)>0
                    if ~skip_downloads, mget(f,deblank(rd1(end,:)),temp_dir); end
                    nc=netcdf.open([temp_dir,filesep,deblank(rd1(end,:))],'nowrite');
                    dat_lastd(i) = netcdf.getVar(nc,netcdf.inqVarID(nc,'JULD'));
                    netcdf.close(nc);
                end
            end
        end
        %[numr(i) numd(i) pre_adj(i)]
        %sprintf('%s numr=%d numd=%d pre_adj=%d numbr=%d numbd=%d doxy_visqc=%d',rd1(1,:),numr(i),numd(i),pre_adj(i),numbr(i),numbd(i),doxy_visqc(i))
    catch foo
        if ~isempty(findstr(foo.message,'Connection reset')) && n_connection_retries < 5
                n_connection_retries=n_connection_retries+1;
                i=i-1;
        else
            % This is just here for QC purposes
            rethrow(foo)
        end
    end
    i=i+1;
end
% Do some sorting
[k,i]=sort(numr,'descend');
list=list(i);
dat_deploy=dat_deploy(i);
dat_dmqc=dat_dmqc(i);
dat_lastd=dat_lastd(i);
pre_adj=pre_adj(i);
numr=numr(i);
numd=numd(i);
numbr=numbr(i);
numbd=numbd(i);
doxy_visqc=doxy_visqc(i);

% Print statistics
sprintf('%f of eligible profiles have been DMQCed at least once',100*sum(numd)./sum(numd+numr))
sprintf('%f of eligible floats have been DMQCed at least once with sal',100*sum(numd>0)./sum(numd>0 | numr>0))
sprintf('%f of eligible floats have been DMQCed at least once with both sal and pres',100*sum(numd(pre_adj)>0)./sum(numd>0 | numr>0))
sprintf('%f of eligible DOXY floats have been DMQCed at least once',100*sum(numbd>0)./sum(numbd>0 | numbr>0))
sprintf('~ %i profiles DMQCed since last year',sum(numd(dat_dmqc>(now-365.25))))
char(list.name)

end