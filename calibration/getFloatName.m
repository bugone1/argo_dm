function out=getFloatName(files)
for i=1:length(files)
und=find(files(i).name=='_');
out(i,1:und(1)-2)=files(1).name(2:und(1)-1);
end
