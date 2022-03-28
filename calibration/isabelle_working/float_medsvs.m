function float_medsvs(float_num,medsvs_file,cycle_num, title_string, show_bad_points, float_from_mat)
% FLOAT_MEDSVS Compare float data to historical data from medsvs
%   DESCRIPTION: Compare float profile to other profiles for this float and
%       for neighbouring floats. This assumes we've already made a request
%       on MEDS and fetched the file using Mathieu's getLatestMedsAsciiFile
%       or by FTP
%   INPUTS:
%       float_num - float number, as a string
%       medsvs_file - MEDSVS file name. This can be either the name of
%           either the raw .DAT file from MEDSV or the .MAT file created by
%           getLatestMedsAsciiFile
%   OPTIONAL INPUTS:
%       cycle_num - Cycle number to highlight in the plots
%       title_string - Title for the plots
%       show_bad_points - Set to 1 to show points that failed QC (default is to
%           hide these)
%       float_from_mat - Set to 1 to load from the MAT file rather than the
%           NetCDF files
%   VERSION HISTORY:
%       Created 11 Sep. 2017, Isabelle Gaboury
%       IG, 10 Oct. 2017 - Improved handling of data directory and mixes of
%           R and D files; removed some leftover lines of code
%       IG, 21 Dec. 2017 - Added show_bad_points flag
%       IG, 12 Jul. 2018 - Added option to calculate pressure from depth, 
%           fixed bug with loading of temp_doxy

if nargin<6, float_from_mat=0; end

% Setup
addpath('/u01/rapps/argo_dm/calibration');
addpath('/u01/rapps/vms_tools');
addpath('/u01/rapps/seawater');
if nargin < 3, cycle_num = []; end
if nargin<4, title_string = ''; end
if nargin<5, show_bad_points=0; end
ITS90toIPTS68=1.00024;

% Figure out the data directory
%data_dir = ['/u01/rapps/argo_dm/calibration/data/' float_num(1:4) '000/'];
data_dir = ['/u01/rapps/argo_dm/calibration/data/' float_num filesep];
data_dir_mat = '/u01/rapps/argo_dm/data/temppresraw/';

% Load the profile data, get the profile index
if float_from_mat==1
    load([data_dir_mat float_num],'t');
    if isfield(t,'temp_doxy')
        b_files=1;
        clear t_b
        for ii=1:length(t)
            t_b(ii) = struct('cycle_number',t(ii).cycle_number,'pres',t(ii).pres,'temp_doxy', ...
                t(ii).temp_doxy,'temp_doxy_qc',t(ii).temp_doxy_qc);
        end
    else
        t_b=[];
        b_files=0;
    end
else
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
[PRES,PSAL,TEMP,TEMP_DOXY,PTEMP]=deal(nan(max(si),lt)); %preallocate profile with max depths
for i=1:lt
    if show_bad_points==1, ok=1:length(t(i).pres);
    else ok = find(t(i).pres_qc<='2');
    end
    PRES(ok,i)=t(i).pres(ok);
    if show_bad_points==0, ok = find(t(i).psal_qc<='2'); end
    PSAL(ok,i)=t(i).psal(ok);
    if show_bad_points==0, ok = find(t(i).temp_qc<='2'); end
    TEMP(ok,i)=t(i).temp(ok);
    if b_files==1
        if show_bad_points==0, ok = find(t_b(i).temp_doxy_qc<='2'); end
        TEMP_DOXY(ok,i)=t_b(i).temp_doxy(ok); 
    end
end

% Load and pre-process the medsvs results
if ~isempty(medsvs_file)
    if isempty(findstr(lower(medsvs_file),'.mat')) && ~isempty(findstr(lower(medsvs_file),'.dat'))
        [stat,prf]=read_medsascii2ocproc(medsvs_file);
    end
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
    lat = zeros(1,length(tokeep))*NaN;
    for ii=1:length(tokeep)
        lat(ii)=stat(tokeep(ii)).FXD.LATITUDE;
    end
        
    o=alignocprocprof(prf);
    % TODO: Eventually use gsw to compute pressure from depth
    if isfield(o,'pres')
        z = o.pres;
        ok = isnan(o.pres);
        if ~isempty(ok) && isfield(o,'deph'), z(ok)=o.deph(ok); end
    else
        % Get the latitudes
        z=-1*gsw_p_from_z(o.deph,lat);
    end
elseif isempty(medsvs_file)
    o=struct();
    z=[];
end

% Hide MEDSVS points that failed QC
if ~isempty(medsvs_file)
    if show_bad_points==0
        if isfield(o,'deph')
            z(o.deph_qc>='2')=NaN;
        elseif isfield(o,'pres')
            z(o.pres_qc>='2')=NaN;
        end
    end
    if isfield(o,'temp')
        o_temp=o.temp;
        if show_bad_points==0, o_temp(o.temp_qc>='2')=NaN; end
    end
    if isfield(o,'psal')
        o_psal=o.psal;
        if show_bad_points==0, o_psal(o.psal_qc>='2')=NaN; end
    end
