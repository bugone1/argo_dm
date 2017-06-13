function fetch_from_web(dire, floatname)
% FETCH_FROM_WEB  Fetch Argo files from the Coriolis FTP site
%   USAGE:
%      fetch_from_web
%   INPUTS:   
%   OUTPUTS:
%   VERSION HISTORY:
%       06 June 2017, Isabelle Gaboury: Created, based on menudmqc.m dated
%           2 Feb. 2017.

% FTP configuration
ftpaddress.ifremer='ftp.ifremer.fr';
ftpaddress.current=ftpaddress.ifremer;
ftppath='/ifremer/argo/dac/meds/';
user.login='anonymous';
user.pwd='mathieu.ouellet@dfo-mpo.gc.ca';

% Fetch the requested files from the Coriolis FTP server
f=ftp(ftpaddress.current,user.login,user.pwd);
cd(f,ftppath);
subdir=findnameofsubdir(floatname,listdirs(dire));
pathe=[dire subdir filesep];
allfloats=uniquefloatsindir(pathe);
cd(f,[ftppath floatname '/profiles/']);
downtechmeta=input('Force download of meta & tech files ? (1/0)');
if isempty(strmatch(floatname,allfloats)) %we don't have this float
    display(['downloading' floatname ' in ' pathe]);
    mget(f,'*.nc',pathe);
    todown=1;
else
    sublist=dir(f,'*.nc');
    locsublist=dir([pathe '*' floatname '*.nc']);
    a1=lower(char(sublist.name));    %what's on the server
    a2=lower(char(locsublist.name)); %what's on disk
    a2=a2(cat(1,locsublist.bytes)>0,:);
    [tr,ok1]=setdiff(a1(:,2:end),a2(:,2:end),'rows');
    todown=char(sublist(ok1).name);
    remnames=char(sublist.name);
    [tr,ok1,ok2]=intersect(lower(remnames),lower(char(locsublist.name)),'rows');
    todown2=remnames(ok1(cat(1,sublist(ok1).datenum)>fix(cat(1,locsublist(ok2).datenum))),:);
    if ~isempty(todown2)
        yn=input('Do you want to download newer versions of cycle files that already existed ? (1/0)');
        if yn==1
            todown=[todown; todown2];
        end
    end
    for j=1:size(todown,1)
        display(['downloading' todown(j,:) ' in ' pathe]);
        mget(f,deblank(todown(j,:)),pathe);
    end
end
if ~isempty(todown) || downtechmeta
    display(['downloading' floatname ' in techfiles']);
    cd(f,[ftppath floatname '/']);
    mget(f,[floatname '_tech.nc'],[dire 'techfiles']);
    display(['downloading' floatname ' in metafiles']);
    cd(f,[ftppath floatname '/']);
    mget(f,[floatname '_meta.nc'],[dire 'metafiles']);
end
close(f)

end