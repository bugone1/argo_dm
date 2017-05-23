function beg=piaction_pres(lo_system_configuration,floatNum)
flnm=[lo_system_configuration.FLOAT_PLOTS_DIRECTORY '..' filesep 'pres_bath_' floatNum '.png'];
beg='a';
while ~isempty(beg) && beg(1)>'9'
%    system(flnm);
    beg=input('Enter cycle number at which the float definitely became a microleaker (empty or 0=none/never)','s');
end
if isempty(beg) || strcmp(beg,'0')
    beg=nan;
else
    beg=str2num(beg);
end