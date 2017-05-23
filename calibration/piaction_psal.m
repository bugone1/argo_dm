function [CellK,slope,offset,start,ende,psalflag,adjpsalflag]=piaction_psal(PROFILE_NO,condslope,oldcoeff)
psalflag=ones(size(PROFILE_NO))*'1';
adjpsalflag=ones(size(PROFILE_NO))*'0';
q=input('Press q if you don''t want to adjust salinity with GUI','s');
if isempty(q) || q~='q'
    condslope(isnan(condslope(:)) | condslope(:)>1.15 | condslope(:)<.85)=nan;
    close all;
    iter=0;decision=char(PROFILE_NO(:)*0+32);
    CellK=condslope;
    ok=1:length(PROFILE_NO);
    nok=isnan(condslope);
    decision(nok)='N';
    profdecided=PROFILE_NO(decision~=32);
    %    ok=unique([ok(~nok) length(PROFILE_NO)]);
    ok=1:length(PROFILE_NO);
    endpoint=[nan nan];
    while length(profdecided)<length(PROFILE_NO)
        iter=iter+1;
        v(iter)=PiAction(PROFILE_NO(ok),condslope(ok),endpoint,oldcoeff(ok));
        endpoint=[v(end).start v(end).condcalc(ok(1))];
        sprintf('Fit is from %i to %i with error of %f',[v(iter).start v(iter).end v(iter).err])
        yn=input('Accept (Y/[N])?','s');
        ok=1:v(iter).ok(1)-1;
        if lower(yn)=='y'
            [tr,i]=intersect(PROFILE_NO,v(iter).prof);
            decision(i)='F';
            profdecided=PROFILE_NO(find(decision~=32));
        else
            [acc,i]=askquestion('Enter range of profiles which should accept climatology (-1 for all, 0 for all not yet selected, empty for none)',PROFILE_NO,profdecided);
            if ~isempty(i)
                decision(i(1):i(end))='C';
                profdecided=PROFILE_NO(find(decision~=32));
                endpoint=[PROFILE_NO(ok(1)) condslope(ok(1))];
                ok=ok(1:i(1)-1);
            end
            [nnot,i]=askquestion('Enter range of profiles which should NOT accept climatology (-1 for all, 0 for all not yet selected, empty for none)',PROFILE_NO,profdecided);
            if ~isempty(i)
                decision(i(1):i(end))='N';
                profdecided=PROFILE_NO(find(decision~=32));
                endpoint=[nan nan];
                ok=ok(1:i(1)-1);
            end
            [nnot,i]=askquestion('Enter range of profiles which should keep last adjustment (-1 for all, 0 for all not yet selected, empty for none)',PROFILE_NO,profdecided);
            if ~isempty(i)
                oknan=find(isnan(oldcoeff((1):i(end))));
                if ~isempty(oknan)
                    i=oknan(end)+1:i(end);
                end
                decision(i(1):i(end))='K';
                profdecided=PROFILE_NO(decision~=32);
                if ~isempty(ok)
                    endpoint=[PROFILE_NO(ok(1)) condslope(ok(1))];
                    ok=ok(1:i(1)-1);
                end
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
