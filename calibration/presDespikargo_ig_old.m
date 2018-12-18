function pres=presDespikargo_ig(pres,thre,recursive)
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
%       24 Nov. 2017, IG: Experimenting with some minor fixes, still under
%           construction.
%       10 Jan. 2018, IG: It is now assumed that the very last point in the
%           pressure vector should not be used to replace a spike in the
%           before-last point (this was causing spikes to propagate
%           backward through the pressure record)

%opres=pres;
lp=length(pres);

% Find the spikes, defined as a difference in pressures greater than or
% equal to the threshold.
% Note that as of Jan. 2018, it is assumed that the last element in the
% pressure vector is an artifical value based on the before-last point, and
% so should not generally be used in averaging.
% TODO: Check that the addition of the +1 here is correct
spiks=[abs(diff(pres))>=thre; 0];
j=find((spiks | spiks([2:end end])))+1;
iter=0;
if ~isempty(j)
    ii_last_good = j(1)-1;
    if ii_last_good<0
        ii_last_good = find(~spiks,1,'first');
    end
    while ~isempty(j) && iter<recursive
        iter=iter+1;
        for i=1:length(j)
            if i>1 && i<(lp-1) && ~any(j==j(i-1)) && ~any(j==j(i+1))
                pres(j(i))=mean(pres(j(i)+[-1 1]));
                ii_last_good=j(i)+1;
            elseif j(i)>1 && ~any(j==j(i)-1)
                pres(j(i))=pres(j(i)-1);
                ii_last_good=j(i)-1;
            elseif j(i)<(lp-1) && ~any(j==j(i)+1)
                pres(j(i))=mean(pres(j(i)+1));
                ii_last_good=j(i)+1;
            elseif j(i)==(lp-1) && j(i-1)==(lp-2)
                foo = setdiff(1:lp,j);
                pres(j(i):lp) = pres(max(foo(foo<j(i))));
            else
                warning('Using last known good value');
                pres(j(i)) = pres(ii_last_good);
            end
        end
        if recursive>0
            spiks=[abs(diff(pres))>=thre; 0];
            j=find((spiks | spiks([2:end end])))+1; % & abs(pres)>=thre);        
            lj=length(j);
        else
            j=[];
        end
    end
    if iter==recursive
        'max iterations reached'
        pause
    end
end