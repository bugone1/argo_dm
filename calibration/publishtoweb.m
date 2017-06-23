function publishtoweb(local_config,lo_system_configuration,floatNum,pub,user_id)
% PUBLISHTOWEB - Prepare plots summarizing the result of Argo DMQC,
%   assemble plots and updated NetCDF files, upload to the MEDS FTP site
% USAGE: 
%   publishtoweb(local_config,lo_system_configuration,floatNum,pub)
% INPUTS:
%   local_config - Structure of configuration data; the only required
%       fields are "OUT", the base working directory, and "OUT", the
%       destination directory for the updated NetCDF files
%   lo_system_configuration - Structure of OW configuration data; required
%       fields are "FLOAT_PLOTS_DIRECTORY" and "FLOAT_CALIB_DIRECTORY", the
%       directories containing the plots and mat files, respectively,
%       generated by the OW routines.
%   floatNum - Float number, as a string
%   pub - 0/1 flag defining whether or not to include the NetCDF output
%       files
%   user_id - FTP user ID
% VERSION HISTORY:
%   3 February 2017 (and before): Creation and updates, history not tracked
%       here
%   20 June 2017, Isabelle Gaboury: Added documentation header; changed the
%       figure export calls slightly so that PNGs are created on both
%       Windows and Linux systems (assuming the Java desktop is available)
%   23 June 2017, IG: Modified the FTP option to use FTP

% Close any existing plots so we can start with a clean slate
close all

opathe=lo_system_configuration.FLOAT_PLOTS_DIRECTORY;
pathe=[lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep];
uc='changed';
flnm=dir([local_config.OUT uc filesep '*' floatNum '_*.nc']);
uflnm=char(flnm.name);
flnm2=uflnm(:,2:end);
[ii,jj]=unique(flnm2,'rows');
dup=setdiff(1:size(uflnm,1),jj);
todel=dup(uflnm(dup,1)=='R');
for i=1:length(todel)
    delete([local_config.OUT uc filesep flnm(todel(i)).name]);
end
for i=1:length(flnm);
    flnm(i)
    [s(i),h(i)]=getcomments([local_config.OUT uc filesep flnm(i).name]);
    t(i)=read_nc([local_config.OUT uc filesep flnm(i).name]);
end
col='rgbymck';
sym='o.+udvs';
texx={'Previous','New'};
[x,y,z]=getcoeffs(s);
save foranh x y z
load([lo_system_configuration.FLOAT_CALIB_DIRECTORY filesep 'cal_' floatNum '.mat'],'pcond_factor','PROFILE_NO');
for i=1:2
    dates=minmax(x(:,i));
    if ~all(isnan(dates))
        a(i)=plot(z,y(:,i),[col(i) sym(i)]);
        legtext{i}=[texx{i} ' ' datestr(dates(1),1) ':' datestr(dates(2),1)];
    else
        a(i)=0;
        legtext{i}=[];
    end
end
a(3)=plot(PROFILE_NO,pcond_factor,'.b');
legtext{3}='OW recommendation';
ylabel('Multiplicative conductivity coefficient');
xlabel('Cycle #');
clear j
ii=0;
for i=1:length(legtext)
    if ~isempty(legtext{i})
        ii=ii+1;
        j(ii)=i;
    end
end
legend(a(j),legtext(j));
if ispc || usejava('desktop')
    print('-dpng',[pathe floatNum '_PSAL_conductivity_adjustment.png']);
end
close

try
    writehtml(s,floatNum,pathe)
