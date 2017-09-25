function doxy = calc_doxy(float_num,pres,temp,psal,temp_doxy,phase_delay_doxy)
% CALC_DOXY Calculate the dissolved oxygen for SBE63 sensors, as per the
%   Argo DOXY cookbook version 2.2
%   USAGE: 
%       doxy - calc_doxy(float_num,pres,temp,psal,temp_doxy,phase_delay_doxy)
%   INPUTS:
%       float_num - float number (used to select parameters)
%       pres - pressure
%       temp - temperture
%       psal - salinity
%       temp_doxy - temperature from the oxygen sensor
%       phase_delay_doxy - phase delay
%   OUTPUTS:
%       doxy - Oxygen concentration in micromoles per kilogram
%   VERSION HISTORY:
%       21 Aug. 2017, Isabelle Gaboury: Written based on the current
%           versions of the Java and Fortran routines used by Anh for
%           real-time QC

% Make sure the float number is numeric
if ischar(float_num), float_num=str2num(float_num); end

% Fetch the parameters
params = get_params(float_num);

% Calculate DOXY in uMol/m^3
V = (phase_delay_doxy + params.pcoef1 * pres/1000)/39.457071;
Ksv = params.C0 + params.C1*temp_doxy + params.C2 * temp_doxy.^2;
ro_water_s = 1013.25 * exp(params.D0 + params.D1 * (100./(temp + 273.15)) ...
        + params.D2 * log((temp + 273.15)/100) + params.D3 * psal);
ro_water_spreset = 1013.25 * exp(params.D0 + params.D1 * (100./(temp + 273.15)) ... 
        + params.D2 * log((temp + 273.15)/100) + params.D3 * params.psal_preset);
A = (1013.25 - ro_water_spreset)./(1013.25 - ro_water_s);
Ts = log((298.15-temp)./(273.15+temp));
Scorr = A .* exp(psal .*(params.solB0 +params.solB1*Ts + params.solB2* Ts.^2 ... 
        + params.solB3*Ts.^3) + params.solC0 * psal.^2);
Pcorr = 1 + (((params.pcoef2 *temp + params.pcoef3).*pres)/1000);
doxy = ((((params.A0 + params.A1*temp_doxy + params.A2 * V.^2)./ ...
    (params.B0 +params.B1*V)) - 1)./Ksv).*Scorr .*Pcorr * 44.6596;

% Convert to uMol/kg
% Calculating density of pure water
dw = 0.999842594 + 6.793952e-5 *temp - 9.095290e-6*temp.^2 + ...
    1.001685e-7*temp.^3 - 1.120083e-9*temp.^4 + 6.536332e-12*temp.^5;
A = 8.24493e-4 - 4.0899e-6*temp + 7.6438e-8*temp.^2 - ...
    8.2467e-10*temp.^3 + 5.3875e-12 *temp.^4;
B = -5.72466e-6 + 1.0227e-7*temp - 1.6546e-9*temp.^2;
C = 4.8314e-7;
dsw = dw + A.*psal + B.*psal.^1.5 + C .* psal.^2;
doxy = doxy./(dsw*1000)*1000;

end

