% load ../data/temppresraw/4901755.mat
for ii=1:length(t)
    foo2 = find(diff(t(ii).pres)<0 & t(ii).psal_qc(2:end) < '4');
    if ~isempty(foo2)
        disp('');
    end
end
        
        