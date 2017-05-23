%function processcycle1
%called by viewplotsnew.m
clear v
iter=0;decision=char(PROFILE_NO(:)*0+32);
ok=1:length(PROFILE_NO);
condslope(condslope==99999)=nan;
nok=isnan(condslope);
decision(nok)='N';
profdecided=PROFILE_NO(find(decision~=32));
ok=ok(~nok);
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
            oknan=find(isnan(oldcoeff(i(1):i(end))));
            if ~isempty(oknan)
                i=oknan(end)+1:i(end);
            end
            decision(i(1):i(end))='K';
            profdecided=PROFILE_NO(find(decision~=32));
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
ok=decision=='C';CellK(ok)=condslope(ok); [slope(ok),offset(ok),start(ok),ende(ok)]=deal(NaN);
ok=decision=='N';CellK(ok)=1; [slope(ok),offset(ok),start(ok),ende(ok)]=deal(NaN);

processcycle2;