*==============================================================================
* TablesS6-S7_Figure3_exclusion_restriction.do
* Evidence on the exclusion restriction (the instrument affects infant
* mortality only through maternal education).
*
*   A. Does the instrument predict other characteristics that could affect
*      mortality? OLS of each outcome on the instruments, controlling for
*      maternal education and the baseline covariates.
*   B. Covariate balance between exposed and unexposed cohorts, conditional
*      on region fixed effects and age trends.
*   C. Bounds under a partial violation of the exclusion restriction
*      (plausibly exogenous inference, Conley, Hansen and Rossi 2012).
*        direct effect gamma of the exposure dummy in [-0.05, 0.05]
*
* Outputs: Table S6   output/tables/TableS6_exclusion_outcomes.xls   (A)
*          Table S7   output/tables/TableS7_covariate_balance.xlsx   (B)
*          Figure 3   output/figures/Figure3_exclusion_bounds.png    (C)
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

use "$maindata", clear

*------------------------------------------------------------------------------
* A. Instrument and other outcomes
*------------------------------------------------------------------------------
local outcomes husband_education age_at_cohabitation age_at_fbirth age_at_fsex ///
    rural_to_urban migrated_region poor

local first = 1
foreach lhs of local outcomes {
    quietly regress `lhs' $instruments educ_years $controls if $sample, ///
        vce(cluster cluster_id age_1994)
    quietly summarize `lhs' if e(sample)
    local mout = r(mean)

    local mode = cond(`first', "replace", "append")
    outreg2 using "$output/TableS6_exclusion_outcomes.xls", `mode' ///
        keep($instruments educ_years) bdec(3) adec(3) ///
        addstat(Avg. outcome, `mout') ///
        addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label
    local first = 0
}

*------------------------------------------------------------------------------
* B. Covariate balance (exposed vs unexposed, region fixed effects and age
*    trends as covariates)
*------------------------------------------------------------------------------
local balance_vars male_child Orthodox Protestant Muslim residence ///
    $lang_dummies num_sibs num_older_sibs sib_mortality_rate sib_death_before_mom15

iebaltab `balance_vars' if $sample, savexlsx("$output/TableS7_covariate_balance.xlsx") ///
    ftest grpvar(treat) rowvarlabels fixedeffect(region) ///
    covariates($region_trends treat_inter control_inter) replace

*------------------------------------------------------------------------------
* C. Plausibly exogenous bounds
*    The exposure dummy (treat) is the single excluded instrument; the two
*    age-trend terms enter as exogenous covariates. plausexog supports
*    one-way clustering only, so standard errors are clustered on cluster_id.
*------------------------------------------------------------------------------
local pe_controls treat_inter control_inter ///
    male_child age_head male_head hh_size Orthodox Protestant Muslim residence ///
    $lang_dummies $region_dummies $region_trends

plausexog uci infant_mortality (educ_years = treat) `pe_controls' ///
    if $sample, vce(cluster cluster_id) ///
    gmin(-0.05) gmax(0.05) grid(100) level(0.95) ///
    graph(educ_years) yline(0, lcolor(maroon) lwidth(medthick) lpattern(solid)) ///
    xtitle("Direct effect of reform exposure on infant mortality ({&gamma})") ///
    ytitle("IV estimate of education effect ({&beta})") title("") ///
    legend(order(1 "Upper bound (95% CI)" 2 "Lower bound (95% CI)") pos(6) row(1)) ///
    graphregion(color(white)) bgcolor(white)
graph export "$figure/Figure3_exclusion_bounds.png", as(png) replace

*==============================================================================
* End of TablesS6-S7_Figure3_exclusion_restriction.do
*==============================================================================
