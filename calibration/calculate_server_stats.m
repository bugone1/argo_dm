function [list,numr,numd,numbr,numbd,dat,pre_adj]=calculate_server_stats(url,login,pass_wd,ftppath)
% CALCULATE_SERVER_STATS Calculate D/R file and calibration statistics for
% files on an Argo FTP server
% 

f=ftp(url,login,pass_wd);
list=dir(f,ftppath);
isdir=cat(1,list.isdir);
list=list(isdir);
[numr,numd,dat,pre_adj,numbr,numbd]=deal(zeros(size(list)));
pre_adj=logical(pre_adj);
n_connection_retries=0;
i=1;
while i<=length(list)
    try
        list(i).name
        rd=dir(f,[ftppath list(i).name '/profiles']);
        if ~isempty(rd)
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
            if numr(i)>0 && numd(i)==0
                cd(f,[ftppath list(i).name '/profiles/']);
                mget(f,rd1(1,:));
                rd1(1,:)
                nc=netcdf.open(rd1(1,:),'nowrite');
                howold=now-netcdf.getVar(nc,netcdf.inqVarID(nc,'JULD'))-datenum(1950,1,0); %how old is the first profile
                netcdf.close(nc);
                if howold<(365.25/2)
                    numr(i)=0;
                    numbr(i)=0;
                end
                howold
            elseif numd(i)>0
                cd(f,[ftppath list(i).name '/profiles/']);
                mget(f,rd1(numd(i),:));
                rd1(numd(i),:)
                nc=netcdf.open(rd1(numd(i),:),'nowrite');
                steps=netcdf.getVar(nc,netcdf.inqVarID(nc,'HISTORY_STEP'));steps=squeeze(steps(:,end,:))';
                ok=strmatch('ARSQ',steps);
                tdat=netcdf.getVar(nc,netcdf.inqVarID(nc,'HISTORY_DATE'));tdat=squeeze(tdat(:,end,:))';dat(i)=datenum(tdat(ok(end),:),'yyyymmddHHMMSS');
                sce=netcdf.getVar(nc,netcdf.inqVarID(nc,'SCIENTIFIC_CALIB_EQUATION'));
                pre_adj(i)=~isempty(findstr('procedure 3.2',strtrim(sce(:)'))) || ~isempty(findstr('surface_pres_offset',strtrim(sce(:)')));
                if ~pre_adj(i)
                    tdat
    %                         pause
                end
                netcdf.close(nc);
            end
        end
        [numr(i) numd(i) pre_adj(i)]
    catch
        if ~isempty(findstr(foo.message,'Connection reset')) && n_connection_retries < 5
                n_connection_retries=n_connection_retries+1;
                i=i-1;
        else
            % This is just here for QC purposes
            raise
        end
    end
    i=i+1;
end
gh=1;
[k,i]=sort(numr,'descend');
list=list(i);
dat=dat(i);
pre_adj=pre_adj(i);
numr=numr(i);
numd=numd(i);
numbr=numbr(i);
numbd=numbd(i);
sprintf('%f of eligible profiles have been DMQCed at least once',100*sum(numd)./sum(numd+numr))
sprintf('%f of eligible floats have been DMQCed at least once with sal',100*sum(numd>0)./sum(numd>0 | numr>0))
sprintf('%f of eligible floats have been DMQCed at least once with both sal and pres',100*sum(numd(pre_adj)>0)./sum(numd>0 | numr>0))
sprintf('~ %i profiles DMQCed since last year',sum(numd(dat>(now-365.25))))
char(list.name)

end