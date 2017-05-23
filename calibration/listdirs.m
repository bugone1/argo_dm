function dirs=listdirs(rep)
%list dirs which correspond to ranges
dirs=dir(rep);
isdir=cat(1,dirs.isdir);
names=char(dirs.name);
ok=find((names(:,1)>='0' & names(:,1)<='9') & isdir);
dirs=names(ok,:);