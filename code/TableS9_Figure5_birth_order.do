*==============================================================================
* TableS9_Figure5_birth_order.do
* All-births analysis and heterogeneity by birth order.
*
* The DHS birth history is reshaped from one row per mother to one row per
* birth. Each birth carries the mother's education, exposure and controls.
* Standard errors are clustered by PSU-by-age-in-1994 cell and by age in 1994.
*
*   (1) all births, with birth-order dummies
*   (2) first-born only
*   (3)-(5) separate estimates for second, third and fourth-or-higher births
* Figure 5 plots the all-births estimate and the four birth-order estimates.
*
* Outputs: output/tables/TableS9_birth_order.xls
*          output/figures/Figure5_birth_order.png
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

*------------------------------------------------------------------------------
* Step 1: reshape to one row per birth
*   Child birth years (b2_*) are already converted to the Gregorian calendar
*   in 01_build_analysis_data.do.
*------------------------------------------------------------------------------
use "$maindata", clear

local keepvars treat treat_inter control_inter educ_years ///
    age_1994 RegionInMain cluster_id age_head male_head hh_size Orthodox ///
    Protestant Muslim residence $lang_dummies $region_dummies $region_trends

tempfile long_data
local first_slot = 1
forvalues slot = 1/14 {
    capture confirm variable bord_`slot'
    if _rc continue

    preserve
    keep if !missing(bord_`slot')

    gen birth_order = bord_`slot'

    gen infant_mortality_b = 0
    replace infant_mortality_b = 1 if b5_`slot' == 0 & b7_`slot' <= 11
    replace infant_mortality_b = . if missing(b5_`slot')
    replace infant_mortality_b = . if b5_`slot' == 0 & missing(b7_`slot')

    gen neonatal_mortality_b = 0
    replace neonatal_mortality_b = 1 if b5_`slot' == 0 & b7_`slot' == 0
    replace neonatal_mortality_b = . if missing(b5_`slot')
    replace neonatal_mortality_b = . if b5_`slot' == 0 & missing(b7_`slot')

    gen postneonatal_mortality_b = 0
    replace postneonatal_mortality_b = 1 if b5_`slot' == 0 & inrange(b7_`slot',1,11)
    replace postneonatal_mortality_b = . if missing(b5_`slot')
    replace postneonatal_mortality_b = . if b5_`slot' == 0 & missing(b7_`slot')

    label var birth_order            "Birth order of this child"
    label var infant_mortality_b     "Infant mortality (death <12 months)"
    label var neonatal_mortality_b   "Neonatal mortality (death at month 0)"
    label var postneonatal_mortality_b "Post-neonatal mortality (months 1-11)"

    keep `keepvars' birth_order infant_mortality_b neonatal_mortality_b postneonatal_mortality_b

    if `first_slot' == 1 {
        save `long_data'
        local first_slot = 0
    }
    else {
        append using `long_data'
        save `long_data', replace
    }
    restore
}

use `long_data', clear

gen bo_2nd   = (birth_order == 2)
gen bo_3rd   = (birth_order == 3)
gen bo_4plus = (birth_order >= 4) if !missing(birth_order)
label var bo_2nd   "Second birth"
label var bo_3rd   "Third birth"
label var bo_4plus "Fourth or higher birth"

local sample "!inrange(age_1994,8,14) & RegionInMain==1 & !missing(infant_mortality_b)"
local ctr    "age_head male_head hh_size Orthodox Protestant Muslim residence $lang_dummies $region_dummies $region_trends"

display as text "Birth observations in the estimation sample by birth order:"
tab birth_order if `sample'

*------------------------------------------------------------------------------
* Step 2: estimates
*------------------------------------------------------------------------------
* (1) All births, birth-order dummies
quietly ivreg2 infant_mortality_b (educ_years = $instruments) ///
    bo_2nd bo_3rd bo_4plus `ctr' if `sample', ///
    cluster($cluster) partial($partial_vars $lang_dummies) ffirst
local kp  = trim("`: display %9.2f e(widstat)'")
local arp = trim("`: display %9.4f e(archi2p)'")
display as text "All births 2SLS: " _b[educ_years] "  KP F: `kp'  N: " e(N)
local b_all  = _b[educ_years]
local lo_all = _b[educ_years] - 1.96*_se[educ_years]
local hi_all = _b[educ_years] + 1.96*_se[educ_years]
quietly summarize infant_mortality_b if e(sample)
local mean_c = trim("`: display %9.4f r(mean)'")

outreg2 using "$output/TableS9_birth_order.xls", replace bdec(3) adec(3) ///
    ctitle("(1) All births") keep(educ_years) ///
    addstat(KP F-stat, `kp', AR p-value, `arp', Avg. outcome, `mean_c') ///
    addtext(Birth order controls, YES, Controls, YES, Region x age trends, YES) ///
    nor2 noni nocons label

* (2)-(5) First-born benchmark and by birth order. Matrix row 1 holds the
* all-births estimate used in the figure, rows 2-5 the birth-order estimates.
matrix bo_res = J(5, 3, .)
matrix bo_res[1,1] = `b_all'
matrix bo_res[1,2] = `lo_all'
matrix bo_res[1,3] = `hi_all'
local col = 2
foreach spec in "1|First-born only|birth_order==1" ///
                "2|Second-born|birth_order==2" ///
                "3|Third-born|birth_order==3" ///
                "4|Fourth+|birth_order>=4" {

    tokenize "`spec'", parse("|")
    local key  "`1'"
    local lab  "`3'"
    local cond "`5'"

    capture noisily ivreg2 infant_mortality_b (educ_years = $instruments) ///
        `ctr' if `sample' & `cond', cluster($cluster) ///
		partial($partial_vars $lang_dummies) ffirst
    if _rc {
        display as error "Specification failed for `lab'"
        local ++col
        continue
    }
    local kp  = trim("`: display %9.2f e(widstat)'")
    local arp = trim("`: display %9.4f e(archi2p)'")
    display as text "`lab': 2SLS = " _b[educ_years] "  KP F = `kp'  N = " e(N)

    matrix bo_res[`=`key'+1',1] = _b[educ_years]
    matrix bo_res[`=`key'+1',2] = _b[educ_years] - 1.96*_se[educ_years]
    matrix bo_res[`=`key'+1',3] = _b[educ_years] + 1.96*_se[educ_years]
    quietly summarize infant_mortality_b if e(sample)
    local mean_c = trim("`: display %9.4f r(mean)'")

    outreg2 using "$output/TableS9_birth_order.xls", append bdec(3) adec(3) ///
        ctitle("(`col') `lab'") keep(educ_years) ///
        addstat(KP F-stat, `kp', AR p-value, `arp', Avg. outcome, `mean_c') ///
        addtext(Birth order controls, NO, Controls, YES, Region x age trends, YES) ///
        nor2 noni nocons label
    local ++col
}

