%After running WJO and ViewPlotsNew, the "changed" and "unchanged" directories will hold the new files.
%this program copies the new files into each ".\save" directory for both the unchanged and changed files.
%it then examines all the saved files and converts any files older than 6
%months to mode "D" and renames the files to D???????_???.nc.
%Any converted files are copied to their parent directories (changed or unchanged)
%Later, zip files of changed and unchanged directories are then sent to MEDS and these directories are emptied for the next group of new files.
ncclose
lo_system_configuration=load_configuration('CONFIG_WJO.TXT');
local_config=load_configuration('local_WJO.txt');
cd(local_config.BASE);
close('all')
fclose('all')
keep local_config;
dirnames1={'changed\','unchanged\'};
dirnames2={''};%,'save\'};
for i=1:length(dirnames1)
    for j=1:length(dirnames2)
        dirname=[dirnames1{i} dirnames2{j}];
        changed=dir([local_config.OUT dirname 'r4900523*.nc']);
        if ~isempty(changed);
            chg_nm=strvcat(changed.name);
            for ii=1:size(chg_nm,1)
                flnm=[local_config.OUT dirname chg_nm(ii,:)]
                f=netcdf(flnm,'write');
                JUL=f{'JULD'}(:);
                [tr,psalindex]=intersect(f{'PARAMETER'}(1,end,:,:),'PSAL','rows');
                if isempty(psalindex)
                    f{'PARAMETER'}(1,end,3,:)=netstr('PSAL',4);
                    psalindex=3;
                end
                caldate=f{'CALIBRATION_DATE'}(1,end,psalindex,:)';
                str=[caldate(1:4) '-' caldate(5:6) '-' caldate(7:8) ' ' caldate(9:10) ':' caldate(11:12) ':' caldate(13:14)];
                if (datenum(str)-datenum(1950,1,1)-JUL)>183; %older than 6 months
                    f{'DATA_MODE'}(:)='D';
                    close(f);f=[];
                    flnmd=[local_config.OUT dirname 'd' chg_nm(ii,2:end)];
                    if exist(flnmd);delete(flnmd);end
                    %                    flnmd=[local_config.OUT dirname '\save\d' chg_nm(ii,2:end)];
                    %                   if exist(flnmd)
                    %                       if ~exist([flnmd 'x']);system(['ren ' flnmd ' ' ['d' chg_nm(ii,2:end) 'x']]);else delete(flnmd);end
                    %                   end
                    c=system(['ren ' flnm ' D' chg_nm(ii,2:end)]);
                    if c ~= 0;error(['cannot rename ' flnm ' to D file']);end
                end
                if isobject(f);close(f);end
            end
        end
    end
end
%load the save archive with newer copies of .nc files (/D), only ones with the
%archive bit set and reset all archive bits (/M).
%/Y suppresses messages
%dscmd=['move ' local_config.OUT 'changed\*.* ' local_config.OUT 'changed\save']; %update the save directory
%c=system(dscmd);
%if c ~= 0;error(['cannot update .\changed\save directory']);end
%dscmd=['move  ' local_config.OUT 'unchanged\*.* ' local_config.OUT 'unchanged\save']; %update the save directory
%c=system(dscmd);
%if c ~= 0;error(['cannot update .\unchanged\save directory']);end
'DONE Real2DelayedMode'