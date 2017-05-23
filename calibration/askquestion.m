function [out,i]=askquestion(in,all,profdecided)
%function [out,i]=askquestion(in,all,profdecided)
%Called by
%Asks question "in" and show which profiles have not been decided

[tr,undecided]=setdiff(all,profdecided);
display('Following profiles have not been decided')
num2str(all(undecided))
out=input(in);
if ~isempty(out)
    if out==-1
       out=all;
    elseif out==0
        out=all(undecided([1 end]));
    end
end
[tr,i]=intersect(all,out);