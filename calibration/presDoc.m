


3.2.1. Delayed-mode pressure adjustment for APEX floats
Similar to the real-time procedure, pressures from APEX floats should be adjusted for offsets by using SURFACE PRESSURE (SP) values 
in delayed-mode. SP values are stored in the Argo technical files in the variable PRES_SurfaceOffsetNotTruncated _dBAR 
or PRES_SurfaceOffsetTruncatedPlus5dbar_dBAR, depending on the type of APEX controller used. The SP time series is examined and 
treated in delayed-mode as follows:
(1). Subtract 5-dbar from the values in PRES_SurfaceOffsetTruncatedPlus5dbar _dBAR.
(2). Despike the SP time series to 1-dbar. This is most effectively done by first 
removing the more conspicuous spikes that are bigger than 5-dbar (as in the real-time procedure), 
then the more subtle spikes that are between 1- to 5-dbar by comparing the SP values with those derived from a 5-point median 
filter. For standard Argo floats that sample every 10 days, a 5-point filter represents a filter window of 40 days (+/- 20 days from a profile), which is an appropriate time scale for retaining effects from the atmospheric seasonal cycle.
(3). Replace the missing SP values by interpolating between good neighbouring points. If missing values occur at the ends of the SP 
time series, extrapolate from the nearest good points.

The resulting SP time series should then be inspected visually to make sure there are no more erroneous points. Then the clean SP 
value from cycle i+1 is used to adjust CTD pressures from cycle i by
PRES_ADJUSTED (cycle i) = PRES (cycle i) – SP (cycle i+1).
The CTD profile and the associated SP is staggered by one cycle because the SP measurement is taken after the telemetry period, 
and therefore is stored in the memory and telemetered during the next cycle. The real-time procedure does not match SP 
(cycle i+1) with PRES (cycle i) because real-time adjustment cannot wait 10 days. However, in delayed-mode, it is important to 
match the CTD profile with the staggered transmission of SP because SP contains synoptic atmospheric variations, 
and because a missing CTD profile is often associated with an erroneous SP point. By this scheme, SP(1), which is taken 
before cycle 1 and therefore before the float has had its first full dive, is not used in delayed-mode.

Note that the real-time procedure does not adjust for pressure offsets that are greater than 20 dbar (or less than -20 dbar). 
This is because the real-time automatic procedure cannot determine whether SP values greater than 20 dbar (or less than -20 dbar) represent real sensor drift or erroneous measurements. Instead, in real-time, floats that return SP values greater than 20 dbar (or less than -20 dbar) for more than 5 consecutive cycles are grey-listed in consultation with the PI. In delayed-mode, operators can inspect the SP time series visually when severe pressure sensor drift occurs. Therefore there is no upper limit to the magnitude of delayed-mode pressure adjustment.
After adjustment, delayed-mode operators should check that PRES_ADJUSTED > 0. If PRES_ADJUSTED < 0, delayed-mode operators should check for decoding errors in SP or in the CTD pressures.
PRES should always record the raw data.

PRES_ADJUSTED_QC should be set appropriately. For example, floats that have had significant pressure adjustment should have PRES_ADJUSTED_QC = ‘2’.
PRES_ADJUSTED_ERROR = 2.4-dbar is the recommended error to quote, with 2.4-dbar being the manufacturer quoted accuracy of the pressure sensor.
Salinity should be re-calculated by using PRES_ADJUSTED, and recorded in PSAL_ADJUSTED. Salinity error due to pressure uncertainty is negligible, and can be ignored in the consideration of PSAL_ADJUSTED_ERROR.
Please use the SCIENTIFIC CALIBRATION section in the netCDF files to record details of the delayed-mode adjustment.
Note to users: The 1-dbar despiking threshold for SP assumes that spikes greater than 1-dbar represent noise in the SP measurement
that should not be integrated into float pressures. After despiking to 1-dbar, the remaining SP values contain sea surface 
atmospheric pressure variations and variations due to other high-frequency surface processes. While sea surface atmospheric 
pressure variations affect the whole water column and therefore should be adjusted for, high-frequency surface processes do not 
affect the whole water column. Therefore users should be aware that PRES_ADJUSTED contains noise from high-frequency surface 
processes that are of the order <1-dbar. In addition, other more subtle pressure errors such as those due to non-linear hysteresis 
and other temperature- and pressure-dependent effects are not accounted for in PRES_ADJUSTED. Hence users should always heed the error bars 
quoted in PRES_ADJUSTED_ERROR.

3.2.2. Truncated negative surface pressure drifts (TNPDs) in APEX floats
APEX floats with Apf-8 controllers that set negative SP to zero (then add the artificial 5-dbar) present a challenge to delayed-mode qc because information from SP on any negative pressure offset is lost. For these floats, if a large portion (nominally 80%) of the SP time series report zero (after removing the artificial 5-dbar), unknown negative pressure error should be suspected. These APEX floats are referred to as APEX TNPDs (truncated negative surface pressure drifts) and their pressures cannot be adjusted. Two scenarios should then be considered.
1. When float data do not show T/S anomaly. This means that the float may be experiencing unknown negative pressure errors that are not severe. For these cases, the adjusted variables should receive a delayed-mode qc flag of ‘2’. That is,
PRES_ADJUSTED_QC = ‘2’
TEMP_ADJUSTED_QC = ‘2’
PSAL_ADJUSTED_QC = ‘2’.
2. When float data show T/S anomaly. This means that the float is experiencing unknown negative pressure errors that are severe. T/S anomaly associated with severe negative pressure error includes:
(a). Positive salinity drift; e.g. pressure error of -20-dbar will cause a +ve salinity error of approximately 0.01 PSS-78.
(b). Cold temperature anomaly whose size depends on vertical temperature gradient.
(c). Float-derived dynamic height anomalies significantly lower than satellite-derived sea level anomalies.
(d). Shoaling of isotherm depths independent of time/space migration of the float.
For these severe cases, delayed-mode operators in consultation with float PIs should consider putting the floats on the grey list. The adjusted variables should receive a delayed-mode qc flag of ‘3’ or ‘4’, depending on the severity of the T/S anomaly. That is,
PRES_ADJUSTED_QC = ‘3’ or ‘4’
TEMP_ADJUSTED_QC = ‘3’ or ‘4’
PSAL_ADJUSTED_QC = ‘3’ or ‘4’.
In both of the above two scenarios, SCIENTIFIC_CALIB_COMMENT should contain the character string “TNPD: APEX float that truncated negative surface pressure drift.” This is to assist users in identifying the APEX floats with unknown negative pressure errors, and whose pressures are therefore unadjustable.
Note that if an APEX TNPD float is telemetering highly erratic data, it is a sign that it may be suffering from the Druck oil microleak problem, and that the disease is about to reach its endpoint. Previous cycles may need to be reviewed.
Argo