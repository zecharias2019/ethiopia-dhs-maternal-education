*==============================================================================
* master.do
* Replication package: "Maternal Education and (First-Born) Infant Mortality in
* Ethiopia: Evidence from a Language-of-Instruction Reform"
*
* Runs the full pipeline from the raw 2016 Ethiopia DHS Individual Recode file
* to every table and figure in the paper and supplementary material.
* File names carry the table or figure they produce.
*
* Steps
*   1. Obtain ETIR71FL.DTA from the DHS Program (registration required; the
*      data cannot be redistributed) and place it in  <root>/data/raw/
*   2. Change Stata's working directory to this folder using 'cd':
*      cd "path/to/ethiopia-dhs-maternal-education"
*   3. Run this file:   do master.do
*
* I used Stata 19 but it should work on earlier versions  
* packages are installed automatically by code/00_config.do 
*==============================================================================

clear all
macro drop _all
set more off

*cd "path/to/ethiopia-dhs-maternal-education"           

*------------------------------------------------------------------------------
* 1. Set root directory  to current working directory
*------------------------------------------------------------------------------
if "$root" == "" {
    global root "`c(pwd)'"
}

*------------------------------------------------------------------------------
* 2. Switches: set to 0 to skip a step
*------------------------------------------------------------------------------
global run_build        1   // build analysis dataset from the raw DHS file
global run_table1       1   // Table 1
global run_tables2_3    1   // Tables 2 and 3
global run_table4       1   // Table 4
global run_s1           1   // Table S1
global run_fig1_s2_s3   1   // Figure 1, Tables S1-S3
global run_s4           1   // Table S4
global run_s5_fig2      1   // Table S5, Figure 2
global run_s6_s7_fig3   1   // Tables S6-S7, Figure 3
global run_s8_fig4      1   // Table S8, Figure 4
global run_s9_fig5      1   // Table S9, Figure 5
global run_s10_fig6     1   // Table S10, Figure 6

*------------------------------------------------------------------------------
* 3. Configuration (paths, packages, shared globals) and log
*------------------------------------------------------------------------------
do "$root/code/00_config.do"

capture log close master_log
log using "$logs/master_log.txt", text replace name(master)

*------------------------------------------------------------------------------
* 4. Run the pipeline
*------------------------------------------------------------------------------
if $run_build       do "$code/01_build_analysis_data.do"
if $run_table1      do "$code/Table1_summary_statistics.do"
if $run_tables2_3   do "$code/Tables2-3_main_results.do"
if $run_table4      do "$code/Table4_neonatal_decomposition.do"
if $run_s1          do "$code/TableS1_hansenJ_tests.do"
if $run_fig1_s2_s3  do "$code/Figure1_TablesS2-S3_leave_one_region_out.do"
if $run_s4          do "$code/TableS4_falsification_tests.do"
if $run_s5_fig2     do "$code/TableS5_Figure2_sensitivity_analysis.do"
if $run_s6_s7_fig3  do "$code/TablesS6-S7_Figure3_exclusion_restriction.do"
if $run_s8_fig4     do "$code/TableS8_Figure4_mechanisms.do"
if $run_s9_fig5     do "$code/TableS9_Figure5_birth_order.do"
if $run_s10_fig6    do "$code/TableS10_Figure6_heterogeneity.do"

log close master_log
*==============================================================================
* End of master.do
*==============================================================================
