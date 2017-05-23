%function genreport
%Generates html file showing content from "notes.txt" along with diagnostic plots
%Notes.txt must be organized this way:
%line1 = Float number
%line2 = Date of DMQC
%line3 = lprof
%line4 = comment
%line5 = Gilson comment
%line6 = wjo comment

fclose all
clear
imgpath='C:\z\argo_DM\data\float_plots\wjo\';
fid=fopen('notes.txt','r');
i=0;
while ~feof(fid)
    lin=[];
    while isempty(deblankde(lin)) & ~feof(fid)
        lin=fgetl(fid);
    end    
    i=i+1;
    if length(lin)>0
        if lin(1)~=-1
            s(i).float=deblank(lin);
            s(i).date=deblank(fgetl(fid));
            s(i).lprof=deblank(fgetl(fid));
            s(i).comm=deblank(fgetl(fid));
            s(i).gilson=deblank(fgetl(fid));
            s(i).wjo=deblank(fgetl(fid));
        end
    end
end
fclose(fid)

fid=fopen('notes.htm','w')
for i=1:length(s)
    fwrite(fid,['<h1>' s(i).float '</h1>' 13 10]);
    fwrite(fid,[s(i).date '<br> ' 13 10]);
    fwrite(fid,['<i>' s(i).lprof '</i><br>' 13 10]);
    fwrite(fid,[s(i).comm '<br>' 13 10]);
    fwrite(fid,[s(i).gilson '<br>' 13 10]);
    fwrite(fid,[s(i).wjo '<br>' 13 10]);
    fwrite(fid,['<a href="' imgpath s(i).float '_4.png"><img src=' imgpath s(i).float 'tb_4.png width=300></a>' 13 10]);
    fwrite(fid,['<a href="' imgpath s(i).float '_6.png"><img src=' imgpath s(i).float 'tb_6.png width=300></a><br>' 13 10]);
    fwrite(fid,['<a href="' imgpath s(i).float '_1.png"><img src=' imgpath s(i).float 'tb_1.png width=300></a>' 13 10]);
    fwrite(fid,['<a href="' imgpath s(i).float '_9.png"><img src=' imgpath s(i).float 'tb_9.png width=300></a>' 13 10]);
end
fclose(fid)
!notes.htm