%Find dirs which correspond to ranges
dirs=dir(local_config.DATA);
isdir=cat(1,dirs.isdir);
names=char(dirs.name);
ok=find(names(:,1)>='0' |  names(:,1)<='9' & isdir);
I=length(ok);
curdir=[local_config.DATA deblank(names(ok(I),:)) filesep];
dirpath=[curdir filesep '*4900523*.nc'];
NewFiles = dir(dirpath);
