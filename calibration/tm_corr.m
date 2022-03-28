function psal_corr=tm_corr(local_config,floatname,alpha,tau)

ITS90toIPTS68=1.00024;
if nargin<3, alpha=0.141; end
if nargin<4, tau=6.68; end
% alpha=0.141;
% tau=1;

% Load the float and trajectory data
dire=fullfile(local_config.DATA,floatname);
files=[dir([dire filesep 'D*.nc']) dir([dire filesep 'R*.nc'])];
dir_traj = [local_config.DATA 'trajfiles'];
t=read_all_nc(dire,files,[]);
t_traj=read_traj_nc([dir_traj filesep floatname '_Rtraj.nc']);

% Get the unique cycle numbers from the trajectory file and the ascent
% times. Deal with any missing ascent times (e.g., start and end times are
% 999999)
% TODO: This is still under development
total_ascent_times = (t_traj.juld_ascent_end-t_traj.juld_ascent_start)*24*60*60;
for ii=find(total_ascent_times==0)
    if ii==1 && total_ascent_times(2)>0
        total_ascent_times(1)=total_ascent_times(2);
    elseif ii==length(total_ascent_times) && total_ascent_times(end-1)>0
        total_ascent_times(end)=total_ascent_times(end-1);
    elseif ii>1 && ii<length(total_ascent_times) && total_ascent_times(ii-1)>0 && total_ascent_times(ii+1)>0
        total_ascent_times(ii) = (total_ascent_times(ii-1)+total_ascent_times(ii+1))/2;
    else
        warning('Probably need to work on the ascent-time-averaging code some more');
        total_ascent_times(ii) = mean(total_ascent_times(total_ascent_times>0));
    end
end

% The ascent start and end times are the same length as the number of
% profiles, but there can be a -1 cycle
if length(total_ascent_times)>length(t)
    if t_traj.cycle_number(1)==-1
        total_ascent_times = total_ascent_times(2:end);
    else
        error('Not sure what to do with cycle numbers...');
    end
end
    

psal_corr={};
for ii=1:length(t)
    total_pres_change = t(ii).pres(end)-t(ii).pres(1);
    ave_ascent_rate = total_pres_change/total_ascent_times(ii);
    e_time = (t(ii).pres(end)-t(ii).pres)/ave_ascent_rate;
    psal_corr{ii}=celltm_sbe41(t(ii).psal,t(ii).temp*ITS90toIPTS68,t(ii).pres,e_time,alpha,tau);
end

end