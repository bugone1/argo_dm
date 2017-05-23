if 0
    fid=fopen('632.txt','r');
    fie=fopen('n632.txt','w');
    while ~feof(fid)
        lin=fgetl(fid);
        if isempty(lin)
            lin=' ';
        end
        if (lin(1)~=' ' && lin(1)~='1')
        else
            fprintf(fie,[lin '\n']);
        end
    end
    fclose all
end

cyc=[1  
2  
3  
4  
5  
6  
7  
8  
9  
10 
11 
12 
13 
14 
15 
16 
17 
18 
19 
20 
21 
22 
23 
24 
25 
26 
27 
28 
29 
30 
31 
32 
33 
34 
35 
36 
37 
38 
39 
40 
41 
42 
43 
44 
45 
46 
47 
48 
49 
50 
51 
52 
53 
54 
55 
56 
57 
58 
59 
60 
61 
62 
63 
64 
65 
66 
67 
68 
69 
70 
77 
88 
90 
91 
94 
96 
99 
103
112
114
115
116
118
120
127
129
130
132
142
149
150
158];


clear ok
nc=netcdf.open('4900632_tech.nc','nowrite')
i=netcdf.inqVarID(nc,'TECHNICAL_PARAMETER_NAME');
allv=netcdf.getVar(nc,i)';
ok{1}=strmatch('POSITION_PistonPark_COUNT',allv);
ok{2}=strmatch('POSITION_PistonProfile_COUNT',allv);
ok{3}=strmatch('POSITION_PistonSurface_COUNT',allv);
j=netcdf.inqVarID(nc,'TECHNICAL_PARAMETER_VALUE');
val=netcdf.getVar(nc,j)';
clear e
for i=1:length(ok)
    for j=1:length(ok{i})
        e(j,i)=str2num(val(ok{i}(j),:));
    end
end

clear ok
q=load('632dep.txt');
ok=[0;find(diff(q(:,1))<0);size(q,1)];
jj=0;
for j=1:length(ok)-1
    jj=jj+1;
    okk=ok(j)+1:ok(j+1);
    p{jj}=q(okk,:);
    q(okk,4)=jj;
    mm(j)=min(p{jj}(:,1));
end
q(q==99.999)=nan;
ok=intersect(cyc,1:192);
[ux,uy,a]=make_c(q(:,4),q(:,1),unique(q(:,4)),unique(round(q(:,1)*100)/100),[100 100],q(:,3));
surface(cyc,uy,a','edgecolor','none')
C=contourf(cyc,uy,a');
set(gca,'ydir','reverse')
set(gca,'ylim',[-10 2000])


S=getClim(LON,LAT,sprintf('%2.2i',nmonth),'psal')