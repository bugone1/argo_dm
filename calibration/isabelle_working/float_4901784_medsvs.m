% function float_4901784_medsvs
% Quick function to compare float 4901784 profile 61 to other profiles for
% this float and for neighbouring floats. This assumes we've already
% made a request on MEDS and fetched the file using Mathieu's
% getLatestMedsAsciiFile
%
% IG, 29 Aug. 2017

% Setup
float_num = '4901784';
cycle_num = 63;
medsvs_file = 'MEDS_ASCII2910475899.DAT;1';
data_dir = 'data/4901000';
file_type = 'R';
reload=1;

% Load the profile data, get the profile index
if reload==1
    t=read_all_nc(data_dir,dir([data_dir filesep file_type float_num '*.nc']),[],[0,0],0); 
    t_b=read_all_nc(data_dir,dir([data_dir filesep 'B' file_type float_num '*.nc']),[],[0,0],1); 
end
if any([t.cycle_number] ~= [t_b.cycle_number]), error('Cycle numbers don''t match'); end
lt=length(t);
ii_prof = find([t.cycle_number]==cycle_num);
si = zeros(1,lt);   
for ii_cyc=1:lt, si(ii_cyc) = length(t(ii_cyc).pres); end
[PRES,PSAL,TEMP,TEMP_DOXY]=deal(nan(max(si),lt)); %preallocate profile with max depths
for i=1:lt
    PRES(1:si(i),i)=t(i).pres;
    PSAL(1:si(i),i)=t(i).psal;
    TEMP(1:si(i),i)=t(i).temp;
    TEMP_DOXY(1:si(i),i)=t_b(i).temp_doxy;
end

% Load and pre-process the medsvs results
if reload==1
    [stat,prf]=agg_ocproc(strtok(medsvs_file,'.'));
    [tokeep,todel]=get_nonCanArgoTESACindicesOcproc(stat);
    stat=stat(tokeep);
    prf=prf(tokeep,:);
    sdn=get_sdn(stat); 
    ll=get_ll(stat); 
    o=alignocprocprof(prf); 
    crn=get_crnumber(stat);
    ok=crn(:,1)=='Q';crn(ok,1:7)=crn(ok,2:8);crn(ok,9:10)=' '; %remove Q and YY
    z=o.pres;ok=isnan(o.pres);z(ok)=o.deph(ok); 
end
    
% Plots: comparison with historical
subplot(1,2,1); foo1 = plot(o.temp,z,'c'); hold on;
foo2 = plot(TEMP,PRES,'b'); 
foo3=plot(t(ii_prof).temp,t(ii_prof).pres,'r'); set(foo3,'linewidth',2);
xlabel('Temperature (^{\circ}C)'); ylabel('Pressure (dBar)'); grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
legend([foo1(1),foo2(1),foo3],'Historical: 43N-45N, 131-133W, 2010-2017', ...
    ['Float ' float_num], ['Profile ' num2str(cycle_num)], 'location','SouthEast');
subplot(1,2,2); 
foo1 = plot(o.psal,z,'c'); hold on; 
foo2 = plot(PSAL,PRES,'b'); 
foo3=plot(t(ii_prof).psal,t(ii_prof).pres,'r'); set(foo3,'linewidth',2);
xlabel('Salinity (psu)'); ylabel('Pressure (dBar)'); grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
legend([foo1(1),foo2(1),foo3],'Historical: 43N-45N, 131-133W, 2010-2017', ...
    ['Float ' float_num], ['Profile ' num2str(cycle_num)], 'location','SouthEast');

% Plots: temp vs. temp_doxy
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
subplot(1,3,3);
plot(TEMP_DOXY-TEMP,PRES,'b'); 
hold on; foo = plot(TEMP_DOXY(:,ii_prof)-TEMP(:,ii_prof),PRES(:,ii_prof),'r'); set(foo,'linewidth',2);
grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
xlabel('TEMP\_DOXY-TEMP (^{\circ}C)'); ylabel('Pressure (dBar)');

 % end