catch
end
suff={'','_adjusted'};
titre={'raw','adjusted'};
col='bgmr';
vars={'PSAL','TEMP'};
clear XX YY ZZ
for i=1:2 %raw then adj
    ts=[cat(2,t.(['psal' suff{i}])); cat(2,t.(['temp' suff{i}]))]';
    ts(ts==99999)=nan;
    tsf=[(cat(2,t.(['psal' suff{i} '_qc']))-'0')' (cat(2,t.(['temp' suff{i} '_qc']))-'0')'];
    mtsf=max(tsf,[],2);
    [leg,nu]=deal(zeros(4,1));
    for j=1:4
        nu(j)=sum(mtsf==j & ~isnan(ts(:,1)) & ~isnan(ts(:,2))); %find how many values associated with each flag
    end
    [tr,k]=sort(nu,'descend');
    for j=1:4 %plot highest number of flags first
        ok=find(mtsf==k(j) & ~isnan(ts(:,1)) & ~isnan(ts(:,2)));
        title([floatNum ' TS ' titre{i}]);
        if ~isempty(ok)
            plot(ts(ok,1),ts(ok,2),['.' col(k(j))]);
            leg(k(j))=plot(ts(ok(1),1),ts(ok(1),2),['.' col(k(j))]);
        end
    end
    xlabel('Salinity');ylabel('Temperature');
    ok=find(leg~=0);
    legend(leg(ok),num2str(ok));
    if ispc || usejava('desktop')
        print('-dpng',[pathe floatNum '_ts_' titre{i}(1) '.png']);
    end
    close
    
    X=[]; %vector of cycle numbers
    for o=1:length(t)
        X=[X ones(1,length(t(o).pres))*double(t(o).cycle_number)];
    end
    X=X';
    Y=cat(2,t.pres)';	%depth vector, same dimensions as X
    Y(Y==99999 | abs(Y)>1e38)=nan;
    ylim=minmax(Y);
    xlim=minmax(X);
    for j=1:2 %sal then temp
        Z=ts(:,j);	%parm value
        ok=tsf(:,j)>2; %set all values with flags>2 to nan
        Z(ok)=nan;
        zlim1=minmax(Z);
        contour_plot(X,Y,Z,xlim,ylim,zlim1);
        title([floatNum ' ' vars{j} ' ' titre{i} ' flags 1 & 2']);
        XXg{i,j}=X;        YYg{i,j}=Y;        ZZg{i,j}=ts(:,j);
        set(gca,'xlim',xlim,'ylim',ylim,'clim',zlim1);
        if ispc || usejava('desktop')
            print('-dpng',[pathe floatNum '_' vars{j} '_' titre{i}(1) '.png']);
        end
        close
        Z=ts(:,j);	%parm value
        ok=tsf(:,j)<3; %set all values with flags<3 to nan
        Z(ok)=nan;
        contour_plot(X,Y,Z,xlim,ylim,minmax([Z(:); zlim1(:)]));
        title([floatNum ' ' vars{j} ' ' titre{i} ' flags 3 & 4']);
        set(gca,'xlim',xlim,'ylim',ylim,'clim',zlim1);
        if ispc || usejava('desktop')
            print('-dpng',[pathe floatNum '_' vars{j} '_' titre{i}(1) '_3&4.png']);
        end
        close
    end
end

for j=1:2
    title([floatNum ' ' vars{j} ' ADJ-RAW' ]);
    X=XXg{2,j};
    Y=YYg{2,j};
    Z=ZZg{2,j}-ZZg{1,j};
    contour_plot(X,Y,Z,xlim,ylim,minmax(Z));
    if ispc || usejava('desktop')
        print('-dpng',[pathe floatNum '_' vars{j} '_ADJ-RAW.png']);
    end
    close
end
title([floatNum ' PRES ADJ-RAW' ]);
for i=1:length(t)
    t(i).pres_adjusted(t(i).pres_adjusted==99999)=nan;
    t(i).pres(t(i).pres==99999)=nan;
    dpy(i)=mean(t(i).pres_adjusted-t(i).pres);
    dpx(i)=t(i).cycle_number;
    dpz(i)=diff(minmax(t(i).pres_adjusted-t(i).pres));
    mp(i)=min(t(i).pres_adjusted);
end
clear a
a(1)=plot(dpx,dpy);
plot(dpx,dpy+dpz,'b');
plot(dpx,dpy-dpz,'b');
a(2)=plot(dpx,mp,'r');
set(gca,'ylim',minmax([0 dpy])+[-.1 .1]);
ok=find(mp<0);
for i=1:length(ok)
    ok1=t(ok(i)).pres_adjusted<0;
    if any(t(ok(i)).pres_adjusted_qc(ok1)=='1' & t(ok(i)).psal_adjusted_qc(ok1)=='1' & t(ok(i)).temp_adjusted_qc(ok1)=='1')
        dbstop if error
        error('Negative pres adjust unflagged');
    end
