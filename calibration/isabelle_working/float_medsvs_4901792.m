function float_medsvs_4901792
% Custom script to view MEDSVS data for float 4901792
% Meant to be run from the medsvs directory
% Isabelle Gaboury, 27 Sep. 2017

cycles = [0,22;26,48;50,66];
dates = [20151129,20160705;20160814,20170322;20170411,20170918];
lats = [-53,-47;-61.5,-57.5;-54.5,-52.5];
lons = [145,156;165,178;175,178];
fnames = {'MEDS_ASCII2709545931.DAT;1','MEDS_ASCII2710090543.DAT;1','MEDS_ASCII2710365832.DAT;1'}

for ii=1:3
    figure
    title_string = [num2str(-1*lats(ii,1)),'-',num2str(-1*lats(ii,2)),'S, ',num2str(lons(ii,1)),'-',num2str(lons(ii,2)),'E, ',num2str(dates(ii,1)),'-',num2str(dates(ii,2))];
    float_medsvs('4901792', fnames{ii}, cycles(ii,1):cycles(ii,2), title_string);
end
end