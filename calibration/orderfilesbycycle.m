function filestoprocess=orderfilesbycycle(filestoprocess)
a=char(filestoprocess.name);
for i=1:size(a,1)
    unders=find(a(i,:)=='_');
    dot=find(a(i,:)=='.');
    cyc(i)=str2num(a(i,unders(1)+1:dot(1)-1));
end
[cyc,i]=sort(cyc);
filestoprocess=filestoprocess(i);