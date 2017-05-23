function pres=presDespikargo(pres,thre,recursive)
%opres=pres;
lp=length(pres);
spiks=[abs(diff(pres))>=thre; 0];
j=find((spiks | spiks([2:end end]))); 
iter=0;
if ~isempty(j)
    while ~isempty(j) && iter<recursive
        iter=iter+1;
        for i=1:length(j)
            if i>1 && i<lp && ~any(j==j(i-1)) && ~any(j==j(i+1))
                pres(j(i))=mean(pres(j(i)+[-1 1]));
            elseif j(i)>1 && ~any(j==j(i)-1)
                pres(j(i))=mean(pres(j(i)-1));
            elseif j(i)<lp && ~any(j==j(i)+1)
                pres(j(i))=mean(pres(j(i)+1));
            end
        end
        if recursive>0
            spiks=[abs(diff(pres))>=thre; 0];
            j=find((spiks | spiks([2:end end]))); % & abs(pres)>=thre);            
        else
            j=[];
        end
    end
    if iter==recursive
        'max iterations reached'
        pause
    end
end