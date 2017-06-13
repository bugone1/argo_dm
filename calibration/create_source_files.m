function create_source_files(local_config,lo_system_configuration,floatname)
dbstop if error
ITS90toIPTS68=1.00024;
load([local_config.RAWFLAGSPRES_DIR floatname],'presscorrect','t')
s=t;
[DATES,j]=sort(cat(1,s.dates)');s=s(j);
lt=length(t);si=zeros(lt,1);

%pressure/bathy plot
clear firstpres lastpres
ook=[];
i=0;
while i<lt
    i=i+1;
    ok=find(~isnan(s(i).pres));
    firstpres(i)=s(i).pres(ok(1));
    lastpres(i)=s(i).pres(ok(end));
    ook=[ook i];
end
[cyc,j]=sort(cat(1,s(ook).cycle_number));
firstpres=firstpres(j);
lastpres=lastpres(j);
maxp=max(lastpres);minp=min(lastpres);
load('topo','topo'); %origin is at lon==0 lat==90
ix=round(cat(1,s(ook(j)).latitude)+91);
iy=round(cat(1,s(ook(j)).longitude));
iy(iy<0)=181-iy;

bathy=diag(topo(ix,iy))';
clear topo
mb=min(bathy);
a(1)=patch(cyc([1 1:end end:-1:1 1]),- [minp firstpres lastpres(end:-1:1) maxp],'b');
a(2)=plot(presscorrect.cyc(1:end-1),-presscorrect.orig_pres,'r');
a(3)=patch(cyc([1 1:end end]),[mb bathy mb],'k');
plot(cyc,-lastpres,'b','linewidth',2)
xlabel('Cycle');
ylabel('-Pressure (db)');
legend(a,'Range of Pressures sampled','Surface pres (tech file)','Bathymetry (1�)�',4);
print('-dpng',[lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep 'pres_bath_' floatname '.png']);
%pause
close

%create variables to be saved
for i=1:lt
    [i lt]
    %     plot(s(i).psal,'.b');
    s(i).pres(s(i).pres_qc=='4')=nan;
    s(i).psal(s(i).psal_qc=='4')=nan;
    s(i).temp(s(i).temp_qc=='4')=nan;
    if ~isempty(presscorrect.pres)
        s(i).cndc=sw_cndr(s(i).psal,s(i).temp*ITS90toIPTS68,s(i).pres);
        ok=find(s(i).cycle_number+1==presscorrect.cyc);
        if s(i).cycle_number>presscorrect.cyc(end)
            ok=length(presscorrect.cyc);
        end
        if ~isempty(ok)
            s(i).pres=s(i).pres-presscorrect.pres(ok);
        end
        if any(s(i).pres)<0
            warning(['Negative adj pres in ' datestr(s(i).cycle_number)]);
            pause
        end
        s(i).psal=sw_salt(s(i).cndc,s(i).temp*ITS90toIPTS68,s(i).pres);
        s(i).ptmp=sw_ptmp(s(i).psal,s(i).temp*ITS90toIPTS68,s(i).pres,0);
    end
    si(i)=length(s(i).pres);
end
[PRES,SAL,PTMP,TEMP,SAL_QC,TEMP_QC]=deal(nan(max(si),lt)); %preallocate profile with max depths
for i=1:lt
    PRES(1:si(i),i)=s(i).pres;
    SAL(1:si(i),i)=s(i).psal;
    PTMP(1:si(i),i)=s(i).ptmp;
    TEMP(1:si(i),i)=s(i).temp;
    SAL_QC(1:si(i),i)=s(i).psal_qc;
    TEMP_QC(1:si(i),i)=s(i).temp_qc;
end

%QC TS plot one more time
but=1;
load as as
ch=0;
while ~isempty(but)
    ok=(SAL_QC>'1' | TEMP_QC>'1');
    close
    plot(SAL,PTMP,'.');
    Xlim=get(gca,'xlim');
    Ylim=get(gca,'ylim');
    plot(as(:,1),as(:,2),'.','color',ones(3,1)*.9);
    plot(SAL,PTMP,'.');
    plot(SAL(ok),PTMP(ok),'o');
    set(gca,'xlim',Xlim,'ylim',Ylim);
    [x,y,but]=ginput(1);
    if ~isempty(but)
        ch=1;
        dis=((PTMP-y)/diff(Ylim)).^2+((SAL-x)/diff(Xlim)).^2;
        mdis=min(dis(:));
        [i,j]=find(dis==mdis);
        SAL(i,j)=nan;
        PTMP(i,j)=nan;
        TEMP(i,j)=nan;
        ok=s(j(1)).pres==PRES(i(1),j(1));
        s(j(1)).temp_qc(ok)='4';
        s(j(1)).psal_qc(ok)='4';
    end
end
for i=1:length(t)
    t(i).temp_qc=s(i).temp_qc;
    t(i).psal_qc=s(i).psal_qc;
    t(i).pres_qc=s(i).pres_qc;
end
save([local_config.RAWFLAGSPRES_DIR floatname],'t','-append') %save flags

LAT=cat(1,s.latitude)';
LONG=cat(1,s.longitude)';
LONG(LONG<0)=LONG(LONG<0)+360;
PROFILE_NO=cat(1,s.cycle_number)';
flnm=[lo_system_configuration.FLOAT_SOURCE_DIRECTORY floatname];
if exist(flnm,'file')
    temp=load('flnm','DATES');
    if length(temp.DATES)>length(DATES)
        error('You are about to overwrite a source file that had more profiles');
    end
    move(flnm,[lo_system_configuration.FLOAT_SOURCE_DIRECTORY 'backup']);
end
%only keep profiles with >0 non nan salinity
if ~exist(flnm,'file') || ch
    save(flnm,'DATES','LAT','LONG','PRES','TEMP','SAL','PTMP','PROFILE_NO');
end