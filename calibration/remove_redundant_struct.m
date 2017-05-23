function s=remove_redundant_struct(s,field1)
[x,i]=unique(cat(1,s.(field1)));
s=s(i);