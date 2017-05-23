function [x,y,z]=getcoeffsfromfloat(floatname)
if lower(floatname(1))=='q'
    floatname=floatname(2:end);
end
local_config=load_configuration('local_wjo.txt');
dire=[local_config.DATA findnameofsubdir(floatname,listdirs(local_config.DATA))];
files=dir([dire filesep '*' floatname '*.nc']);
for i=1:length(files);
    [dire filesep files(i).name]
    [s(i),h]=getcomments([dire filesep files(i).name]);
end
[x,y,z]=getcoeffs(s);
