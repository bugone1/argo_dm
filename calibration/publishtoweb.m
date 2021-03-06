function publishtoweb(local_config,lo_system_configuration,floatNum,pub,user_id,ftp_url,ftp_path)
% PUBLISHTOWEB Prepare plots summarizing the result of Argo DMQC,
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
% OPTIONAL INPUTS:
%   ftp_url - URL of the FTP server. Default is the MEDS FTP site
%   ftp_path - path on the FTP server to which files are to be uploaded.
%       Default is /pub/argo/
% VERSION HISTORY:
%   03 Feb. 2017 (and before): Creation and updates, history not tracked
%       here
%   20 Jun. 2017, Isabelle Gaboury: Added documentation header; changed the
%       figure export calls slightly so that PNGs are created on both
%       Windows and Linux systems (assuming the Java desktop is available)
%   23 Jun. 2017, IG: Modified the FTP option to use FTP
%   02 Aug. 2017, IG: ZIP files now stored in a "zip" sub-directory
%   08 Aug. 2017, IG: Added DOXY plots
%   10 Aug. 2017, IG: Added a line to the plot of the conductivity
%       adjustment to improve visibility
%   29 Aug. 2017, IG: Upload the KML file
%   25 Jan. 2018, IG: Fixed a minor bug in plotting data where all samples
%       have bad QC flags
%   11 Jan. 2019, IG: Added ftp_url and ftp_path optional inputs

% Close any existing plots so we can start with a clean slate
close all

% Default inputs
if nargin<7, ftp_path = '/pub/Argo/'; 
elseif ~strcmpi(ftp_path(end),'/'), ftp_path=[ftp_path '/']; 
end
if nargin<6, ftp_url='dfonk1awvwsp002.dfo-mpo.gc.ca'; end

opathe=lo_system_configuration.FLOAT_PLOTS_DIRECTORY;
%pathe=[lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep];
pathe='C:/Users/maz/Desktop/MEDS Project/argo_dm/data/float_plots/';
uc='changed';
flnm=[dir([local_config.OUT uc filesep 'D' floatNum '_*.nc']); dir([local_config.OUT uc filesep 'R' floatNum '_*.nc'])];
clean([local_config.OUT uc],flnm, 0);
flnm=[dir([local_config.OUT uc filesep 'D' floatNum '_*.nc']); dir([local_config.OUT uc filesep 'R' floatNum '_*.nc'])];
flnm_b=[dir([local_config.OUT uc filesep 'BD' floatNum '_*.nc']); dir([local_config.OUT uc filesep 'BR' floatNum '_*.nc'])];
if ~isempty(flnm_b)
    clean([local_config.OUT uc],flnm_b, 1);
    flnm_b=[dir([local_config.OUT uc filesep 'BD' floatNum '_*.nc']); dir([local_config.OUT uc filesep 'BR' floatNum '_*.nc'])];
end
% uflnm=char(flnm.name);
% is_bfile=uflnm(:,1)=='B';
% flnm2=uflnm(~is_bfile,2:end);
% [ii,jj]=unique(flnm2,'rows');
% dup=setdiff(find(~is_bfile),jj);
% todel=dup(uflnm(dup,1)=='R');
% if any(is_bfile)
%     flnm2=uflnm(is_bfile,3:end);
%     [ii,jj]=unique(flnm2,'rows');
%     dup=setdiff(find(is_bfile),jj);
%     todel=[todel,dup(uflnm(dup,2)=='R')];
% end
% for i=1:length(todel)
%     delete([local_config.OUT uc filesep flnm(todel(i)).name]);
% end
% flnm(todel)=[];
% uflnm(todel,:)=[];
% is_bfile(todel)=[];
% flnm_b=flnm(is_bfile);
% flnm=flnm(~is_bfile);
for i=1:length(flnm);
    flnm(i)
    [s(i),h(i)]=getcomments([local_config.OUT uc filesep flnm(i).name]);
    t(i)=read_nc([local_config.OUT uc filesep flnm(i).name]);
end
if isempty(flnm_b), s_b=[];
else
    for i=1:length(flnm_b);
        flnm_b(i)
        [s_b(i),h_b(i)]=getcomments([local_config.OUT uc filesep flnm_b(i).name]);
        t_b(i)=read_nc([local_config.OUT uc filesep flnm_b(i).name],1);
    end
end
col='rgbymck';
sym='o.+udvs';
lin=' -     ';
texx={'Previous','New'};
[x,y,z]=getcoeffs(s);
save foranh x y z
load([lo_system_configuration.FLOAT_CALIB_DIRECTORY filesep 'cal_' floatNum '.mat'],'pcond_factor','PROFILE_NO');
for i=1:2
    dates=minmax(x(:,i));
    if ~all(isnan(dates))
        a(i)=plot(z,y(:,i),[col(i) sym(i) lin(i)]);
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
    writehtml(s,floatNum,pathe,s_b)
catch
    warning('Error writing HTML file');
