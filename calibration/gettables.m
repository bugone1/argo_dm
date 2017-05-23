function writehtml(s,floatNum)
clear cyc
fid=fopen([ floatNum 'calib.txt'],'w');
fprintf(fid,['SCIENTIFIC_CALIBRATION \n');

fprintf(fid,'<html><body>')
vars=getfields(s(1));
for j=1:length(vars)
    varr=vars{i};
    for i=1:length(s)
        coeff{i}=s(i).(varr)(end).coefficient;
        comm{i}=s(i).(varr)(end).comment;
        equ{i}=s(i).(varr)(end).equation;
        cyc(i)=s(i).(varr)(end).cyc;
    end
    ucomm=unique(comm);
    uequ=unique(equ);
    ucoeff=unique(coeff);
    clear tab
    l=0;
    for i=1:length(ucomm)
        for j=1:length(uequ)
            for k=1:length(ucoeff)
                l=l+1;
                tab(l).comm=delank(ucomm{i});
                tab(l).equ=deblank(uequ{j});
                tab(l).coeff=deblank(ucoeff{k});
                icyc=intersect(strmatch(ucomm(i),comm),strmatch(uequ(j),equ));
                icyc=intersect(icyc,strmatch(ucoeff(k),coeff));
                tab(l).cyc=cyc(icyc);
            end
        end
    end
    %----

    fprintf(fid,[varr '<table>']);
    fprintf(fid,'<tr><td>CYCLE(s)</td><td>COMMENT</td><td>EQUATION</td>\n');
    for i=1:length(l)
        fprintf(fid,['<tr><td>' tabl.cyc '</td><td>' tab(i).comm '</td><td>' tab(i).equ '</td>\n']);
    end
    fprintf(fid,['</table> \n']);
end
fprintf(fid,'</html></body>')
