*==============================================================================
* 01_build_analysis_data.do
* Builds data/derived/main_analysis.dta from the raw 2016 Ethiopia DHS
* Individual Recode file (ETIR71FL.DTA).
*
* Sections
*   A. Dates: Ethiopian -> Gregorian calendar, age in 1994, instruments
*   B. Maternal characteristics, education, mechanism outcomes
*   C. Controls: religion, residence, region, region-specific age trends
*   D. Birth history: first-born outcomes (infant, neonatal, post-neonatal)
*   E. Prenatal care (most recent birth)
*   F. Language groups, quadratic age terms, sample indicator, clusters
*   G. Sibling history (maternal-mortality module)
*
* DHS dates in Ethiopia are recorded in the Ethiopian calendar. The Ethiopian
* year lags the Gregorian year by 7 years for Ethiopian months 1-4 (roughly
* September-December) and by 8 years for months 5-12; the conversions below
* add 7 or 8 years accordingly. Conversions are applied once, here.
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$dhs_ir" == "" do "$root/code/00_config.do"

use "$dhs_ir", clear

*------------------------------------------------------------------------------
* A. Dates, age in 1994 and instruments
*------------------------------------------------------------------------------
* Mother's birth year, Gregorian
gen women_bm = v009
gen women_by = v010
replace women_by = women_by + 7 if inlist(women_bm,1,2,3,4)
replace women_by = women_by + 8 if inlist(women_bm,5,6,7,8,9,10,11,12)

* Age in 1994, the year of the language-of-instruction reform
gen age_1994 = 1994 - women_by
label var age_1994 "Age in 1994"

* Exposure: age 7 or younger in 1994; cutoff-centred age and age trends
gen agediff = age_1994 - 7
gen treat = age_1994 <= 7
label var treat "Exposed cohort (<=7 in 1994)"
gen treat_inter   = treat*agediff
gen control_inter = (1 - treat)*agediff
label var treat_inter   "Age (centred) x Exposed cohort"
label var control_inter "Age (centred) x Unexposed cohort"

*------------------------------------------------------------------------------
* B. Maternal characteristics and mechanism outcomes
*------------------------------------------------------------------------------
gen married_bywill = (s711a == 1) if s711a != .
label var married_bywill "Married by will"

gen age_at_cohabitation = v511
label var age_at_cohabitation "Age at first cohabitation"
gen age_at_fbirth = v212
label var age_at_fbirth "Age at first birth"
gen age_at_fsex = v525
label var age_at_fsex "Age at first sex"

* Endogenous regressor: total single years of education (v133)
clonevar educ_years = v133
label var educ_years "Maternal years of education"

gen rural_to_urban = (v105 == 2 & v102 == 1)
label var rural_to_urban "Migration to urban"
gen migrated_region = !missing(v105a)
label var migrated_region "Interregional migration"
gen poor = v190 <= 2
label var poor "Household wealth: poor"

* Empowerment and household decision-making
* (1 = respondent alone or jointly with husband)
gen dec_health_involved = inlist(v743a,1,2)
label var dec_health_involved "Respondent involved in decision on own healthcare"
gen dec_purchase_involved = inlist(v743b,1,2)
label var dec_purchase_involved "Respondent involved in decision on large household purchases"
gen dec_own_earn_involved = inlist(v739,1,2)
label var dec_own_earn_involved "Respondent involved in decision on own earnings"
gen dec_hus_earn_involved = inlist(v743f,1,2)
label var dec_hus_earn_involved "Respondent decides on husband's earnings"

gen HigherEduc = (v701 == 3) if v701 != 8
label var HigherEduc "Husband has higher education"
gen perm_NonProblem = (v467b == 2)
label var perm_NonProblem "Permission to seek medical help not a big problem"
gen money_NonProblem = (v467c == 2)
label var money_NonProblem "Money for medical treatment not a big problem"
gen husband_supports = (s924a == 1) if s924a != 3
label var husband_supports "Husband helps with household chores"

gen children_ever_born = v201
label var children_ever_born "# children ever born"
gen high_parity = (children_ever_born >= 4)
label var high_parity "High parity (4+ births)"

gen husband_education = (v701 >= 1) if v701 != 8 & v701 != .
label var husband_education ">=Primary school (husband)"
gen hc_use = v394
label var hc_use "Used healthcare"
gen insured = v481
label var insured "Has health insurance"
gen modern_contraception = (v313 == 3)
label var modern_contraception "Uses modern contraception"

* Overweight or obese (BMI >= 25), non-pregnant women
gen nt_wm_ovobese = inrange(v445,2500,6000) if inrange(v445,1200,6000)
replace nt_wm_ovobese = . if v213 == 1
label var nt_wm_ovobese "Overweight or obese"

