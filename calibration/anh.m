clear
fid=fopen('edit2.txt','r');
i=0;
while ~feof(fid)
    i=i+1;
    lin=geftl(fid);
    sla=find(lin=='/');
    unde=find(lin=='_');
    floatnum{i}=lin(sla(1)+1:sla(2)-1);
    cyc{i}=lin(cyc(1)+1:cyc(1)+3);
end
fclose(fid);

f=ftp('ftp.usgodae.org','anonymous','anh.tran@dfo-mpo.gc.ca');
inputdir='c:\users\trana';
cd(inputdir);
binary(f)
for i=1:length(cyc)
    cd(f,['/pub/outgoing/argo/dac/meds/' floatnum{i} '/profiles']);
    mget(f,[floatnum{i} '_' cyc{i} '.nc']);
end
close(f);