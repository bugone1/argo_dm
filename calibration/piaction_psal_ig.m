function [CellK,slope,offset,start,ende,psalflag,adjpsalflag]=piaction_psal_ig(PROFILE_NO,condslope,oldcoeff)
% PIACTION_PSAL Select a salinity adjustment based on OW output (Isabelle's
%   fork)
%   USAGE: 
%       [CellK,slope,offset,start,ende,psalflag,adjpsalflag]=piaction_psal(PROFILE_NO,condslope,oldcoeff)
%   INPUTS:
%       PROFILE_NO - List of profile numbers
%       consdslope - pcond_factor from the OW code
%       oldcoeff - Old conversion coefficient
%   OUTPUTS:
%       Still in the process of documenting these...
%   VERSION HISTORY:
%       3 Aug. 2017, Isabelle Gaboury: Written, based on piaction_psal.m
%           dated 25 July 2017

% Initialize flags
psalflag=ones(size(PROFILE_NO))*'1';
adjpsalflag=ones(size(PROFILE_NO))*'0';

% Give the user the option to set all conversion factors and flags to 1
q=input('Press q to skip GUI-based salinity adjustment and accept adjustment=1, or any other key to continue','s');

% Interactively select a salinity adjustment
if isempty(q) || q~='q'
    
    close all;
    
    % Check that the slope is between 0.85 and 1.15
    condslope(isnan(condslope(:)) | condslope(:)>1.15 | condslope(:)<.85)=nan;
   
    decision=char(PROFILE_NO(:)*0+32);
    CellK=condslope;
    nok=isnan(condslope);
    decision(nok)='N';
    profdecided=PROFILE_NO(decision~=32);
    v = PiAction_ig(PROFILE_NO,condslope,oldcoeff);
    sprintf('Fit is from %i to %i with maximum error of %f',[min([v.start]) max([v.end]) max([v.err])])
    if min([v.prof])>min(PROFILE_NO) || max([v.prof])<max(PROFILE_NO), yn='n';
    else
        yn=input('Accept without modification (Y/[N])?','s');
    end
    prof_all=[v.prof];
    if lower(yn)=='y'
        [tr,i]=intersect(PROFILE_NO,prof_all);
        decision(i)='F';
    else
        while lower(yn)=='n'
            [acc,i]=askquestion('Enter range of profiles which should accept climatology (start:end, -1 for all, 0 for all not yet selected, empty for none)',PROFILE_NO,profdecided);
            if ~isempty(i)
                decision(i(1):i(end))='C';
                profdecided=PROFILE_NO(decision~=32);
            end
            [nnot,i]=askquestion('Enter range of profiles which should use r=1 (start:end, -1 for all, 0 for all not yet selected, empty for none)',PROFILE_NO,profdecided);
            if ~isempty(i)
                decision(i(1):i(end))='N';
                profdecided=PROFILE_NO(decision~=32);
            end
            [nnot,i]=askquestion('Enter range of profiles which should keep last adjustment (-1 for all, 0 for all not yet selected, empty for none)',PROFILE_NO,profdecided);
            if ~isempty(i)
                oknan=find(isnan(oldcoeff((1):i(end))));
                if ~isempty(oknan)
                    i=oknan(end)+1:i(end);
                end
                decision(i(1):i(end))='K';
                profdecided=PROFILE_NO(decision~=32);
            end
            % Are there any profiles still needing to be decided?
            if min([v.prof])==min(PROFILE_NO) && max([v.prof])==max(PROFILE_NO)
                yn='Y';
            else
                sprintf('Undecided profiles remain');
            end
        end
    end
    for j=1:length(v) %rearrange slope information in rows / columns
        [tr,oki,okb]=intersect(PROFILE_NO,v(j).prof);
        CellK(oki)=v(j).condcalc(okb);    slope(oki)=v(j).slope;    offset(oki)=v(j).offset;    start(oki)=v(j).start;    ende(oki)=v(j).end;
    end
    ok=decision=='K';CellK(ok)=oldcoeff(ok); [slope(ok),offset(ok),start(ok),ende(ok)]=deal(NaN);
    ok=decision=='C';CellK(ok)=condslope(ok);[slope(ok),offset(ok),start(ok),ende(ok)]=deal(NaN);
    ok=decision=='N';CellK(ok)=1;[slope(ok),offset(ok),start(ok),ende(ok)]=deal(NaN);
else
    CellK=ones(size(condslope));
    ba=input('Enter cycle from which the float should have its salinity flagged to 4 (0 if none)');
    if ~isempty(ba) && ba>0
        CellK(PROFILE_NO>=ba)=nan;
    end
    [slope,offset,start,ende]=deal(nan);
end
set(findobj('color','g','linestyle','-'),'xdata',PROFILE_NO,'ydata',CellK);
ok=CellK>1;
if any(ok)
    [find(ok)' CellK(ok)']
    yn=input('Do you want to crop all >1 values to 1 ?','s');
    if strcmpi(yn,'y')
        CellK(ok)=1;
    end
end
ok=CellK<1;
if any(ok)
    [find(ok)' CellK(ok)']
    yn=input('Do you want to crop all <1 values to 1 ?','s');
    if strcmpi(yn,'y')
        CellK(ok)=1;
    end
end
ok=CellK~=1;
if any(ok)
    [find(ok)' CellK(ok)']
    newv=input('Round to a number of decimal places ? (empty=no, anything else = number of decimal places)');
    if ~isempty(newv)
        CellK = round(CellK*10^newv)/10^newv;
    end
end
if (~isempty(q) && q=='q') || any(abs(1-CellK)>.0005)
    newv=input('Enter manual factor ? (empty=no, anything else = factor)');
    if ~isempty(newv)
        rang=input('From which cycle onward?');
        if ~isempty(rang)
            CellK(PROFILE_NO>=rang)=newv;
        end
        yn=lower(input('Rest set to 1 ?','s'));
        if (yn=='y' || yn=='1')
            CellK(PROFILE_NO<rang)=1;
        end
    end
end
CellK=round(CellK*1e8)/1e8;
psalflag(isnan(CellK))='4';
ba=input('Enter cycle from which the float should have its raw salinity flagged to 2 (0 if none)');
if ~isempty(ba) && ba>0
    psalflag(PROFILE_NO>=ba & psalflag<'2')='2';
end
psalflag=char(psalflag);
ba=input('Enter cycle from which the float should have its raw salinity flagged to 3 (0 if none)');
if ~isempty(ba) && ba>0
    psalflag(PROFILE_NO>=ba & psalflag<'3')='3';
end
psalflag=char(psalflag);
%adjpsalflag=psalflag;
ba=input('Enter cycle from which the float should have its ADJ salinity flagged to 1 (0 if none)');
if ~isempty(ba) && ba>0
    adjpsalflag(PROFILE_NO>=ba & adjpsalflag<'1')='1';
end
ba=input('Enter cycle from which the float should have its ADJ salinity flagged to 2 (0 if none)');
if ~isempty(ba) && ba>0
    adjpsalflag(PROFILE_NO>=ba & adjpsalflag<'2')='2';
end
ba=input('Enter cycle from which the float should have its ADJ salinity flagged to 3 (0 if none)');
if ~isempty(ba) && ba>0
    adjpsalflag(PROFILE_NO>=ba & adjpsalflag<'3')='3';
end
ba=input('Enter cycle from which the float should have its ADJ salinity flagged to 4 (0 if none)');
if ~isempty(ba) && ba>0
    adjpsalflag(PROFILE_NO>=ba & adjpsalflag<'4')='4';
end
adjpsalflag=char(adjpsalflag);

end

