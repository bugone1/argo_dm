%loads MAT file : C:\z\argo_dm\data\float_mapped\freeland\map_*_.mat
%if it exists,loads MAT file : C:\z\argo_dm\data\float_calib\freeland\calseries_*.mat
%Saves MAT file : C:\z\argo_dm\data\float_calib\freeland\calseries_*.mat
function set_calib_series(pn_float_dir,pn_float_name,po_system_configuration)
% function set_calib_series(pn_float_dir,pn_float_name,po_system_configuration)
% cal_series_flags = preceding profile until changed
% A. Wong,4 Sep 2002
% get profile_no from mapped file ----
ls_float_mapped_filename= strcat(po_system_configuration.FLOAT_MAPPED_DIRECTORY,pn_float_dir,po_system_configuration.FLOAT_MAPPED_PREFIX,pn_float_name,po_system_configuration.FLOAT_MAPPED_POSTFIX);
ls_calseries_filename = strcat(po_system_configuration.FLOAT_CALIB_DIRECTORY,pn_float_dir,po_system_configuration.FLOAT_CALSERIES_PREFIX,pn_float_name,po_system_configuration.FLOAT_CALIB_POSTFIX) ;
if comparefiles(ls_float_mapped_filename,ls_calseries_filename)
    lo_float_mapped_data = load(ls_float_mapped_filename) ;
    mapped_profile_no = lo_float_mapped_data.la_profile_no;
    % build calseries file ----
    %if this file has been calibrated before; load parameters
    if ~isempty(dir(ls_calseries_filename))
        load(ls_calseries_filename);
    else%otherwise,initialize new parameters
        calib_profile_no = mapped_profile_no;
        running_const = str2double(po_system_configuration.CONFIG_RUNNING_CONST).*ones(1,length(mapped_profile_no));
        cal_series_flags = ones(1,length(mapped_profile_no));
    end
    if ~ exist('CellK','var');CellK=ones(1,length(mapped_profile_no))*NaN;end %calseries is saved in set_calseries_ron.m
    if ~ exist('comment','var');   comment{length(CellK)}=' ' ;end %ron
    if ~ exist('min_err','var');min_err= ones(1,length(mapped_profile_no))*NaN;end %ron
    if ischar(comment);comment=cellstr(comment);end
    % compare profile_number in mapped file and calseries file ----
    missing_profile_index = [];
    for i=1:length(mapped_profile_no)
        if sum(calib_profile_no==mapped_profile_no(i))==0
            missing_profile_index = [ missing_profile_index,i ];
        end
    end
    % update calseries file by missing_profile_index ----
    for i=1:length(missing_profile_index)
        j = missing_profile_index(i);
        calib_profile_no = [calib_profile_no,mapped_profile_no(j)];
        running_const = [running_const,str2double(po_system_configuration.CONFIG_RUNNING_CONST)];
        cal_series_flags = [cal_series_flags,cal_series_flags(max(j-1,1))]; %same flag as previous profile
        min_err = [min_err,NaN]; %ron
        CellK = [CellK ,NaN]; %ron
        comment{length(comment)+1} = ''; %ron
    end
    % sort the calseries file by profile_number ----
    [y,ii]=sort(calib_profile_no);
    calib_profile_no=calib_profile_no(ii);
    running_const=running_const(ii);
    cal_series_flags=cal_series_flags(ii);
    min_err=min_err(ii); %ron
    CellK=CellK(ii); %ron
    for jj=1:length(ii);tempc{jj}=comment{ii(jj)};end; %ron
    comment=tempc; %ron
    % save calseries file ----
    save(ls_calseries_filename,'calib_profile_no','running_const','cal_series_flags' ,'CellK' ,'min_err' ,'comment');
end