*------------------------------------------------------------------------------
* C. Controls
*------------------------------------------------------------------------------
recode v130 (1=1 "Orthodox") (3=2 "Protestant") (4=3 "Muslim") (2 5 96=4 "other"), gen(religion)
gen Orthodox   = religion == 1
gen Protestant = religion == 2
gen Muslim     = religion == 3
label var Orthodox   "Orthodox Christian"
label var Protestant "Protestant Christian"
label var Muslim     "Muslim"

* residence = 1 for RURAL, 0 for urban (v025: 1 urban, 2 rural)
gen residence = v025 == 2
label var residence "Rural resident"

rename (v152 v024) (age_head region)

gen male_head = (v151 == 1)
label var male_head "Household head is male"
label var age_head "Age of household head"
clonevar hh_size = v136
label var hh_size "Household size"

* Region indicators from v139 (2016 coding)
gen Addis_Ababa    = v139 == 10
gen Gambela        = v139 == 8
gen SNNP           = v139 == 7
gen Benishangul    = v139 == 6
gen Somali         = v139 == 5
gen Oromia         = v139 == 4
gen Amhara         = v139 == 3
gen Afar           = v139 == 2

* Region-specific linear age trends
foreach r in Addis_Ababa Gambela SNNP Benishangul Somali Oromia Amhara Afar {
    gen agediff_`r' = agediff * `r'
}

