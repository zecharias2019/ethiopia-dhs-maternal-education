*==============================================================================
* Tables2-3_main_results.do
* Tables 2 and 3. Main results: first stage (FS), reduced form (RF), 2SLS and OLS.
*   Columns 1-4: excludes the partially exposed cohort (age 8-14 in 1994)
*   Columns 5-8: includes all cohorts in the reform regions
* Both blocks report, in order: FS, RF, 2SLS, OLS.
* Output: output/tables/Tables2-3_main_results.xls
*
* Table note: The excluded instruments are an indicator for being aged 7 or
* younger in 1994 (treat) and linear age trends on each side of the cutoff
* (treat_inter, control_inter). Region-specific age trends are absorbed with
* ivreg2's partial() option. Standard errors are two-way clustered by
* PSU-by-age-in-1994 cell and by age in 1994.
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

use "$maindata", clear

local first = 1
foreach spec in excl incl {

    if "`spec'" == "excl" local cond "$sample"
    else                  local cond "RegionInMain==1 & fborn_deceased!=."

    * 2SLS with stored first stage and reduced form
    ivreg2 infant_mortality (educ_years = $instruments) $controls if `cond', ///
        cluster($cluster) first ffirst savefirst savefprefix(fs_`spec') ///
        rf saverf saverfprefix(rf_`spec') partial($partial_vars)

    estimates store tsls_`spec'
    gen insample_`spec' = e(sample)
    quietly summarize infant_mortality if e(sample)
    local mout_`spec' = r(mean)
    scalar kpf_`spec' = e(widstat)
    scalar arp_`spec' = e(archi2p)

    local mode = cond(`first', "replace", "append")

    * First stage
    estimates restore fs_`spec'educ_years
    outreg2 using "$output/Tables2-3_main_results.xls", `mode' bdec(3) ///
        ctitle("Education in years: FS") keep($instruments) ///
        addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label

    * Reduced form
    estimates restore rf_`spec'infant_mortality
    outreg2 using "$output/Tables2-3_main_results.xls", append bdec(3) ///
        ctitle("Infant mortality: RF") keep($instruments) ///
        addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label

    * 2SLS
    estimates restore tsls_`spec'
    outreg2 using "$output/Tables2-3_main_results.xls", append bdec(3) adec(3) ///
        ctitle("Infant mortality: 2SLS") keep(educ_years) ///
        addstat(KP rk Wald F, kpf_`spec', AR test p-value, arp_`spec', ///
                Avg. outcome, `mout_`spec'') ///
        addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label

    * OLS on the same sample
    regress infant_mortality educ_years $controls if insample_`spec', ///
        vce(cluster cluster_id age_1994)
    quietly summarize infant_mortality if e(sample)
    local mols = r(mean)
    outreg2 using "$output/Tables2-3_main_results.xls", append bdec(3) adec(3) ///
        ctitle("Infant mortality: OLS") keep(educ_years) ///
        addstat(Avg. outcome, `mols') ///
        addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label

    local first = 0
}

*==============================================================================
* End of Tables2-3_main_results.do
*==============================================================================
