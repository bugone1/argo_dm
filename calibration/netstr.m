function out=netstr(stri,dime)
%function out=netstr(stri,dime);
%padds a string with blanks to a certain length number (dime)
out=ones(1,dime)*32;
if dime<length(stri)
    stri=strtok(stri,'(');
    if dime<length(stri)
    stri=stri(1:dime);
    end
end
out(1:length(stri))=stri;
out=char(out);