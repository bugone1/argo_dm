function s= calculate_profile_qc(qc)
coun=qc=='1' | qc=='2' | qc=='5' | qc=='8'; %coun is logical data type
ratio=sum(coun)/sum(qc~='9'); %ratio is double data type
if ratio==1
    s='A';
elseif ratio>=.75
    s='B';
elseif ratio>=.5;
    s='C';
elseif ratio>=.25;
    s='D';
elseif ratio>0
    s='E';
else
    s='F';
end