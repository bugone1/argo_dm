function s=comparefiles(f1,f2)
%warns before starting a process that could have already been done
sour=dir(f1);
towr=dir(f2);
s=1;
if ~isempty(towr)
    if sour.datenum<towr.datenum
        s=input('Source file is older than file to create. Likely nothing \n changed since last time you performed this action. Want to do it anyway? (1=yes,else=no)','s');
        if isempty(s) || s~='1'
            s=0;
        elseif s=='1'
            s=1;
        end
    end
end