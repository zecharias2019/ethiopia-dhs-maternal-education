*==============================================================================
* Table1_summary_statistics.do
*
* Table 1: Summary statistics, main estimation sample.
*   Columns: Overall | Treatment (age <= 7 in 1994) | Control (age >= 15 in 1994)
*            each with mean and SD. Last row: number of observations.
*   Rows follow the order of Table 1 in the paper (Panels A to G).
*
* The estimation sample is the set of observations used by the baseline 2SLS
* regression (the partially exposed cohort, age 8-14 in 1994, is excluded).
*
* Output: output/tables/Table1_summary_statistics.xlsx
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

use "$maindata", clear

*------------------------------------------------------------------------------
* Sample counts quoted in the text
*------------------------------------------------------------------------------
gen hhid = substr(caseid,1,12)
egen tag_hh = tag(hhid)
count                                       // all women
count if tag_hh                             // households
count if RegionInMain == 1 & v201 != 0      // women with births, reform regions

*------------------------------------------------------------------------------
* Mark the estimation sample (observations used by the main 2SLS regression)
*------------------------------------------------------------------------------
quietly ivreg2 infant_mortality (educ_years = $instruments) $controls ///
    if $sample, cluster($cluster) partial($partial_vars)
gen byte in_sample = e(sample)
count if in_sample
display as text "Main estimation sample: " r(N)

*------------------------------------------------------------------------------
* Table 1
*------------------------------------------------------------------------------
tempname P
tempfile T1
postfile `P' str60 Variable double(All_Mean All_SD Treat_Mean Treat_SD Control_Mean Control_SD) ///
    using `T1'

capture program drop t1row
program define t1row
    args P label var
    local i = 0
    foreach cond in "in_sample" "in_sample & age_1994 <= 7" "in_sample & age_1994 >= 15" {
        local ++i
        quietly summarize `var' if `cond'
        local m`i' = r(mean)
        local s`i' = r(sd)
    }
    post `P' ("`label'") (`m1') (`s1') (`m2') (`s2') (`m3') (`s3')
end

capture program drop t1panel
program define t1panel
    args P label
    post `P' ("`label'") (.) (.) (.) (.) (.) (.)
end

t1panel `P' "PANEL A: Primary outcomes"
t1row   `P' "Infant mortality (death <12 months)"            infant_mortality
t1row   `P' "Neonatal mortality (death at month 0)"          neonatal_mort
t1row   `P' "Post-neonatal mortality (deaths months 1-11)"   postneonatal_mort

t1panel `P' "PANEL B: Education"
t1row   `P' "Maternal years of education"                    educ_years
t1row   `P' "Ever attended school"                           s107

t1panel `P' "PANEL C: Child characteristics"
t1row   `P' "Child sex (male)"                               male_child

t1panel `P' "PANEL D: Household characteristics"
t1row   `P' "Age of household head"                          age_head
t1row   `P' "Household head sex (male)"                      male_head
t1row   `P' "Household size"                                 hh_size

t1panel `P' "PANEL E: Religion"
t1row   `P' "Orthodox Christian"                             Orthodox
t1row   `P' "Protestant Christian"                           Protestant
t1row   `P' "Islam"                                          Muslim

t1panel `P' "PANEL F: Residence and region"
t1row   `P' "Rural resident"                                 residence
t1row   `P' "Afar"                                           Afar
t1row   `P' "Amhara"                                         Amhara
t1row   `P' "Oromia"                                         Oromia
t1row   `P' "Somali"                                         Somali
t1row   `P' "Benishangul-Gumuz"                              Benishangul
t1row   `P' "SNNPR"                                          SNNP
t1row   `P' "Gambela"                                        Gambela

* Language order follows $lang_dummies (Tigrigna, lang3, is the omitted category).
t1panel `P' "PANEL G: Native language"
t1row   `P' "Amarigna"                                       lang1
t1row   `P' "Oromigna"                                       lang2
t1row   `P' "Somaligna"                                      lang4
t1row   `P' "Afarigna"                                       lang5
t1row   `P' "Sidamigna"                                      lang6
t1row   `P' "Nuwerigna / Gambeligna"                         lang7
t1row   `P' "Gumuzigna / Bangagna"                           lang8
t1row   `P' "Agnwakigna"                                     lang9
t1row   `P' "Other language"                                 lang10

quietly count if in_sample
local n_all = r(N)
quietly count if in_sample & age_1994 <= 7
local n_t = r(N)
quietly count if in_sample & age_1994 >= 15
local n_c = r(N)
post `P' ("Observations") (`n_all') (.) (`n_t') (.) (`n_c') (.)

postclose `P'

preserve
    use `T1', clear
    format All_Mean All_SD Treat_Mean Treat_SD Control_Mean Control_SD %9.3f
    list, noobs sep(0)
    export excel using "$output/Table1_summary_statistics.xlsx", replace firstrow(variables)
restore

*==============================================================================
* End of Table1_summary_statistics.do
*==============================================================================
