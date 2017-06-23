function [filestoprocess,floatname,ow]=menudmqc_ig(local_config,argu)
% MENUDMQC_IG  DMQC menu handling (Isabelle's version)
%   DESCRIPTION:
%       Launches DMQC given the provided configuration. Some QC steps are
%       carried out in the current routine, others are typically done by
%       the calling routine.
%   USAGE:
%      [filestoprocess,floatname,ow]=menudmqc_ig(local_config,config,argu)
%   INPUTS:   
%       local_config - Structure with various configuration parameters,
%          e.g. paths
%       config - Structure of Owens & Wong processing paths and parameters
%   OPTIONAL INPUTS:
%       argu - 1-3 element cell array of strings indicating the desired action, 
%           float number, and QC stage to be carried out (i.e., the first
%           three questions normally asked by the routine). See code below
%           for available options.
%   OUTPUTS:
%       filestoprocess - List of files that could be processed
%       floatname - Name of the float to process
%       ow - 1/0 array describing which processing steps were actually
%           carried out.
%   VERSION HISTORY:
%       May-June 2017, Isabelle Gaboury: Created, based on Mathieu Ouellet's
%           code dated 2 Feb. 2017.

% Setup
dire=local_config.DATA;

% If argu is provided, make sure the first and third elements are strings,
% and that the middle element is a double. This is for
% backward-compatibility with earlier versions of the code
if nargin<2, argu=[]; end
largu=length(argu);
if largu > 0 && isnumeric(argu{1}), argu{1} = num2str(argu{1}); end
if largu > 1 && isnumeric(argu{2}), argu{2} = num2str(argu{2}); end
if largu > 2 && ~isnumeric(argu{3}), argu{3} = str2double(argu{3}); end

% Get the desired action from the user or from argu
if largu>0
    q=argu{1};
    display(['Processing option selected via argu: ', q]);
else
    display('0- Exit without doing anything');
    display('1- Enter the float number (starting with Q, wild card * accepted)');
    display('2- List directories of files currently on disk');
    display('3- Give me "best candidate" currently on disk');
    display('4- Synchronize files currently on disk and FTP site');
    display('5- Update reference database from Coriolis');
    display('6- Calculate stats of r/d files at GDAC');
    q=input('? ','s');
end
[filestoprocess,floatname]=deal([]);
ow=ones(1,4);
% Exit without doing anything
if q=='0'
    ow=zeros(1,4);
    return; 
end

% If the user selected "1" above, get a float number to process, then ask
% what the user whats to do with the float
if q=='1'
    if largu > 1
        display(['Float selected via argu: ', argu{2}])
        q = argu{2};
    else
        q=input('1- Enter the float number (wild card * accepted) ','s');
    end
    if lower(q(1))~='q'
        q=['q' q];
    end
end
dirs=listdirs(dire);
sd1=size(dirs,1);
switch lower(q(1))
    case 'q'
        q=q(q~='*');
        pathe=[dire findnameofsubdir(q,dirs) filesep];
        allfilestoprocess=dir([pathe '*' q(2:end) '*.nc']);
        if ~isempty(allfilestoprocess)
            clean(pathe,allfilestoprocess);
            allfilestoprocess=dir([pathe '*' q(2:end) '*.nc']);
            allfilestoprocess=allfilestoprocess(cat(1,allfilestoprocess.bytes)>0);
            undr=find(allfilestoprocess(1).name=='_');
            floatname=allfilestoprocess(1).name(2:undr-1);
            filestoprocess=dir([pathe '*' floatname '*.nc']);
            filestoprocess=orderfilesbycycle(filestoprocess);
        else
            floatname=q(2:end);
        end
        if largu>2
            qow=argu{3};
            display(['Processing step selected via argu: ', num2str(qow)])
        else
            qow=input('0)FTP 1)Pre-OW, 2)OW, 3)Post-OW, 4)Prepare to publish to web?'); %, 5)Delete local files ?');
        end
        if ~isempty(qow)
            ow(qow+1)=true;
            ow(setdiff(1:6,qow+1))=false;
        end       
        
    case '2'
        for i=1:sd1;
            display([num2str(i) '-' dirs(i,:)]);
        end
        di=input([num2str(1) '-' num2str(sd1)]');
        pathe=[dire deblank(dirs(di,:)) filesep];
        allfilestoprocess=dir([pathe '*.nc']);
        undr=find(allfilestoprocess(1).name=='_');
        floatname=allfilestoprocess(1).name(2:undr);
        filestoprocess=dir([pathe '*' floatname '*.nc']);
        filestoprocess=orderfilesbycycle(filestoprocess);
    case '3'
        f=ftp(ftpaddress.current,user.login,user.pwd);
        cd(f,ftppath);
        list=dir(f);
        isdir=cat(1,list.isdir);
        list=list(isdir);
        for i=1:length(list)
            list(i).name
            rd=dir(f,[list(i).name '/profiles']);
            if ~isempty(rd)
                isnotdir=~cat(1,rd.isdir);
                rd=upper(char(rd(isnotdir).name));
                num(i)=sum(rd(:,1)=='R');
            end
        end
        [tr,i]=sort(num);
        tr
        floatnames=char(list(i(end:-1:1)).name)
        filestoprocess=[];
    case '4'
        f=ftp(ftpaddress.current,user.login,user.pwd);
        list=dir(f,ftppath);
        for i=1:length(list)
            subdir=findnameofsubdir(list(i).name,dirs);
            pathe=[dire subdir filesep];
            allfloats=uniquefloatsindir(pathe);
            cd(f,[ftppath list(i).name '/profiles/']);
            if isempty(allfloats) || isempty(strmatch(list(i).name,allfloats)) %we don't have this float
                display(['downloading' list(i).name ' in ' pathe]);
                mget(f,'*.nc',pathe);
                todown=1;
            else
                sublist=dir(f,'*.nc');
                locsublist=dir([pathe '*' list(i).name '*.nc']);
                [tr,ok1]=setdiff(lower(char(sublist.name)),lower(char(locsublist.name)),'rows');
                todown1=char(sublist(ok1).name);
                remnames=char(sublist.name);
                [tr,ok1,ok2]=intersect(lower(remnames),lower(char(locsublist.name)),'rows');
                todown2=remnames(ok1(cat(1,sublist(ok1).datenum)>fix(cat(1,locsublist(ok2).datenum))),:);
                todown=[todown1; todown2];
                for j=1:size(todown,1)
                    display(['downloading' todown(j,:) ' in ' pathe]);
                    mget(f,deblank(todown(j,:)),pathe);
                end
            end
            if ~isempty(todown)
                display(['downloading' list(i).name ' in techfiles']);
                cd(f,[ftppath list(i).name '/']);
                mget(f,[list(i).name '_tech.nc'],[dire 'techfiles']);
                display(['downloading' list(i).name ' in metafiles']);
                cd(f,[ftppath list(i).name '/']);
                mget(f,[list(i).name '_meta.nc'],[dire 'metafiles']);
            end
        end
        close(f)
    case '5'
        display('Updating climatology for OW');
        path0='/coriolis';
        inst={'CTD','ARGO'};
        f=ftp(ftpaddress.ifremer,'ext-dmqc','plijad@r88');
        for i=1:length(inst)
            path=[path0 '/' inst{i} '_for_DMQC'];
            cd(f,path)
            ret=dir(f,path);
            ok=cat(1,ret.isdir);
            if any(ok)
                sdn=cat(1,ret.datenum);
                sdn(~ok)=0;
                [tr,j]=max(sdn);
                cd(f,ret(j).name);
            end
            ret=[dir(f,'*.GZ');dir(f,'*.gz')];
            for ok=1:length(ret)
                if isempty(dir([config.HISTORICAL_DIRECTORY filesep ret(ok).name]))
                    display(['Downloading ' inst{i} ' dbase: ' ret(ok).name 32 num2str(ret(ok).bytes/1012/1012) ' Mb']);
                    mget(f,ret(ok).name,config.HISTORICAL_DIRECTORY);
                    display('Unzipping..')
                    target=[config.HISTORICAL_DIRECTORY filesep 'historical_' config.(['HISTORICAL_' inst{i} '_PREFIX'])];
                    gunzip([config.HISTORICAL_DIRECTORY filesep ret(ok).name],target);
                    display(['New ' inst{i} ' climatology downloaded and un-gunzipped']);
                    tountar=dir([target filesep '*.tar']);
                    if length(tountar)>1
                        error(['more than one tar file in ' target]);
                    end
                    display('Un-tar-ing..')
                    untar([target filesep tountar.name],[target filesep]);
                    delete([target filesep tountar.name]);
                    display(['New ' inst{i} ' climatology un-tarred']);
                else
                    display(['No new ' inst{i} ' climatology since last time']);
                end
            end
        end
        close(f);
        update_ref_dbase;
        display('Edit climatology information in config file');
        edit(config.CONFIGURATION_FILE);
    case '6'
        f=ftp(ftpaddress.current,user.login,user.pwd);
        list=dir(f,ftppath);
        isdir=cat(1,list.isdir);
        list=list(isdir);
        [numr,numd,dat,pre_adj]=deal(zeros(size(list)));
        pre_adj=logical(pre_adj);
        i=1;
        for i=i:length(list)
            list(i).name
            rd=dir(f,[ftppath list(i).name '/profiles']);
            if ~isempty(rd)
                rd=rd(~cat(1,rd.isdir));
                rrd=lower(char(rd.name));
                ok=rrd(:,1)=='r' | rrd(:,1)=='d';
                rd=char(rd(ok).name);
                numr(i)=sum(rd(:,1)=='R' | rd(:,1)=='r');
                numd(i)=sum(rd(:,1)=='D' | rd(:,1)=='d');
                if numr(i)>0 && numd(i)==0
                    cd(f,[ftppath list(i).name '/profiles/']);
                    mget(f,rd(1,:));
                    rd(1,:)
                    nc=netcdf.open(rd(1,:),'nowrite');
                    howold=now-netcdf.getVar(nc,netcdf.inqVarID(nc,'JULD'))-datenum(1950,1,0); %how old is the first profile
                    netcdf.close(nc);
                    if howold<(365.25/2)
                        numr(i)=0;
                    end
                    howold
                elseif numd(i)>0
                    cd(f,[ftppath list(i).name '/profiles/']);
                    mget(f,rd(numd(i),:));
                    rd(numd(i),:)
                    nc=netcdf.open(rd(numd(i),:),'nowrite');
                    steps=netcdf.getVar(nc,netcdf.inqVarID(nc,'HISTORY_STEP'));steps=squeeze(steps(:,end,:))';
                    ok=strmatch('ARSQ',steps);
                    tdat=netcdf.getVar(nc,netcdf.inqVarID(nc,'HISTORY_DATE'));tdat=squeeze(tdat(:,end,:))';dat(i)=datenum(tdat(ok(end),:),'yyyymmddHHMMSS');
                    sce=netcdf.getVar(nc,netcdf.inqVarID(nc,'SCIENTIFIC_CALIB_EQUATION'));pre_adj(i)=~isempty(findstr('procedure 3.2',strtrim(sce(:)')));
                    if ~pre_adj(i)
                        tdat
                        pause
                    end
                    netcdf.close(nc);
                end
            end
            [numr(i) numd(i) pre_adj(i)]
        end
        gh=1;
        [k,i]=sort(numr,'descend');
        list=list(i);
        numr=numr(i);
        numd=numd(i);
        sprintf('%f of eligible profiles have been DMQCed at least once',100*sum(numd)./sum(numd+numr))
        sprintf('%f of eligible floats have been DMQCed at least once with sal',100*sum(numd>0)./sum(numd>0 | numr>0))
        sprintf('%f of eligible floats have been DMQCed at least once with both sal and pres',100*sum(numd(pre_adj)>0)./sum(numd>0 | numr>0))
        sprintf('~ %i profiles DMQCed since last year',sum(numd(dat>(now-365.25))))
        char(list.name)
        save stats list numr numd dat pre_adj 
        floatname=input('Float number ? ','s');
    case '7'
        f=ftp(ftpaddress.current,user.login,user.pwd);
        list=dir(f,ftppath);
        isdir=cat(1,list.isdir);
        list=list(isdir);
        for i=1:length(list)
            [i 317]
            list(i).name
            rd=dir(f,[ftppath list(i).name '/profiles']);
            rdn=char(rd.name);
            ok=lower(rdn(:,1))=='d';
            sincenov10(i)=sum(ok & cat(1,rd.datenum)>datenum(2010,10,30));
        end
        save sincenov10 sincenov10 list
end