*------------------------------------------------------------------------------
* D. Birth history: first-born outcomes
*------------------------------------------------------------------------------
* Drop the leading zero from slot suffixes 01-09 (slots 10-20 are unpadded)
foreach num in 1 2 3 4 5 6 7 8 9 {
    foreach stub in b5 bord b4 b2 b1 b7 b6 {
        rename `stub'_0`num' `stub'_`num'
    }
}

* Child birth year, Gregorian (applied once here; do not repeat downstream)
forvalues i = 1/20 {
    replace b2_`i' = b2_`i' + 7 if inlist(b1_`i',1,2,3,4)
    replace b2_`i' = b2_`i' + 8 if inlist(b1_`i',5,6,7,8,9,10,11,12)
}

gen child_sex = .
gen age_at_death = .
forvalues i = 1/20 {
    replace child_sex    = b4_`i' if bord_`i' == 1
    replace age_at_death = b7_`i' if bord_`i' == 1      // months
}
gen male_child = child_sex == 1
label var male_child "Child sex (male)"

* Survival status of the first-born (b5: 1 alive, 0 dead)
gen fborn_deceased = .
forvalues i = 1/20 {
    replace fborn_deceased = 1 if b5_`i' == 0 & bord_`i' == 1
    replace fborn_deceased = 0 if b5_`i' == 1 & bord_`i' == 1
}
label var fborn_deceased "First child died"

* Mortality outcomes. All three are set to missing when the child is deceased
* but age at death is missing, so that
*   infant_mortality = neonatal_mort + postneonatal_mort
* holds on a common sample.
gen infant_mortality = 0
replace infant_mortality = 1 if fborn_deceased == 1 & age_at_death <= 11
replace infant_mortality = . if missing(fborn_deceased)
replace infant_mortality = . if fborn_deceased == 1 & missing(age_at_death)
label var infant_mortality "Infant mortality (death <12 months)"

* Neonatal: death in month 0 (DHS b7 = 0 means died before completing one month)
gen neonatal_mort = (age_at_death == 0) if fborn_deceased != .
replace neonatal_mort = . if fborn_deceased == 1 & missing(age_at_death)
label var neonatal_mort "Neonatal mortality (death at month 0)"

* Post-neonatal: death in months 1-11
gen postneonatal_mort = (age_at_death >= 1 & age_at_death <= 11) if fborn_deceased != .
replace postneonatal_mort = . if fborn_deceased == 1 & missing(age_at_death)
label var postneonatal_mort "Post-neonatal mortality (death months 1-11)"

*------------------------------------------------------------------------------
* E. Prenatal care with a doctor, most recent birth (m2a_1)
*------------------------------------------------------------------------------
gen prenatal_doc_recent = .
replace prenatal_doc_recent = 1 if m2a_1 == 1
replace prenatal_doc_recent = 0 if m2a_1 == 0
label var prenatal_doc_recent "Prenatal care with doctor (most recent birth)"

*------------------------------------------------------------------------------
* F. Language groups, quadratic age terms, sample indicator, clusters
*------------------------------------------------------------------------------
gen native_lang_group = .
replace native_lang_group = 1  if v045c == 2    // Amarigna
replace native_lang_group = 2  if v045c == 4    // Oromigna
replace native_lang_group = 3  if v045c == 3    // Tigrigna
replace native_lang_group = 4  if v045c == 7    // Somaligna
replace native_lang_group = 5  if v045c == 6    // Afarigna
replace native_lang_group = 6  if v045c == 12   // Sidamigna
replace native_lang_group = 7  if v045c == 19   // Nuwerigna/Gambeligna
replace native_lang_group = 8  if v045c == 22   // Gumuzigna/Bangagna
replace native_lang_group = 9  if v045c == 18   // Agnwakigna
replace native_lang_group = 10 if !inlist(v045c,2,4,3,7,6,12,19,22,18)
label define lang_group_lbl 1 "Amarigna" 2 "Oromigna" 3 "Tigrigna" 4 "Somaligna" ///
    5 "Afarigna" 6 "Sidamigna" 7 "Nuwerigna/Gambeligna" 8 "Gumuzigna/Bangagna" ///
    9 "Agnwakigna" 10 "Other"
label values native_lang_group lang_group_lbl
tabulate native_lang_group, generate(lang)
label var lang1  "Native language: Amarigna"
label var lang2  "Native language: Oromigna"
label var lang3  "Native language: Tigrigna"
label var lang4  "Native language: Somaligna"
label var lang5  "Native language: Afarigna"
label var lang6  "Native language: Sidamigna"
label var lang7  "Native language: Nuwerigna/Gambeligna"
label var lang8  "Native language: Gumuzigna/Bangagna"
label var lang9  "Native language: Agnwakigna"
label var lang10 "Native language: Other"

* Quadratic age trends (functional-form sensitivity, Table S2)
gen age2Xtreat   = agediff^2*treat
gen age2Xcontrol = agediff^2*(1 - treat)
label var age2Xtreat   "Age^2 x Exposed cohort"
label var age2Xcontrol "Age^2 x Unexposed cohort"

* Reform-implementing regions: Tigray, Afar, Amhara, Oromia, Somali,
* Benishangul-Gumuz, SNNP, Gambela
gen RegionInMain = inlist(v139,1,2,3,4,5,6,7,8)
label var RegionInMain "Region included in main analysis (reform regions)"

* PSU-by-age-in-1994 cell, first dimension of $cluster
egen cluster_id = group(age_1994 v021)

*------------------------------------------------------------------------------
* G. Sibling history (maternal-mortality module)
*------------------------------------------------------------------------------
foreach num in 1 2 3 4 5 6 7 8 9 {
    foreach stub in mm7 mm8 mm2 {
        rename `stub'_0`num' `stub'_`num'
    }
}

gen num_sibs = mmc1
label var num_sibs "Number of siblings"
gen num_older_sibs = mmc2
label var num_older_sibs "Number of siblings born before respondent"

* Sibling deaths and survivors (mm2: 0 dead, 1 alive, 8 don't know)
forvalues i = 1/20 {
    gen dum_mm2_`i' = mm2_`i' == 0
    replace dum_mm2_`i' = . if mm2_`i' == 8
}
egen sib_death_count = rowtotal(dum_mm2_*)
drop dum_mm2_*

forvalues i = 1/20 {
    gen dum_mm2_`i' = mm2_`i' == 1
    replace dum_mm2_`i' = . if mm2_`i' == 8
}
egen sib_alive_count = rowtotal(dum_mm2_*)
drop dum_mm2_*

gen sib_mortality_rate = sib_death_count/sib_alive_count
label var sib_mortality_rate "Sibling mortality rate (deaths / alive)"

* Sibling death before the respondent was 15 (mm8 and v011 are century-month codes)
forvalues i = 1/20 {
    gen dum_mm8_`i' = mm8_`i' > 0 & mm8_`i' < (v011 + 15*12)
}
egen tot = rowtotal(dum_mm8_*)
gen sib_death_before_mom15 = tot > 0
drop dum_mm8_* tot
label var sib_death_before_mom15 "Any sibling death before respondent age 15"

*------------------------------------------------------------------------------
* Integrity checks and save
*------------------------------------------------------------------------------
assert _N == 15683
assert neonatal_mort + postneonatal_mort == infant_mortality if !missing(infant_mortality)
quietly count if !missing(infant_mortality)
display as text "Non-missing first-born infant mortality: " r(N)

* Drop intermediate variables that no analysis file uses
drop women_bm women_by agediff child_sex age_at_death native_lang_group ///
    sib_death_count sib_alive_count

compress
save "$maindata", replace

*==============================================================================
* End of 01_build_analysis_data.do
*==============================================================================
