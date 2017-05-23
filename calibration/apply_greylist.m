%function apply_greylist
%Called by viewplotsnew.m
%applies greylist
%ftp://ftp.ifremer.fr/ifremer/argo/ar_greylist.txt
%ftp://usgodae2.usgodae.org/pub/outgoing/argo/ar_greylist.txt

greylisted=0;
    if (strmatch(name_root,GREY)) %greylisted data come through with qc=3 but they are bad.
        for KK=1:length(GREY) %Find the latest instance of listing
            if strmatch(name_root,GREY(KK))
                %if DATESnew == nan | (DATESnew > START_DAY(KK)/365.25 & DATESnew < END_DAY(KK)/365.25) %DATESnew comes as decimal year
                greylisted = 1;
                h=msgbox(['BAD DATA FROM  ' datestr(START_DAY(KK),1) ' TO ' DATESTR(END_DAY(KK),1)],'GREYLISTED FLOAT');
                pause(3)
                delete(h)
            end
        end
    end
    