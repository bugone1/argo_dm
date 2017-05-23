function qctests=hex2dec(history_qctest);%% This function deciphers the hexadecimal number recorded% in HISTORY_QCTEST in the Argo netcdf files, and tells you% which real-time qc tests are represented by it.%% input: 'history_qctest' in character string% e.g. :  qctests = hex2dec('24A00');%% Annie Wong, January 2008% modified by Breck Owens, January 2008% From Argo User Manualtestid_table={    '2' 'Platform Identification Test';    '4' 'Impossible Date Test';    '8' 'Impossible Location Test';    '16' 'Position on Land Test';    '32' 'Impossible Speed Test';    '64' 'Global Range Test';    '128' 'Regional Global Parameter Test';    '256' 'Pressure Increasing Test';    '512' 'Spike Test';    '1024' 'Top and Bottom Spike Test';    '2048' 'Gradient Test';    '4096' 'Digit Rollover Test';    '8192' 'Stuck Value Test';    '16384' 'Density Inversion Test';    '32768' 'Grey List Test';    '65536' 'Gross S or T Sensor Drift Test';    '131072' 'Visual QC Test';    '261144' 'Frozen Profile Test';    '524288' 'Deepest Pressure Test';    };% convert to binary and find which ones are 1'sstr = dec2bin(sscanf(history_qctest,'%x'));% Note: we don't need the least significant bittst= findstr(str(end-1:-1:1),'1');qctests=[];for n=1:length(tst)    qctests = [qctests;testid_table(tst(n),2)];end