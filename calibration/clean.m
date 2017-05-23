function clean(dire,files)
%eliminate r versions when d is present
%eliminate oldest of r and R or d and D when more than one case is present
filenames=char(files.name);
nums=filenames(:,2:end);
cyc=str2num(filenames(:,10:12));
todel=[];
for i=1:length(cyc)
    ok=find(cyc==cyc(i));
    if length(ok)>1
        firstletter=filenames(ok,1);
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