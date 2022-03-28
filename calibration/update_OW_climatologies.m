function update_OW_climatologies
     ftpaddress.ifremer='ftp.ifremer.fr';
  ftpaddress.current=ftpaddress.ifremer;
  ftppath='/ifremer/argo/dac/meds/';
  user.login='anonymous';
   user.pwd='mathieu.ouellet@dfo-mpo.gc.ca';

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
                target=[config.HISTORICAL_DIRECTORY fileparts(config.(['HISTORICAL_' inst{i} '_PREFIX']))];
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

end