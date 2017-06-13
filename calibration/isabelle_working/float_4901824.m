% Script to finish processing of float 4901824, for which no OW processing
% was done
%
% Isabelle Gaboury, 31 May 2017

% Setup
local_config=load_configuration('local_OW.txt');
lo_system_configuration=load_configuration([local_config.BASE 'config_ow.txt']);
float_num = '4901824';
psal_comment = 'Too few profiles passed visual QC to compute a conductivity adjustment';

%viewplots_nocorr(lo_system_configuration,local_config,float_num, psal_comment);
%reducehistory(local_config,float_num);
publishtoweb_nocorr(local_config,lo_system_configuration,float_num,1);