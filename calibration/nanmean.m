function out=nanmean(in)
ok=~isnan(in);
out=mean(in(ok));