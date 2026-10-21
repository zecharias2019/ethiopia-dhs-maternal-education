*==============================================================================
* TableS5_Figure2_sensitivity_analysis.do
*
* PART A  Table S5, sensitivity of the baseline estimate (one loop, four specs)
*   Cols 1-2  Quadratic age trends on each side of the cutoff added to the
*             instrument set                               (FS, 2SLS)
*   Cols 3-4  Restricted window: women aged 0-22 in 1994   (FS, 2SLS)
*   Cols 5-6  Baseline plus the sibling mortality rate as a control
*             (proxy for family health environment). Endogenous variable:
*             years of education                           (FS, 2SLS)
*   Cols 7-8  Baseline specification, no sibling mortality control. Endogenous
*             variable: ever attended school (DHS s107)    (FS, 2SLS)
*
* PART B  Figure 2, 2SLS estimate as the upper age bound of the unexposed cohort
*         varies from 15 to 28.
*
* Under the pre-reform system primary school ran grades 1-8 with entry around
* age 7, so age 7 in 1994 is the natural cutoff. Age 22 corresponds to the
* approximate end of tertiary schooling.
*
* Outputs: output/tables/TableS5_sensitivity_analysis.xls
*          output/figures/Figure2_bandwidth_sensitivity.png
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

use "$maindata", clear

*==============================================================================
* PART A. TABLE S5
*==============================================================================
local first = 1
foreach spec in quad bw sib att {

    * Defaults: baseline specification
    local endog  "educ_years"
    local lab    "Education in years"
    local inst   "$instruments"
    local fskeep "$instruments"
    local cond   "$sample"
    local extra  ""

    *--------------------------------------------------------------------------
    * Columns 1-2: quadratic age trends
    *--------------------------------------------------------------------------
    if "`spec'" == "quad" {
        local inst   "$instruments age2Xtreat age2Xcontrol"
        local fskeep "$instruments age2Xtreat age2Xcontrol"
    }

    *--------------------------------------------------------------------------
    * Columns 3-4: restricted window (aged 0-22 in 1994)
    *--------------------------------------------------------------------------
    if "`spec'" == "bw" {
        local cond "$sample & inrange(age_1994,0,22)"
    }

    *--------------------------------------------------------------------------
    * Columns 5-6: control for the sibling mortality rate
    *--------------------------------------------------------------------------
    if "`spec'" == "sib" {
        local extra "sib_mortality_rate"
    }

    *--------------------------------------------------------------------------
    * Columns 7-8: ever attended school (s107), baseline controls only,
    * 
    *--------------------------------------------------------------------------
    if "`spec'" == "att" {
        local endog "s107"
        local lab   "Ever attended school"
    }

    ivreg2 infant_mortality (`endog' = `inst') $controls `extra' if `cond', ///
        cluster($cluster) first ffirst savefirst savefprefix(fs_`spec') ///
        partial($partial_vars $lang_dummies ///
		 Gambela SNNP Benishangul Somali Oromia Amhara Afar)

    estimates store tsls_`spec'
    scalar kpf_`spec' = e(widstat)
    scalar arp_`spec' = e(archi2p)
    quietly summarize infant_mortality if e(sample)
    local mout_`spec' = r(mean)
    quietly summarize `endog' if e(sample)
    local mfs_`spec' = r(mean)

    local mode = cond(`first', "replace", "append")

    * First stage
    estimates restore fs_`spec'`endog'
    outreg2 using "$output/TableS5_sensitivity_analysis.xls", `mode' bdec(3) adec(3) ///
        ctitle("`lab': FS (`spec')") keep(`fskeep') ///
        addstat(KP rk Wald F, kpf_`spec', Avg. outcome, `mfs_`spec'') ///
        addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label

    * 2SLS
    estimates restore tsls_`spec'
    outreg2 using "$output/TableS5_sensitivity_analysis.xls", append bdec(3) adec(3) ///
        ctitle("Infant mortality: 2SLS (`spec')") keep(`endog') ///
        addstat(KP rk Wald F, kpf_`spec', AR test p-value, arp_`spec', ///
                Avg. outcome, `mout_`spec'') ///
        addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label

    local first = 0
}

*==============================================================================
* PART B. FIGURE 2: bandwidth sensitivity
* Vary the upper age bound of the unexposed cohort from 15 to 28.
*==============================================================================
local lo_age = 15
local hi_age = 28
local n_steps = `hi_age' - `lo_age' + 1
matrix bw_res = J(`n_steps', 4, .)     // columns: bound, coef, lower, upper

local row = 1
forvalues upper = `lo_age'/`hi_age' {
    quietly ivreg2 infant_mortality (educ_years = $instruments) $controls ///
        if $sample & age_1994 <= `upper', cluster($cluster) partial($partial_vars $lang_dummies ///
		 Gambela SNNP Benishangul Somali Oromia Amhara Afar)
    matrix bw_res[`row',1] = `upper'
    matrix bw_res[`row',2] = _b[educ_years]
    matrix bw_res[`row',3] = _b[educ_years] - 1.96*_se[educ_years]
    matrix bw_res[`row',4] = _b[educ_years] + 1.96*_se[educ_years]
    local ++row
}

preserve
    clear
    svmat double bw_res
    rename (bw_res1 bw_res2 bw_res3 bw_res4) (bw_age bw_b bw_lo bw_hi)
    list, noobs

    twoway (rcap bw_lo bw_hi bw_age, lcolor(navy%60) lwidth(medium)) ///
           (connected bw_b bw_age, lcolor(navy) mcolor(navy) msymbol(O) lwidth(medthick)), ///
        yline(0, lpattern(dash) lcolor(gs10)) ///
        xline(28, lpattern(shortdash) lcolor(maroon) lwidth(thin)) ///
        xlabel(`lo_age'(1)`hi_age', labsize(small)) ///
        ylabel(, labsize(small) format(%4.3f)) ///
        xtitle("Maximum age of unexposed cohort included (age in 1994)", size(small)) ///
        ytitle("2SLS estimate: effect of maternal education", size(small)) ///
        graphregion(color(white)) bgcolor(white) legend(off) ysize(4) xsize(7)

    graph export "$figure/Figure2_bandwidth_sensitivity.png", replace width(2400) as(png)
restore

*==============================================================================
* End of TableS5_Figure2_sensitivity_analysis.do
*==============================================================================
