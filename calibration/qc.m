%addpath('w:\argo_dm\calibration');
function qc (floatId)
addpath('c:\users\trana\MATLAB\argo_dm\calibration');
%files=dir('*4901147_1*.nc');
%files = dir(strcat(strcat('*',floatId),'*.nc'));
files = dir (floatId);
for i=1:length(files)
    t(i)=read_nc(files(i).name);
end
q='s';
for i=1:length(t)
    tic;
    [t(i),q]=visual_qc(t(i),q);
    dura=toc;
    %if more than 1 second is spent on the screen, flag this profile as having been visually QCed
    if dura>1
        t(i).qc=1;
    end
end
for i=1:length(files)
    write_nc(files(i).name,t(i),[pwd filesep 'new' filesep files(i).name]);
end
end