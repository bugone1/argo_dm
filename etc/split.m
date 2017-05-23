load ctd_7412
dates=dates(:,1:1000);
lat=lat(:,1:1000);
long=long(:,1:1000);
pres=pres(:,1:1000);
ptmp=ptmp(:,1:1000);
sal=sal(:,1:1000);
source=source(:,1:1000);
temp=temp(:,1:1000);
save ctd_7412_a

load ctd_7412
dates=dates(:,1001:end);
lat=lat(:,1001:end);
long=long(:,1001:end);
pres=pres(:,1001:end);
ptmp=ptmp(:,1001:end);
sal=sal(:,1001:end);
source=source(:,1001:end);
temp=temp(:,1001:end);
save ctd_7412_b

a=load('ctd_7412_a');
b=load('ctd_7412_b');


clear;
for i=52682237:62105999
    clear a
    i
    a=zeros(52682237,1);
end