end  

% Potential temperatures, for the TS plot
PTMP = sw_ptmp(PSAL,TEMP*ITS90toIPTS68,PRES,0);
o_ptmp = sw_ptmp(o_psal,o_temp*ITS90toIPTS68,z,0);
    
% Plots: comparison with historical
subplot(1,2,1); 
foo2 = plot(TEMP,PRES,'c');  
hold on;
if ~isempty(z) && isfield(o,'temp')
    foo1 = plot(o_temp,z,'b');
else foo1=[];
end
foo3=[];
for ii=1:length(ii_prof)   
    foo3(ii)=plot(TEMP(:,ii_prof(ii)),PRES(:,ii_prof(ii)),'r'); 
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
foo=leg_h>0;
legend(leg_h(foo), leg_txt(foo), 'location','SouthEast');
title(title_string)
subplot(1,2,2); 
foo2 = plot(PSAL,PRES,'c'); 
hold on;
if isfield(o,'psal')
    foo1 = plot(o_psal,z,'b');
end
foo3 = [];
for ii=1:length(ii_prof)
    foo3(ii)=plot(PSAL(:,ii_prof(ii)),PRES(:,ii_prof(ii)),'r'); 
end
set(foo3,'linewidth',2); 
xlabel('Salinity (psu)'); ylabel('Pressure (dBar)'); grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
foo=leg_h>0;
legend(leg_h(foo), leg_txt(foo), 'location','SouthEast');
title(title_string)

% TS plot
figure
foo2 = plot(PSAL,PTMP,'c');  
hold on;
if isfield(o,'temp') && isfield(o,'psal')
    foo1 = plot(o_psal,o_ptmp,'b');
else foo1=[]
end
foo3=[];
for ii=1:length(ii_prof)   
    foo3(ii)=plot(PSAL(:,ii_prof(ii)),PTMP(:,ii_prof(ii)),'r'); 
end
set(foo3,'linewidth',2);
xlabel('Salinity (psu)'); ylabel('Potential temperature (^{\circ}C)'); grid on;  
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
foo=leg_h>0;
legend(leg_h(foo), leg_txt(foo), 'location','SouthEast');
title(title_string)

% Plots: temp vs. temp_doxy
if b_files==1
    figure
    subplot(1,3,1); 
    foo1=plot(TEMP,PRES,'b');
    hold on;
    foo2=plot(t(ii_prof-1).temp,t(ii_prof-1).pres,'c');
    hold on; 
    if ii_prof<length(t)
        foo2(end+1)=plot(t(ii_prof+1).temp,t(ii_prof+1).pres,'c');
    end
    foo2(end+1)=plot(t(ii_prof).temp,t(ii_prof).pres,'r'); set(foo2,'linewidth',2);
    xlabel('TEMP (^{\circ}C)'); ylabel('PRES (dBar)');
    grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
    legend([foo1(1),foo2(1),foo2(end)],['Float ' float_num], ['Profiles ' num2str(cycle_num-1) ',' num2str(cycle_num+1)], ['Profile ' num2str(cycle_num)], 'location','SouthEast');
    subplot(1,3,2);
    foo1=plot(TEMP_DOXY,PRES,'b');
    hold on;
    foo2=plot(t_b(ii_prof-1).temp_doxy,t_b(ii_prof-1).pres,'c');
    hold on;
    if ii_prof<length(t)
        foo2(end+1)=plot(t_b(ii_prof+1).temp_doxy,t_b(ii_prof+1).pres,'c');
    end
    foo2(end+1)=plot(t_b(ii_prof).temp_doxy,t_b(ii_prof).pres,'r'); set(foo2,'linewidth',2);
    xlabel('TEMP\_DOXY (^{\circ}C)'); ylabel('PRES (dBar)');
    grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
    legend([foo1(1),foo2(1),foo2(end)],['Float ' float_num], ['Profiles ' num2str(cycle_num-1) ',' num2str(cycle_num+1)], ['Profile ' num2str(cycle_num)], 'location','SouthEast');
    title(title_string)
    subplot(1,3,3);
    plot(TEMP_DOXY-TEMP,PRES,'b'); 
    hold on; foo = plot(TEMP_DOXY(:,ii_prof)-TEMP(:,ii_prof),PRES(:,ii_prof),'r'); set(foo,'linewidth',2);
    grid on; set(gca,'ydir','rev','ylim',[0 2010]); 
    xlabel('TEMP\_DOXY-TEMP (^{\circ}C)'); ylabel('Pressure (dBar)');
end
 % end