function params = get_params(float_number)

    % FIXME: Finish implementing fetching parameters from file
    
    % Calibration coefficient file
    if ~ispc
        doxy_cal_file = '/u01/rapps/argo_dm/calibration/doxy_calibration_coef.csv';
    else
        doxy_cal_file = 'W:\argo_dm\calibration\doxy_calibration_coef.csv';
    end

    % General parameters
    pcoef1 = 0.115;
    pcoef2 = 0.00022;
    pcoef3= 0.0419;
    D0 = 24.4543;
    D1 = -67.4509;
    D2= -4.8489;
    D3 = -5.44e-4;
    psal_preset = 0;
    solB0 = -6.24523e-3;
    solB1 = -7.37614e-3;
    solB2 = -1.03410e-3;
    solB3 = -8.17083e-3;
    solC0 = -4.88682e-7;

    % Float-dependent parameters
    % TODO: Consider loading from file
    switch float_number
        case 4901779
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.9835e-001;
            B0 =-2.2317e-001;
            B1 = 1.7101;
            C0 = 8.8677e-002;
            C1 = 3.7066e-003;
            C2 = 5.2424e-005;
            E = 1.1000e-002;
        case 4901780
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.8121e-001;
            B0 =-2.2905e-001;
            B1 = 1.6975;
            C0 = 9.2491e-002;
            C1 = 3.8560e-003;
            C2 = 5.4903e-005;
            E = 1.1000e-002;
        case 4901781
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.1037e-001;
            B0 =-2.2988e-001;
            B1 = 1.6317;
            C0 = 9.9938e-002;
            C1 = 4.1949e-003;
            C2 = 5.9194e-005;
            E = 1.1000e-002;
        case 4901782
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.8159e-001;
            B0 =-2.2490e-001;
            B1 = 1.6957;
            C0 = 9.0583e-002;
            C1 = 3.8236e-003;
            C2 = 5.4023e-005;
            E = 1.1000e-002;
        case 4901784
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.35069e-001;
            B0 =-2.3160e-001;
            B1 = 1.6508;
            C0 = 9.8794e-002;
            C1 = 4.1925e-003;
            C2 = 5.5958e-005;
            E = 1.1000e-002;
        case 4901785
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 3.8388e-001;
            B0 =-2.3603e-001;
            B1 = 1.6048;
            C0 = 1.0655e-001;
            C1 = 4.5149e-003;
            C2 = 6.1844e-005;
            E = 1.1000e-002;
        case 4901786
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.8159e-001;
            B0 =-2.9151e-001;
            B1 = 1.5168;
            C0 = 1.2044e-001;
            C1 = 5.1041e-003;
            C2 = 7.0502e-005;
            E = 1.1000e-002;
        case 4901790
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.3870e-001;
            B0 =-2.3493e-001;
            B1 = 1.6975;
            C0 = 9.9072e-002;
            C1 = 4.2014e-003;
            C2 = 5.6472e-005;
            E = 1.1000e-002;
        case 4901791
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.2742e-001;
            B0 =-2.2202e-001;
            B1 = 1.6389;
            C0 = 9.6115e-002;
            C1 = 4.0795e-003;
            C2 = 5.6439e-005;
            E = 1.1000e-002;
        case 4901808
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 3.9128e-001;
            B0 =-2.1480e-001;
            B1 = 1.6020;
            C0 = 1.0304e-001;
            C1 = 4.3471e-003;
            C2 = 5.7248e-005;
            E = 1.1000e-002;
        case 4902383
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.5336e-001;
            B0 =-2.3397e-001;
            B1 = 1.6744;
            C0 = 9.5425e-002;
            C1 = 4.0395e-003;
            C2 = 5.4178e-005;
            E = 1.1000e-002;
        case 4902384
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.0759e-001;
            B0 =-2.2157e-001;
            B1 = 1.6213;
            C0 = 1.0121e-002;
            C1 = 4.2729e-003;
            C2 = 5.7236e-005;
            E = 1.1000e-002;
        case 4902385
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.7915e-001;
            B0 =-2.1016e-001;
            B1 = 1.6808;
            C0 = 9.1169e-002;
            C1 = 3.8441e-003;
            C2 = 4.9628e-005;
            E = 1.1000e-002;
        case 4902386
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2 = 4.7622e-001;
            B0 =-2.2334e-001;
            B1 = 1.6891;
            C0 = 9.1375e-002;
            C1 = 3.8645e-003;
            C2 = 5.1119e-005;
            E = 1.1000e-002;
        case 4902414
            A0 = 1.0513;
            A1 = -1.5000e-003;
            A2=5.0533e-001;
            B0=-1.9485e-001;
            B1=1.6956e+000;
            C0=8.5696e-002;
            C1=3.5631e-003;
            C2=4.5915e-005;
            E = 1.1000e-002;
    end
    
    params = struct('pcoef1',pcoef1,'pcoef2',pcoef2,'pcoef3',pcoef3,...
        'D0',D0,'D1',D1,'D2',D2,'D3',D3,'psal_preset',psal_preset,...
        'solB0',solB0,'solB1',solB1,'solB2',solB2,'solB3',solB3, ...
        'solC0',solC0,'A0',A0,'A1',A1,'A2',A2,'B0',B0,'B1',B1,...
        'C0',C0,'C1',C1,'C2',C2,'E',E);
    
%     % Load parameters from file
%     fid = fopen(doxy_cal_file,'r');
%     foo = fgetl(fid);   % Discard the header
%     data = fscanf(fid, '%d;%d;%s');
%     fclose(fid)
    
  end