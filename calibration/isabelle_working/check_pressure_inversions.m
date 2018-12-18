function check_pressure_inversions(float_num, report_only)
% CHECK_PRESSURE_INVERSIONS Quick check for pressure non-increasing
% Routine assumes the mat file has already been created
%   USAGE: check_pressure_inversions(float_num, report_only)
%   INPUTS:
%       float_num - Float number, as a string
%       report_only - Set to 0 to flag the bad values, 1 to only report
%           (default)
%   VERSION HISTORY:
%       Isabelle Gaboury, 22 Jan. 2018
%       27 Apr. 2018, IG: Changed default behaviour to only report, not
%           change the files

if nargin < 2, report_only=1; end

% Setup
data_dir = '../data/temppresraw';

% Load the data
load([data_dir filesep float_num '.mat'],'t');

% Calculate the potential density
for ii_prof=1:length(t)
    ok = find(t(ii_prof).pres_qc(2:end) <= '2' & t(ii_prof).pres(2:end)<=t(ii_prof).pres(1:end-1));
    if ~isempty(ok)
        ok=ok+1;
        if report_only==1
            disp(['Found unflagged duplicate/reversal for cycle ' num2str(t(ii_prof).cycle_number) ', z=' num2str(t(ii_prof).pres(ok))]);
        else
            t(ii_prof).pres_qc(ok) = '4';
            t(ii_prof).psal_qc(ok) = '3';
        end
    end
end

if report_only==0
    save([data_dir filesep float_num '.mat'],'t','-append');
end
end