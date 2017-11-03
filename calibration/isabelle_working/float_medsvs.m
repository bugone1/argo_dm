function float_medsvs(float_num,medsvs_file,cycle_num, title_string)
% Compare float profile to other profiles for this float and for
% neighbouring floats. This assumes we've already made a request on MEDS
% and fetched the file using Mathieu's getLatestMedsAsciiFile
%
% IG, 11 Sep. 2017
% IG, 10 Oct. 2017 - Improved handling of data directory and mixes of R and
%   D files; removed some leftover lines of code

% Setup
addpath('/u01/rapps/argo_dm/calibration');
reload=1;
if nargin < 3, cycle_num = []; end
if nargin<4, title_string = ''; end

% Figure out the data directory
data_dir = ['/u01/rapps/argo_dm/calibration/data/' float_num(1:4) '000/'];

% Load the profile data, get the profile index
if reload==1
    temp_files = [dir([data_dir 'D' float_num '*.nc']); dir([data_dir 'R' float_num '*.nc'])];
    t=read_all_nc(data_dir,temp_files,[],[0,0],0); 
    [foo, ii] = sort([t.cycle_number]);
    t = t(ii);
    temp_files = [dir([data_dir 'BD' float_num '*.nc']); dir([data_dir 'BR' float_num '*.nc'])];
    if ~isempty(temp_files)
        b_files=1;
        t_b=read_all_nc(data_dir,temp_files,[],[0,0],1); 
        [foo, ii] = sort([t_b.cycle_number]);
        t_b = t_b(ii);
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
    [crn,foo]=get_crnumber(stat);
    if size(unique(crn,'rows'),1) > 1
        [tokeep,foo]=get_nonCanArgoTESACindicesOcproc(stat);
        prf=prf(tokeep,:);
    end
    % Skip the current float
    tokeep = [];
    for ii=1:length(prf)
        if isempty(strfind(prf(ii).FXD.CR_NUMBER, ['Q' float_num]))
            tokeep = [tokeep; ii];
        end
    end
    prf = prf(tokeep,:);
    o=alignocprocprof(prf); 
    if isfield(o,'pres')
        z=o.pres;
        ok=isnan(o.pres);
        z(ok)=o.deph(ok); 
    elseif isfield(o,'deph')
        z=[];
    end
end
    
% Plots: comparison with historical
subplot(1,2,1); 
foo2 = plot(TEMP,PRES,'b');  
hold on;
if ~isempty(z) && isfield(o,'temp')
    foo1 = plot(o.temp,z,'c');
else foo1=[]
end
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
foo2 = plot(PSAL,PRES,'b'); 
hold on;
if isfield(o,'psal')
    foo1 = plot(o.psal,z,'c');
end
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
    hold on;
    foo2=plot(t(ii_prof-1).temp,t(ii_prof-1).pres,'c',t(ii_prof+1).temp,t(ii_prof+1).pres,'c',t(ii_prof).temp,t(ii_prof).pres,'r'); set(foo2,'linewidth',2);
    xlabel('TEMP (^{\circ}C)'); ylabel('PRES (dBar)');
    grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
    legend([foo1(1),foo2(1),foo2(3)],['Float ' float_num], ['Profiles ' num2str(cycle_num-1) ',' num2str(cycle_num+1)], ['Profile ' num2str(cycle_num)], 'location','SouthEast');
    subplot(1,3,2);
    foo1=plot(TEMP_DOXY,PRES,'b');
    hold on;
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