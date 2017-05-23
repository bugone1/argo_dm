function fix_nws(fname)
fid=fopen(fname,'r');
s=fread(fid);
fclose(fid);
ok=find(s(1:end-13)=='=' & s(14:end)=='S');
s(ok+2)=10;
s(ok+3)=13;
s(ok+4)=10;
s(ok+5)=13;
['Fixed ' num2str(length(ok)) ' lines']

ok=find(s(1:end-13)=='=' & s(14:end)=='S');


movefile(fname,[fname 'old'],'f');
fie=fopen(fname,'w');
fwrite(fie,s);
fclose(fie);