end
suff={'','_adjusted'};
titre={'raw','adjusted'};
col='bgmr';
vars={'PSAL','TEMP'};
if ~isempty(flnm_b) && isfield(t_b,'doxy'), vars{3}='DOXY'; end
clear XX YY ZZ
for i=1:2 %raw then adj
    ts=[cat(2,t.(['psal' suff{i}])); cat(2,t.(['temp' suff{i}]))]';
    if length(vars)==3
        ts(:,3) = cat(2,t_b.(['doxy' suff{i}]))';
    end
    ts(ts==99999)=nan;
    tsf=[(cat(2,t.(['psal' suff{i} '_qc']))-'0')' (cat(2,t.(['temp' suff{i} '_qc']))-'0')'];
    if length(vars)==3
        tsf(:,3) = (cat(2,t_b.(['doxy' suff{i} '_qc']))-'0')';
    end
    mtsf=max(tsf(:,1:2),[],2);
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
    for j=1:length(vars) %sal then temp
        if i==2 && strcmp(vars{j},'DOXY'), continue; end
        Z=ts(:,j);	%parm value
        ok=tsf(:,j)>2; %set all values with flags>2 to nan
        Z(ok)=nan;
        zlim1=minmax(Z);
        contour_plot(X,Y,Z,xlim,ylim,zlim1);
        title([floatNum ' ' vars{j} ' ' titre{i} ' flags 1 & 2']);
        XXg{i,j}=X;        YYg{i,j}=Y;        ZZg{i,j}=ts(:,j);
        set(gca,'xlim',xlim,'ylim',ylim);
        if any(~isnan(zlim1)), set(gca,'clim',zlim1); end
        if ispc || usejava('desktop')
            print('-dpng',[pathe floatNum '_' vars{j} '_' titre{i}(1) '.png']);
        end
        close
        Z=ts(:,j);	%parm value
        ok=tsf(:,j)<3; %set all values with flags<3 to nan
        Z(ok)=nan;
        contour_plot(X,Y,Z,xlim,ylim,minmax([Z(:); zlim1(:)]));
        title([floatNum ' ' vars{j} ' ' titre{i} ' flags 3 & 4']);
        set(gca,'xlim',xlim,'ylim',ylim);
        if any(~isnan(zlim1)), set(gca,'clim',zlim1); end
        if ispc || usejava('desktop')
            print('-dpng',[pathe floatNum '_' vars{j} '_' titre{i}(1) '_3&4.png']);
        end
        close
    end
end

for j=1:length(vars)
    if strcmp(vars{j},'DOXY'), continue; end
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
% if ~isempty(flnm_b) && isfield(t_b,'doxy')
%     err=cat(2,t_b.doxy_adjusted_error)';err(err==99999)=nan;
%     contour_plot(X,Y,err,xlim,ylim,minmax(err)+[-.001 .001]);
%     if ispc || usejava('desktop')
%         print('-dpng',[pathe floatNum '_DOXY_err.png']);
%     end
%     close
% end
    
% ZIP the NetCDF files
if pub
    zip(['zip' filesep floatNum],[local_config.OUT uc filesep '*' floatNum '_*.nc']);
end

% Create the file containing the FTP commands that will be input to sftp
% below. We create this intermediate file to avoid having to enter the
% password multiple times, as sftp cannot accept a password from the
% command line, and as of June 2017 it is not possible to copy a key over
% to the FTP server
% fid=fopen(['sftp_' floatNum '.txt'],'w');
% fprintf(fid,['cd ' ftp_path 'DM/PICorner\n']);
% fprintf(fid,['put ' pathe '*' floatNum '*.png\n']);
% fprintf(fid,['put ' pathe '*' floatNum '*.htm\n']);
% fprintf(fid,['put ' opathe '*' floatNum '*.png\n']);
% fprintf(fid,['put ' local_config.BASE 'kml' filesep floatNum '.kml\n']);
% fprintf(fid,['cd ' ftp_path 'DM\n']);
% if pub
%     fprintf(fid,['put ' local_config.BASE filesep 'zip' filesep floatNum '.zip\n']);
% end
% fprintf(fid,'bye');
% fclose(fid);
    
% Actually upload
% system(['sftp ' user_id '@' ftp_url ' < sftp_' floatNum '.txt']);
user_id='maz';
pw_id='Maz2407*';
% fhandle=ftp(ftp_url,user_id,pw_id);
% cd(fhandle,[ftp_path 'DM/']);
% mput(fhandle,[local_config.BASE filesep 'zip' filesep floatNum '.zip']);
% cd(fhandle,'picorner');
% mput(fhandle,[pathe '*' floatNum '*.png']);
% mput(fhandle,[pathe '*' floatNum '*.htm']);
% mput(fhandle,[opathe '*' floatNum '*.png']);
% mput(fhandle,[local_config.BASE 'kml' filesep floatNum '.kml']);

% Delete the temporary file (temporarily commented out, for troubleshooting
% purposes)
% delete(['sftp_' floatNum '.txt']);
    
end