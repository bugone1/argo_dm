function out=nanmeanstd(in)
ok=~isnan(in);
out=mean(in(ok));