function [filestoprocess,floatname,ow]=menudmqc_ig(local_config,config,argu)
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
%       July 2017, IG: Updated to handle b-files; assorted minor changes.

% Setup
ftpaddress.ifremer='ftp.ifremer.fr';   % FTP address for the climatology
ftpaddress.current=ftpaddress.ifremer;
ftppath='/ifremer/argo/dac/meds/';
user.login='anonymous';
user.pwd='mathieu.ouellet@dfo-mpo.gc.ca';
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
        % pathe=[dire findnameofsubdir(q,dirs) filesep];
        pathe = [dire q(2:end) filesep];
        %allfilestoprocess=dir([pathe '*' q(2:end) '*.nc']);
        allfilestoprocess=[dir([pathe 'D' q(2:end) '*.nc']);dir([pathe 'R' q(2:end) '*.nc'])];
        allfilestoprocess_b=[dir([pathe 'BD' q(2:end) '*.nc']);dir([pathe 'BR' q(2:end) '*.nc'])];
        if ~isempty(allfilestoprocess)
            clean(pathe,allfilestoprocess);
            allfilestoprocess=[dir([pathe 'D' q(2:end) '*.nc']);dir([pathe 'R' q(2:end) '*.nc'])];
            filestoprocess=orderfilesbycycle(allfilestoprocess);
            allfilestoprocess=allfilestoprocess(cat(1,allfilestoprocess.bytes)>0);
            undr=find(allfilestoprocess(1).name=='_');
            floatname=allfilestoprocess(1).name(2:undr-1);          
        else
            floatname=q(2:end);
        end
        if ~isempty(allfilestoprocess_b)
            clean(pathe,allfilestoprocess,1);
            allfilestoprocess=[dir([pathe 'BD' q(2:end) '*.nc']);dir([pathe 'BR' q(2:end) '*.nc'])];
            filestoprocess_b=orderfilesbycycle(allfilestoprocess);
            names = strvcat(filestoprocess.name);
            names_b = strvcat(filestoprocess_b.name);
            if  any(any(names(:,2:end)~=names_b(:,3:end)))
                error('Current version of the code requires that core and b files match exactly');
            else
                filestoprocess(:,2)=filestoprocess_b;
            end
        end
        if largu>2
            qow=argu{3};
            display(['Processing step selected via argu: ', num2str(qow)])
        else
            qow=input('0)FTP 1)Pre-OW, 2)OW, 3)Post-OW, 4)Publish to web?'); %, 5)Delete local files ?');
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
        update_OW_climatologies;
        filestoprocess=[];
    case '6'  % Calculate statistics
        % IG TEMP LINE
        %floats_to_exclude={'4901789','4902426','4902427','4902428','4902430','4902431','4902432','4902433'};
        floats_to_exclude={};
        [list,numr,numd,numbr,numbd,dat,pre_adj,doxy_visqc,dat_deploy,dat_lastd]=calculate_server_stats(ftpaddress.current,...
            user.login,user.pwd,ftppath,[local_config.DATA,filesep,'temp'],365.25/2,floats_to_exclude,0);
%         [k,i]=sort({list.name});
%         list=list(i);
%         dat=dat(i);
%         numr=numr(i);
%         numd=numd(i);
%         numbr=numbr(i);
%         numbd=numbd(i);
%         pre_adj=pre_adj(i);
%         save stats list numr numd numbr numbd dat pre_adj doxy_visqc dat_deploy dat_lastd
%         dlmwrite('stats.txt',[str2num(vertcat(list.name)), pre_adj, numr, numd, numbr, numbd],'precision','%d');
%         sprintf('%f of eligible profiles have been DMQCed at least once',100*sum(numd)./sum(numd+numr))
%         sprintf('%f of eligible floats have been DMQCed at least once with sal',100*sum(numd>0)./sum(numd>0 | numr>0))
%         sprintf('%f of eligible floats have been DMQCed at least once with both sal and pres',100*sum(numd(pre_adj)>0)./sum(numd>0 | numr>0))
%         sprintf('~ %i profiles DMQCed since last year',sum(numd(dat>(now-365.25))))
%         sprintf('%f of eligible DOXY profiles have been visually QCd at least once',100*sum(max([numbd numd.*doxy_visqc],[],2))./sum(numbr+numbd));
%         sprintf('%f of eligible DOXY profiles have been DMQCed at least once',100*sum(numbd)./sum(numbd+numbr))
        ow = zeros(1,6);
end