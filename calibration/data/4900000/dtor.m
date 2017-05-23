d=dir('d4900632*.nc');
for i=1:length(d)
    d(i)
    tic 
%    s=copyfile(d(i).name,['r' d(i).name(2:end)]);
%    if s==1
%        delete(d(i).name)
%    end
    system(['ren ' d(i).name ' r' d(i).name(2:end)])
    toc
end