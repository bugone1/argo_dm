%function processcycle
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

rms=meannan((ocondslope-CellK).^2);
if all(decision=='N')
    ogencomment='No salinity adjustment was judged needed after visual inspection of DMQC software diagnostic.';
elseif all(decision=='C')
    ogencomment='DMQC diagnostic software suggestion was accepted as such.';
elseif rms~=0
    ogencomment=['Visual piecewise linear fit done upon inspection of profiles ' num2str(PROFILE_NO(1)) ' to ' num2str(PROFILE_NO(end)) '. ' num2str(length(v)) ' breakpoints. RMS error between conductivity correction determined by DMQC software and linear interpolation is : ' num2str(rms) '.'];
end

condslope(isnan(condslope))=99999;
if ~all(decision=='K') %Do not write new files if old coeff was kept
    for i=length(PROFILE_NO):-1:1
%        if strmatch(flnmp,'4900234') %John Gilson, nov2009
%            CellK(66)=1.062692;
%            CellK(67:end)=1.065272;
%        end     
        flnmp=[floatNum '_' num2str(PROFILE_NO(i),'%03d') '.nc'];
        lastnan=find(diff(isnan(PRES(:,i)))~=0);
        if ~isempty(lastnan)
            x=1:lastnan(end);
        else
            x=1:size(PRES,1);
        end
        output_flnm=['R' flnmp];
        ingested_flnm=dir([local_config.INGESTED '*' flnmp]);
        ingested_flnm=ingested_flnm(1);
        input_flnm=[local_config.INGESTED ingested_flnm.name];
        if all(isnan(PRES(x,i)))
            copyfile(input_flnm,[local_config.OUT 'error\' output_flnm]);
        else
            if decision(i)=='C'
                if min_err(i)>max(40*abs(CellK(i)-1)/2)
                    min_err(i)=min_err(i)-.004;
                end
                result=rewrite_nc(input_flnm,[local_config.OUT 'changed\' output_flnm],PRES(x,i),TEMP(x,i),cal_SAL(x,i),cal_SAL_FLAG(x,i),cal_SAL_err(x,i),condslope(i),condslope_err(i),CalDate,min_err(i),'A',ogencomment,condslope(i));
            elseif decision(i)=='N' %&&  oldcoeff(i)~=1
                min_err(i)=max(40*abs(CellK(i)-1)/2)+.004;
                result=rewrite_nc(input_flnm,[local_config.OUT 'unchanged\' output_flnm],PRES(x,i),TEMP(x,i),cal_SAL(x,i),cal_SAL_FLAG(x,i),cal_SAL_err(x,i),1,condslope_err(i),CalDate,min_err(i),'A',ogencomment,condslope(i));
            elseif decision(i)=='F'
                if min_err(i)>max(40*abs(CellK(i)-1)/2)
                    min_err(i)=min_err(i)-.004;
                end
                %find the slope which was decided for the current cycle                
                cal_SAL(:,i)=sw_salt(cal_COND(:,i).*CellK(i)/sw_c3515/condslope(i),PTMP(:,i),0*SAL(:,i));
                gencomment=[ogencomment sprintf('Linear fit to error for this cycle: [start,end,offset,slope]=[%i %i %6.4f %g]',[start(i) ende(i) offset(i) slope(i)])];
                if all(cal_SAL_FLAG(:,i)==4) %if the profile was rejected for being too short, assign QC=3 (adjustment applied but may still be bad)
                    saldat=isnan(SAL(:,i)); cal_SAL_FLAG(saldat,i)='3';
                end
                result=rewrite_nc(input_flnm,[local_config.OUT 'changed\' output_flnm],PRES(x,i),TEMP(x,i),cal_SAL(x,i),cal_SAL_FLAG(x,i),cal_SAL_err(x,i),CellK(i),condslope_err(i),CalDate,min_err(i),'A',ogencomment,condslope(i));
            elseif decision(i)=='K'
                if min_err(i)>max(40*abs(CellK(i)-1)/2)
                    min_err(i)=min_err(i)-.004;
                end
                cal_SAL(:,i)=sw_salt(cal_COND(:,i).*CellK(i)/condslope(i)/sw_c3515,PTMP(:,i),0*SAL(:,i));
                gencomment=[ogencomment sprintf('The salinity in this cycle was adjusted with previously determined conductivity coefficient; other cycles by the same float obtained new correction coefficients during the same analysis.')];
                result=rewrite_nc(input_flnm,[local_config.OUT 'changed\' output_flnm],PRES(x,i),TEMP(x,i),cal_SAL(x,i),cal_SAL_FLAG(x,i),cal_SAL_err(x,i),CellK(i),condslope_err(i),CalDate,min_err(i),'A',ogencomment,condslope(i));
            end
        end
    end
end
save([lo_system_configuration.FLOAT_CALIB_DIRECTORY local_config.PI 'calseries_' floatNum '.mat'], 'calib_profile_no', 'running_const', 'cal_series_flags','CellK','min_err','comment');