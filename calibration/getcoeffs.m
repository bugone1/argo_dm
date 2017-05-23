function [sdn,coeff,cyc]=getcoeffs(s)
coeff=nan(length(s),2);
for i=1:length(s)
    ma=min([2 length(s(i).PSAL)])-1;
    for j=0:ma
        tem=deblank(s(i).PSAL(end-j).coefficient)';
        if ~isempty(tem)
            coeff(i,(~j)+1)=condstrings(tem);
        else
            coeff(i,(~j)+1)=1;
        end
        if ~isempty(s(i).PSAL(end-j).sdn)
            sdn(i,(~j)+1)=s(i).PSAL(end-j).sdn;
        else
            sdn(i,(~j)+1)=nan;
            coeff(i,(~j)+1)=nan;
        end
    end
    cyc(i)=s(i).PSAL.cyc;
end

function co=condstrings(tem)
strings={'COEFFICIENT r FOR CONDUCTIVITY IS ','detected; r=','r='};
i=0;
ok=[];
while isempty(ok) && i<length(strings)
    i=i+1;
    ok=findstr(strings{i},tem);
end
if ~isempty(ok)
    stri=deblankde(tem(ok+length(strings{i}):end));
    if strcmpi(stri(1:3),'nan')
        co=nan;
    else
        nonchar=find(stri>'9' | stri<'.');
        if ~isempty(nonchar)
            stri=stri(1:nonchar(1)-1);
        end
        co=str2num(stri);
    end
elseif  findstr('COEFFICIENT FOR CONDUCTIVITY IS',tem)
    co=str2num(tem(findstr('COEFFICIENT FOR CONDUCTIVITY IS',tem)+31:end));
else
    error(tem)
end