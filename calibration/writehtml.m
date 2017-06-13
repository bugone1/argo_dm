
function writehtml(s,floatNum,pathe)
clear cyc
fid=fopen([pathe floatNum 'calib.htm'],'w');
fprintf(fid,'<html><body>')

fprintf(fid,['<a1><center>' floatNum '</center><br></a1>']);
fprintf(fid,['<center>' datestr(now) '</center><br>']);
fprintf(fid,'------<br>');
fprintf(fid,'Diagnostic:<br>');
fprintf(fid,'<a href="#diagP">Pressure Diagnosis Plots<br>');
fprintf(fid,'<a href="#diagS">Salinity Diagnosis Plots (WJO)</a><br>');
fprintf(fid,'<a href="#condc">Conductivity Correction Applied</a><br>');
fprintf(fid,'Results:<br>');
fprintf(fid,'<a href="#TS">TS Plots raw/adjusted</a><br>');
fprintf(fid,'<a href="#TEMP">TEMP raw/adjusted</a><br>');
fprintf(fid,'<a href="#PSAL">PSAL raw/adjusted</a><br>');
fprintf(fid,'------<br>');

fprintf(fid,'<a name="diagP">Pressure Diagnosis Plots</a><br>');
%fprintf(fid,linimg(['pres_bath_' floatNum '.png']));
fprintf(fid,linimg([floatNum '_PRES_ADJ-RAW.png']));
fprintf(fid,[linimg(['pres_' floatNum '.png']) '<br>']);

fprintf(fid,['<a name="diagS">Salinity Diagnosis Plots (WJO)</a><br>']);
% The OW routines produce 8 plots; if using WJO change this to 9.
for i=1:8
    fprintf(fid,linimg([floatNum '_' num2str(i) '.png']));
end
fprintf(fid,'<a name="TS"><br>TS raw & adjust</a><br>');
fprintf(fid,linimg([floatNum '_ts_a.png']));
fprintf(fid,[linimg([floatNum '_ts_r.png']) '<br>']);
fprintf(fid,'<a name="condc">Conductivity Correction Applied</a><br>');
fprintf(fid,linimg([floatNum '_PSAL_conductivity_adjustment.png']));
fprintf(fid,'<br>');

fprintf(fid,'<a name="err"><br>TEMP_ADJUSTED_ERROR</a><br>');
fprintf(fid,linimg([floatNum '_TEMP_err.png']));
fprintf(fid,'<a name="err"><br>PSAL_ADJUSTED_ERROR</a><br>');
fprintf(fid,[linimg([floatNum '_PSAL_err.png']) '<br>']);
fprintf(fid,'<br>');


vars=fieldnames(s(1)); vars=vars(1:3); %remove doxy
for j=1:length(vars)
    varr=vars{j};
    for i=1:length(s)
        coeff{i}=s(i).(varr)(end).coefficient';
        comm{i}=s(i).(varr)(end).comment';
        equ{i}=s(i).(varr)(end).equation';
        cyc(i)=s(i).(varr)(end).cyc';
    end
    ucomm=unique(comm);
    uequ=unique(equ);
    ucoeff=unique(coeff);
    clear tab
    l=0;
    for i=1:length(ucomm)
        for j=1:length(uequ)
            ocyc=intersect(strmatch(ucomm(i),comm),strmatch(uequ(j),equ,'exact'));
            for k=1:length(ucoeff)
                icyc=intersect(ocyc,strmatch(ucoeff(k),coeff,'exact'));
                if ~isempty(icyc)
                    l=l+1;
                    tab(l).cyc=cyc(icyc);
                    tab(l).comm=deblank(ucomm{i});
                    tab(l).equ=deblank(uequ{j});
                    tab(l).coeff=deblank(ucoeff{k});
                end
            end
        end
    end
    %----
    fprintf(fid,['----- <br> <a name="#' varr '">']);
    if ~strcmp(varr,'PRES')
        fprintf(fid,['raw & adjust</a><br>']);

        fprintf(fid,linimg([floatNum '_' varr '_r.png']));
        fprintf(fid,[linimg([floatNum '_' varr '_a.png']) '<br>']);
        fprintf(fid,linimg([floatNum '_' varr '_r_3&4.png']));
        fprintf(fid,[linimg([floatNum '_' varr '_a_3&4.png']) '<br>']);
        fprintf(fid,linimg([floatNum '_' varr '_ADJ-RAW.png']));
    end
    fprintf(fid,[varr ' SCIENTIFIC_CALIBRATION:']);
    fprintf(fid,'<br><table border=1>');
    fprintf(fid,'<tr><td>CYCLE(s)</td><td>COMMENT</td><td>EQUATION</td><td>COEFFICIENT</td></tr>\n');
    for i=1:l
        cyc=sort(tab(i).cyc);
        fc=[];
        fc=[num2str(cyc(1)) ' '];
        for J=2:length(cyc)-1
            if (cyc(J+1)-cyc(J))~=1
                fc=[fc num2str(cyc(J)) ' '];
            else
                if (cyc(J)-cyc(J-1))~=1
                    fc=[fc num2str(cyc(J)) ':'];
                else
                    if fc(end)~=':'
                        fc=[fc ':'];
                    end
                end
            end
        end
        if ~isempty(J)
            fc=[fc num2str(cyc(end))];
        end
        fprintf(fid,['<tr><td>' fc '</td><td>' tab(i).comm '</td><td>' tab(i).equ '</td><td>' tab(i).coeff '</td></tr>\n']);
    end
    fprintf(fid,['</table> \n']);
    fprintf(fid,['-----<br>']);
end
fprintf(fid,'</html></body>')
fclose(fid)

function out=linimg(in)
out=['<a href=' in '><img src=' in ' width=500></a>'];