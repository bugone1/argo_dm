function float_medsvs(float_num,medsvs_file,cycle_num, title_string)
% Compare float profile to other profiles for this float and for
% neighbouring floats. This assumes we've already made a request on MEDS
% and fetched the file using Mathieu's getLatestMedsAsciiFile
%
% IG, 11 Sep. 2017

% Setup
data_dir = '/u01/rapps/argo_dm/calibration/data/4901000';
file_type = 'R';
reload=1;
if nargin < 3, cycle_num = []; end
if nargin<4, title_string = ''; end

addpath('/u01/rapps/argo_dm/calibration');

% Load the profile data, get the profile index
if reload==1
    t=read_all_nc(data_dir,dir([data_dir filesep file_type float_num '*.nc']),[],[0,0],0); 
    if ~isempty(dir([data_dir filesep 'B' file_type float_num '*.nc']))
        b_files=1;
        t_b=read_all_nc(data_dir,dir([data_dir filesep 'B' file_type float_num '*.nc']),[],[0,0],1); 
    else
        b_files=0;
        t_b=[];
    end
end
if b_files==1 && any([t.cycle_number] ~= [t_b.cycle_number]), error('Cycle numbers don''t match'); end
lt=length(t);
if ~isempty(cycle_num)
    [foo,ii_prof,foo] = intersect([t.cycle_number],cycle_num);
else ii_prof = [];
end
si = zeros(1,lt);   
for ii_cyc=1:lt, si(ii_cyc) = length(t(ii_cyc).pres); end
[PRES,PSAL,TEMP,TEMP_DOXY]=deal(nan(max(si),lt)); %preallocate profile with max depths
for i=1:lt
    PRES(1:si(i),i)=t(i).pres;
    PSAL(1:si(i),i)=t(i).psal;
    TEMP(1:si(i),i)=t(i).temp;
    if b_files==1, TEMP_DOXY(1:si(i),i)=t_b(i).temp_doxy; end
end

% Load and pre-process the medsvs results
if reload==1
    [stat,prf]=agg_ocproc(strtok(medsvs_file,'.'));
    [crn,fxd]=get_crnumber(stat);
    if size(unique(crn,'rows'),1) > 1
        [tokeep,todel]=get_nonCanArgoTESACindicesOcproc(stat);
        stat=stat(tokeep);
        prf=prf(tokeep,:);
    end
    sdn=get_sdn(stat); 
    ll=get_ll(stat); 
    o=alignocprocprof(prf); 
    crn=get_crnumber(stat);
    ok=crn(:,1)=='Q';crn(ok,1:7)=crn(ok,2:8);crn(ok,9:10)=' '; %remove Q and YY
    if isfield(o,'pres')
        z=o.pres;ok=isnan(o.pres);z(ok)=o.deph(ok); 
    elseif isfield(o,'deph')
        z=[]
    end
end
    
% Plots: comparison with historical
if ~isempty(z) && isfield(o,'temp')
    subplot(1,2,1); foo1 = plot(o.temp,z,'c'); hold on;
else foo1=[]
end
foo2 = plot(TEMP,PRES,'b'); 
foo3=[];
for ii=1:length(ii_prof)   
    foo3(ii)=plot(t(ii_prof(ii)).temp,t(ii_prof(ii)).pres,'r'); 
end
set(foo3,'linewidth',2);
xlabel('Temperature (^{\circ}C)'); ylabel('Pressure (dBar)'); grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
leg_h = [];
leg_txt = {};
if ~isempty(foo1)
    leg_h(1) = foo1(1);
    leg_txt{1} = 'Historical';
end
leg_h(2) = foo2(1);
leg_txt{2} = ['Float ' float_num];
if ~isempty(ii_prof)
    leg_h(3) = foo3(1);
    if length(ii_prof)==1, leg_txt{3} = ['Profile ' num2str(cycle_num)];
    else leg_txt{3} = ['Profiles ' num2str(cycle_num(1)) '-' num2str(cycle_num(end))];
    end
end
legend(leg_h, leg_txt, 'location','SouthEast');
title(title_string)
subplot(1,2,2); 
if isfield(o,'psal')
    foo1 = plot(o.psal,z,'c'); hold on; 
end
foo2 = plot(PSAL,PRES,'b'); 
foo3 = [];
for ii=1:length(ii_prof)
    foo3(ii)=plot(t(ii_prof(ii)).psal,t(ii_prof(ii)).pres,'r'); 
end
set(foo3,'linewidth',2); 
xlabel('Salinity (psu)'); ylabel('Pressure (dBar)'); grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
legend(leg_h, leg_txt, 'location','SouthEast');
title(title_string)

% Plots: temp vs. temp_doxy
if b_files==1
    figure
    subplot(1,3,1); 
    foo1=plot(TEMP,PRES,'b');
    foo2=plot(t(ii_prof-1).temp,t(ii_prof-1).pres,'c',t(ii_prof+1).temp,t(ii_prof+1).pres,'c',t(ii_prof).temp,t(ii_prof).pres,'r'); set(foo2,'linewidth',2);
    xlabel('TEMP (^{\circ}C)'); ylabel('PRES (dBar)');
    grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
    legend([foo1(1),foo2(1),foo2(3)],['Float ' float_num], ['Profiles ' num2str(cycle_num-1) ',' num2str(cycle_num+1)], ['Profile ' num2str(cycle_num)], 'location','SouthEast');
    subplot(1,3,2);
    foo1=plot(TEMP_DOXY,PRES,'b');
    foo2=plot(t_b(ii_prof-1).temp_doxy,t_b(ii_prof-1).pres,'c',t_b(ii_prof+1).temp_doxy,t_b(ii_prof+1).pres,'c',t_b(ii_prof).temp_doxy,t_b(ii_prof).pres,'r'); set(foo2,'linewidth',2);
    xlabel('TEMP\_DOXY (^{\circ}C)'); ylabel('PRES (dBar)');
    grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
    legend([foo1(1),foo2(1),foo2(3)],['Float ' float_num], ['Profiles ' num2str(cycle_num-1) ',' num2str(cycle_num+1)], ['Profile ' num2str(cycle_num)], 'location','SouthEast');
    title(title_string)
    subplot(1,3,3);
    plot(TEMP_DOXY-TEMP,PRES,'b'); 
    hold on; foo = plot(TEMP_DOXY(:,ii_prof)-TEMP(:,ii_prof),PRES(:,ii_prof),'r'); set(foo,'linewidth',2);
    grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
    xlabel('TEMP\_DOXY-TEMP (^{\circ}C)'); ylabel('Pressure (dBar)');
end
 % end