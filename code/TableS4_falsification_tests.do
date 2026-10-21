*==============================================================================
* TableS4_falsification_tests.do
* Table S1. Falsification tests (first stage only).
*   Column 1  Placebo cutoff: only women aged 15 or older in 1994 (already
*             past school age at the reform) in the reform regions, with a
*             fake exposure cutoff at age 19 (median age of this group).
*   Column 2  Placebo geography: the real instrument applied to the
*             non-reform regions (Harari and Addis Ababa), with the partially
*             exposed cohort (age 8-14) excluded. Dire Dawa (region code 11
*             in 2016) is left out so that the placebo sample contains only
*             regions without reform implementation. Available reports
*             indicate at most grade-limited implementation in Dire Dawa,
*             concentrated in early grades.
* Under a valid design neither instrument set should have first-stage power;
* the Kleibergen-Paap F statistic is the primary diagnostic.
* Output: output/tables/TableS4_falsification_tests.xls
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

*------------------------------------------------------------------------------
* Column 1: placebo cutoff at age 19 among unexposed cohorts
*------------------------------------------------------------------------------
use "$maindata", clear
keep if age_1994 >= 15

gen placebo_treat         = (age_1994 <= 19)
gen placebo_control       = (age_1994 >= 20)
gen placebo_agediff       = age_1994 - 19
gen placebo_treat_inter   = placebo_treat   * placebo_agediff
gen placebo_control_inter = placebo_control * placebo_agediff
label variable placebo_treat         "Placebo cohort (age <=19 in 1994)"
label variable placebo_treat_inter   "Age (centred) x Placebo cohort"
label variable placebo_control_inter "Age (centred) x Placebo control cohort"

quietly ivreg2 infant_mortality ///
    (educ_years = placebo_treat placebo_treat_inter placebo_control_inter) ///
    $controls if RegionInMain==1, cluster($cluster) ///
    first ffirst savefirst savefprefix(plac1) ///
    partial($lang_dummies $region_dummies $region_trends)

scalar kpf_plac1 = e(widstat)
quietly summarize educ_years if e(sample)
local mfs_plac1 = r(mean)

estimates restore plac1educ_years
outreg2 using "$output/TableS4_falsification_tests.xls", replace bdec(3) adec(3) ///
    ctitle("(1)" "Placebo instrument" "Unexposed cohorts") ///
    keep(placebo_treat placebo_treat_inter placebo_control_inter) ///
    addstat(KP rk Wald F, kpf_plac1, Avg. outcome, `mfs_plac1') ///
    addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label

*------------------------------------------------------------------------------
* Column 2: real instrument in non-reform regions
*------------------------------------------------------------------------------
use "$maindata", clear
keep if RegionInMain == 0 & region != 11

label variable treat         "Exposed cohort (<=7 in 1994)"
label variable treat_inter   "Age (centred) x Exposed cohort"
label variable control_inter "Age (centred) x Unexposed cohort"

* Controls: language dummies present in these regions, the Addis Ababa
* indicator (Harari is the omitted region) and its age trend
quietly ivreg2 infant_mortality (educ_years = $instruments) ///
    male_child age_head male_head hh_size Orthodox Protestant Muslim residence ///
    lang1 lang2 lang4 lang5 lang6 lang9 lang10 ///
    Addis_Ababa agediff_Addis_Ababa ///
    if !inrange(age_1994,8,14), cluster($cluster) ///
    first ffirst savefirst savefprefix(plac2) partial(agediff_Addis_Ababa)

scalar kpf_plac2 = e(widstat)
quietly summarize educ_years if e(sample)
local mfs_plac2 = r(mean)

estimates restore plac2educ_years
outreg2 using "$output/TableS4_falsification_tests.xls", append bdec(3) adec(3) ///
    ctitle("(2)" "Placebo geography" "Non-reform regions") ///
    keep($instruments) ///
    addstat(KP rk Wald F, kpf_plac2, Avg. outcome, `mfs_plac2') ///
    addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label

*==============================================================================
* End of TableS1_falsification_tests.do
*==============================================================================
