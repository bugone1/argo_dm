function pres=presDespikargo(pres,thre,recursive)
% PRESDESPIKEARGO Despike Argo pressure data
%   USAGE: pres=presDespikargo(pres,thre,recursive)
%   INPUTS:
%       pre - pressure time series, with offset and scaling already applied
%       thre - threshold; any pressure differences larger than this are
%           considered a spike
%       recursive - maximum number of times to iterate through the
%           despiking process
%   OUTPUTS:
%       pre - despiked pressure time series
%   VERSION HISTORY:
%       May 2017: Current working version
%       24 Nov. 2017, Isabelle Gaboury: Added documentation

%opres=pres;
lp=length(pres);

% Find the spikes, defined as a difference in pressures greater than or
% equal to the threshold.
% TODO: I think it might be necessary to add 1 to j here and below; check
% this on later runs.
spiks=[abs(diff(pres))>=thre; 0];
j=find((spiks | spiks([2:end end])));
iter=0;
if ~isempty(j)
    while ~isempty(j) && iter<recursive
        iter=iter+1;
        for i=1:length(j)
            if i>1 && i<lp && ~any(j==j(i-1)) && ~any(j==j(i+1))
                pres(j(i))=mean(pres(j(i)+[-1 1]));
            elseif j(i)>1 && ~any(j==j(i)-1)
                pres(j(i))=mean(pres(j(i)-1));
            elseif j(i)<lp && ~any(j==j(i)+1)
                pres(j(i))=mean(pres(j(i)+1));
            end
        end
        if recursive>0
            spiks=[abs(diff(pres))>=thre; 0];
            j=find((spiks | spiks([2:end end]))); % & abs(pres)>=thre);            
        else
            j=[];
        end
    end
    if iter==recursive
        'max iterations reached'
        pause
    end
end