function out=nansum(in)
ok=~isnan(in);
out=sum(in(ok));