*------------------------------------------------------------------------------
* Step 3: Figure 5, coefficient plot (all births, then by birth order)
*------------------------------------------------------------------------------
preserve
    clear
    svmat double bo_res
    rename (bo_res1 bo_res2 bo_res3) (bo_coef bo_lo bo_hi)
    gen bo_x = _n

        twoway (rcap bo_hi bo_lo bo_x, lcolor(navy) lwidth(medthick)) ///
           (line bo_coef bo_x if bo_x > 1, lcolor(navy) lpattern(solid)) ///
           (scatter bo_coef bo_x if bo_x > 1, mcolor(navy) msize(medium) msymbol(circle)) ///
           (scatter bo_coef bo_x if bo_x == 1, mcolor(maroon) msize(medlarge) msymbol(diamond)), ///
        yline(0, lcolor(gs10) lpattern(dash)) ///
        xline(1.5, lcolor(gs12) lpattern(shortdash)) ///
        xlabel(1 "All births" 2 "First" 3 "Second" 4 "Third" 5 "Fourth+", labsize(medium)) ///
        ylabel(, labsize(medium)) ///
        ytitle("2SLS coefficient (years of education)", size(medium)) ///
        xtitle("Birth order", size(medium)) legend(off) ///
        graphregion(color(white)) plotregion(color(white)) ///
        note("", size(small))
    graph export "$figure/Figure5_birth_order.png", replace width(2400)
restore

*==============================================================================
* End of TableS9_Figure5_birth_order.do
*==============================================================================
