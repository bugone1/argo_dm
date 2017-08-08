% CALIBRATION
%
% Files
%   ahex2dec                  - This function deciphers the hexadecimal number recorded
%   anh                       - 
%   apply_greylist            - function apply_greylist
%   argo_clip                 - 
%   askquestion               - function [out,i]=askquestion(in,all,profdecided)
%   batchDMQC                 - Programs called:
%   bestcandidate             - bestcandidate
%   bugzilla2pc               - 
%   bunch                     - 
%   calculate_profile_qc      - 
%   checkfilesfeb2009         - 
%   checkincomefiles          - function checkincomefiles.m
%   clean                     - eliminate r versions when d is present
%   contour_plot              - 
%   copy_nc                   - 
%   copy_nc_redim             - Copy a NetCDF file, changing a dimension in the process
%   create_source_file        - 
%   create_source_files       - Prepare files for OW processing. Display the float 
%   displaygraphs             - 
%   dmq                       - 
%   DMQC09                    - Programs called:
%   DMQC10                    - 
%   dmqc_632                  - 
%   dmqc_633                  - 
%   download_manager          - 
%   fetch_from_web            - Fetch Argo files from the Coriolis FTP site
%   findnameofsubdir          - return subdir for given float
%   fix_nws                   - 
%   fix_surface_flags         - Fix flags for floats with lots of pressures very near
%   fixjohnfiles              - 
%   fixQ4900234               - NOVEMBER 2009
%   genreport                 - function genreport
%   getcoeffs                 - 
%   getcoeffsfromfloat        - 
%   getcomments               - 
%   getFloatName              - 
%   getoldcoeffs              - Fetch existing calibration coefficients from NetCDF files
%   gettables                 - 
%   gredit_confirm            - function [nr,start,SAL,TEMP,PTMP,PRES,REJECT_SAL]=gredit_confirm(SAL,TEMP,PTMP,PRES,REJECT_SAL,PROFILE_NO,flnm)
%   heuredete                 - Du deuxième dimanche de mars inclus ou premier dimanche de novembre exclus
%   interactive_qc            - output fname is a filename with a structure "t" containing t&s data with
%   interactive_qc_ig         - Interactive QC of Argo files (Isabelle's version)
%   listdirs                  - list dirs which correspond to ranges
%   listfiles                 - Find dirs which correspond to ranges
%   load_configuration        - loadConfiguration
%   main                      - 
%   main_function             - 
%   main_ig                   - Main function for the Argo DMQC
%   main_visqc                - 
%   menudmqc                  - 
%   menudmqc_ig               - DMQC menu handling (Isabelle's version)
%   nanmean                   - Take the mean of a vector or matrix, excluding means. For a
%   nanmeanstd                - 
%   nansum                    - 
%   ncprofile_read_OSAP       - this routine is used to extract data from a single profile Argo file
%   ncprofile_write_OSAP      - NOTE: OUTPUT FLOAT_NUMBER CYCLE_NUMBER AND SCIENTIFIC_CALIB_COEFFICIENT in
%   netstr                    - function out=netstr(stri,dime);
%   nrewrite_nc               - 
%   orderfilesbycycle         - 
%   PiAction                  - function v=PiAction(profile_no,condslope,endpoint,oldcoeff)
%   piaction_pres             - 
%   piaction_psal             - 
%   plot_float_ts             - Plot TS for all float profiles
%   plotcoef                  - function plotcoef
%   plotcoef2                 - function plotcoef
%   post_WJO                  - 
%   pre_ow                    - 
%   pre_WJO                   - 
%   presDespikargo            - opres=pres;
%   presDoc                   - 
%   presMain                  - DMQC of Argo pressures
%   presPerformqc             - callled by presMain.m
%   prestnpd                  - 
%   processcycle              - function processcycle
%   processcycle1             - function processcycle1
%   processcycle2             - 
%   publishtoweb              - Prepare plots summarizing the result of Argo DMQC,
%   Q4900509                  - NOVEMBER 2009
%   qc                        - addpath('w:\argo_dm\calibration');
%   qc_window_ig              - QC_WINDOW_UI - Get and process user input from the visual QC window
%   qc_window_plots_ig        - QC_WINDOW_PLOTS - Create subplots for QC purposes
%   read_all_nc               - Net Argo NetCDF files
%   read_nc                   - Read an Argo profile NetCDF file
%   Real2DelayedMode          - After running WJO and ViewPlotsNew, the "changed" and "unchanged" directories will hold the new files.
%   reducehistory             - 
%   reducehistory_nc          - 
%   remove_exceeding_pressure - ---remove exceeding presure
%   remove_redundant_struct   - 
%   resize_dimension          - Copies a file while editing one dimension. Crops all
%   review_changed            - REVIEW_CHANGED
%   review_unchanged          - REVIEW_WORK
%   rewrite_nc                - Create an output Argo NetCDF file from an input file and parameters
%   rmsfit                    - 
%   rr                        - 
%   set_profile_qcflags       - Update QC flags for the position or date for a
%   sw_sat02                  - 
%   test                      - 
%   test_nc                   - 
%   transferflags             - t1 contains new data
%   uniquefloatsindir         - 
%   update_ref_dbase          - 
%   viewplots                 - Review results of OW calculations on Argo floats, choose
%   ViewPlotsNew              - Loads : C:\z\argo_dm\data\float_calib\freeland\calseries_*.mat
%   visual_qc_ig              - Visual QC of a single Argo profile (Isabelle's version)
%   write_nc                  - Copy and rewrite an Argo NetCDF file based on the provided
%   writehtml                 - Output the Argo DMQC HTML file
%   xp1152pc                  - 
%   PiAction_ig               - Create a conductivity adjustment curve based on OW results
%   displaygraphs_fun         - Display OW plots. Start by showing plot FigNo, then prompt
%   piaction_psal_ig          - PIACTION_PSAL Select a salinity adjustment based on OW output (Isabelle's
%   viewplots_ig              - VIEWPLOTS Review results of OW calculations on Argo floats, choose
