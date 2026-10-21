*==============================================================================
* 00_config.do
* Paths, package installation and globals shared by every analysis file.
* Called once by master.do. Each analysis file also calls it when run
* standalone, provided $root has been set.
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) before running this file."
    exit 198
}

version 19
set more off
capture set maxvar 32767
set seed 20260101

*------------------------------------------------------------------------------
* Paths
*------------------------------------------------------------------------------
global code    "$root/code"
global raw     "$root/data/raw"
global derived "$root/data/derived"
global output  "$root/output/tables"
global figure  "$root/output/figures"
global logs    "$root/logs"

foreach d in derived output figure logs {
    capture mkdir "${`d'}"
}

* Raw input and derived analysis file
global dhs_ir  "$raw/ETIR71FL.DTA"
global maindata "$derived/main_analysis.dta"

*------------------------------------------------------------------------------
* Third-party packages
*------------------------------------------------------------------------------
foreach pkg in ivreg2 ranktest estout outreg2 coefplot plausexog ietoolkit {
    capture which `pkg'
    if _rc {
        capture noisily ssc install `pkg', replace
        if _rc {
            display as error "Could not install `pkg' from SSC; install it manually."
        }
    }
}

*------------------------------------------------------------------------------
* Shared specification globals
*   Baseline 2SLS: first-born infant mortality on maternal years of education,
*   instrumented by the cohort-exposure set; age-in-1994 trends are allowed to
*   differ by region and by side of the cutoff (age 7 in 1994).
*------------------------------------------------------------------------------

* Excluded instruments
global instruments  "treat treat_inter control_inter"

* Language dummies (Tigrigna, lang3, is the omitted category)
global lang_dummies "lang1 lang2 lang4 lang5 lang6 lang7 lang8 lang9 lang10"

* Region dummies (Tigray is the omitted category)
global region_dummies "Gambela SNNP Benishangul Somali Oromia Amhara Afar"

* Region-specific linear age trends
global region_trends "agediff_Afar agediff_Amhara agediff_Oromia agediff_Somali agediff_Benishangul agediff_SNNP agediff_Gambela"

* Variables absorbed with partial() in ivreg2 (must also be listed as regressors)
global partial_vars "$region_trends"

* Baseline covariates (second stage and first stage)
global controls ///
    male_child age_head male_head hh_size ///
    Orthodox Protestant Muslim residence ///
    $lang_dummies $region_dummies $region_trends

* Estimation sample: excludes the partially exposed cohort (age 8-14 in 1994),
* keeps the reform-implementing regions, requires non-missing first-born outcome
global sample "!inrange(age_1994,8,14) & RegionInMain==1 & fborn_deceased!=."

* Standard errors are clustered two-way: PSU-by-age-in-1994 cell (cluster_id)
* and age in 1994.
global cluster "cluster_id age_1994"

display as text "Configuration loaded. Root: $root"
*==============================================================================
* End of 00_config.do
*==============================================================================
