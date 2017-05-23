function subdirname=findnameofsubdir(floatname,dirs)
%return subdir for given float
if lower(floatname(1))=='q' 
    floatname=floatname(2:end);
end
ndirs=str2num(dirs);
num=str2num(floatname)*10^(7-length(floatname));
ok=find(num>=ndirs);ok=ok(length(ok));
subdirname=deblank(dirs(ok,:));