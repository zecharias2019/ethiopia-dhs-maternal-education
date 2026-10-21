*==============================================================================
* TableS1_hansenJ_tests.do
* Table S1. Hansen J overidentification tests.
*
* The model has one endogenous regressor (years of education) and three
* excluded instruments (treat, treat_inter, control_inter), so the test has
* two degrees of freedom. Rows:
*   1  Preferred sample (partially exposed cohort, age 8-14 in 1994, excluded)
*   2  Including the partially exposed cohorts
*   3  Neonatal mortality (preferred sample)
*   4  Post-neonatal mortality (preferred sample)
* Columns: 2SLS estimate | KP F | Hansen J | p-value
*
* Output: output/tables/TableS1_hansenJ_tests.xlsx
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

use "$maindata", clear

tempname P
tempfile HJ
postfile `P' str60 Specification double(coef kpf hansenJ df p) using `HJ'

local sample_incl "RegionInMain==1 & fborn_deceased!=."

local i = 0
foreach spec in "Preferred sample|infant_mortality|$sample" ///
                "Including partially exposed cohorts|infant_mortality|`sample_incl'" ///
                "Neonatal mortality|neonatal_mort|$sample" ///
                "Post-neonatal mortality|postneonatal_mort|$sample" {

    tokenize `"`spec'"', parse("|")
    local lab  "`1'"
    local yvar "`3'"
    local cond "`5'"

    quietly ivreg2 `yvar' (educ_years = $instruments) $controls if `cond', ///
        cluster($cluster) partial($partial_vars)

    post `P' ("`lab'") (_b[educ_years]) (e(widstat)) (e(j)) (e(jdf)) (e(jp))
}
postclose `P'

preserve
    use `HJ', clear
    format coef kpf hansenJ p %9.3f
    format df %9.0f
    list, noobs sep(0)
    export excel using "$output/TableS1_hansenJ_tests.xlsx", replace firstrow(variables)
restore

*==============================================================================
* End of TableS1_hansenJ_tests.do
*==============================================================================