end
ok=find(dpy>=5);
for i=1:length(ok)
    if any(t(ok(i)).pres_adjusted_qc=='1')
        dbstop if error
        error('Should flag pres to 2');
    end
end
legend(a,{'ADJ-RAW','Min pres adj'});
if ispc || usejava('desktop')
    print('-dpng',[pathe floatNum '_PRES_ADJ-RAW.png']);
end

close
err=cat(2,t.psal_adjusted_error)';err(err==99999)=nan;
contour_plot(X,Y,err,xlim,ylim,minmax(err)+[-.001 .001]);
if ispc || usejava('desktop')
    try
        print('-dpng',[pathe floatNum '_PSAL_err.png']);
    catch
        plot(0)
        print('-dpng',[pathe floatNum '_PSAL_err.png']);
    end
end
close
err=cat(2,t.temp_adjusted_error)';err(err==99999)=nan;
contour_plot(X,Y,err,xlim,ylim,minmax(err)+[-.001 .001]);
if ispc || usejava('desktop')
    print('-dpng',[pathe floatNum '_TEMP_err.png']);
end
close
if pub
    zip(floatNum,[local_config.OUT uc filesep '*' floatNum '_*.nc']);
end

% Upload the files to the MEDS FTP server
% The following lines are being temporarily kept for reference, but as of
% June 2017 they do not work (plain FTP and the alphapro user are no longer
% supported).
% f=ftp('ftp.meds-sdmm.dfo-mpo.gc.ca','alphapro','aiLahm4u');
% binary(f);
% cd(f,'/pub/Argo/DM/PICorner')
% cd(pathe)
% mput(f,['*' floatNum '*.png']);
% ascii(f);
% mput(f,['*' floatNum '*.htm']);
% cd(opathe)
% binary(f);
% mput(f,['*' floatNum '*.png']);
% cd(f,'/pub/Argo/DM');
% binary(f);
% if pub
%     cd('../../../calibration')
%     mput(f,[floatNum '.zip'])
% end
% close(f)
%%% Another set of lines being kept (temporarily) for reference, copying the
%%% files into a temporary directory
% ftp_dir = [local_config.BASE '..' filesep 'ready_to_ftp' filesep floatNum filesep];
% ftp_dir_pi = [ftp_dir 'PICorner/'];
% mkdir(ftp_dir_pi);
% cd(pathe)
% copyfile(['*' floatNum '*.png'], ftp_dir_pi);
% copyfile(['*' floatNum '*.htm'], ftp_dir_pi);
% cd(opathe)
% copyfile(['*' floatNum '*.png'], ftp_dir_pi);
% if pub
%     cd('../../../calibration')
%     copyfile([floatNum '.zip'], ftp_dir);
% end

% Create the file containing the FTP commands that will be input to sftp
% below. We create this intermediate file to avoid having to enter the
% password multiple times, as sftp cannot accept a password from the
% command line, and as of June 2017 it is not possible to copy a key over
% to the FTP server
fid=fopen(['sftp_' floatNum '.txt'],'w');
fprintf(fid,'cd /pub/Argo/DM/PICorner\n');
fprintf(fid,['put ' pathe '*' floatNum '*.png\n']);
fprintf(fid,['put ' pathe '*' floatNum '*.htm\n']);
fprintf(fid,['put ' opathe '*' floatNum '*.png\n']);
fprintf(fid,'cd /pub/Argo/DM\n');
if pub
    fprintf(fid,['put ' opathe '../../../calibration' filesep floatNum '.zip\n']);
end
fprintf(fid,'bye');
fclose(fid);
    
% Actually upload
system(['sftp ' user_id '@ftp.meds-sdmm.dfo-mpo.gc.ca < sftp_' floatNum '.txt']);

% Delete the temporary file (temporarily commented out, for troubleshooting
% purposes)
% delete(['sftp_' floatNum '.txt']);
    
end