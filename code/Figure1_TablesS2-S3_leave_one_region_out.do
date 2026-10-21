*==============================================================================
* Figure1_TablesS2-S3_leave_one_region_out.do
* Leave-one-region-out robustness: re-estimates the first stage and the 2SLS
* dropping each reform region in turn.
*   Figure 1: first-stage coefficient on the exposure dummy (treat)
*   Table S2: first stage for each omitted region
*   Table S3: 2SLS for each omitted region
* Region codes (v024): 1 Tigray, 2 Afar, 3 Amhara, 4 Oromia, 5 Somali,
*   6 Benishangul-Gumuz, 7 SNNP, 8 Gambela.
* When a region is omitted its dummy and age trend are dropped from the
* controls. If Tigray (the omitted baseline) is dropped, the Afar dummy and
* trend are dropped instead so that the controls remain identified.
* Outputs: output/figures/Figure1_leave_one_out_first_stage.png
*          output/tables/TableS2_leave_one_out_first_stage.xls
*          output/tables/TableS3_leave_one_out_2sls.xls
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

use "$maindata", clear

local rname1 "Tigray"
local rname2 "Afar"
local rname3 "Amhara"
local rname4 "Oromia"
local rname5 "Somali"
local rname6 "Benishangul"
local rname7 "SNNP"
local rname8 "Gambela"

local cond "RegionInMain==1 & !inrange(age_1994,8,14) & fborn_deceased!=."

eststo clear

forvalues r = 1/8 {
    local dropnm = cond(`r' == 1, "Afar", "`rname`r''")
    local dums "$region_dummies"
    local dums : list dums - dropnm
    local trs ""
    foreach d of local dums {
        local trs `trs' agediff_`d'
    }

    quietly ivreg2 infant_mortality (educ_years = $instruments) ///
        male_child age_head male_head hh_size Orthodox Protestant Muslim residence ///
        $lang_dummies `dums' `trs' if `cond' & region != `r', ///
        cluster($cluster) first ffirst savefirst savefprefix(loo`r') ///
        partial(`trs')

    local kp   = trim("`: display %9.2f e(widstat)'")
    local arp  = trim("`: display %9.4f e(archi2p)'")
    quietly summarize infant_mortality if e(sample)
    local mout = trim("`: display %9.4f r(mean)'")
    quietly summarize educ_years if e(sample)
    local mfs  = trim("`: display %9.4f r(mean)'")

    local mode = cond(`r' == 1, "replace", "append")

    * 2SLS column (active estimates are still the 2SLS)
    outreg2 using "$output/TableS3_leave_one_out_2sls.xls", `mode' bdec(3) adec(3) ///
        ctitle("Omit `rname`r'': 2SLS") keep(educ_years) ///
        addstat(KP rk Wald F, `kp', AR test p-value, `arp', Avg. outcome, `mout') ///
        addtext(Controls, YES) nor2 noni nocons label

    * First-stage column
    estimates restore loo`r'educ_years
    eststo drop_r`r'
    outreg2 using "$output/TableS2_leave_one_out_first_stage.xls", `mode' bdec(3) adec(3) ///
        ctitle("Omit `rname`r'': FS") keep($instruments) ///
        addstat(KP rk Wald F, `kp', Avg. outcome, `mfs') ///
        addtext(Controls, YES) nor2 noni nocons label
}

* Full sample first stage (reference line)
quietly ivreg2 infant_mortality (educ_years = $instruments) $controls if `cond', ///
    cluster($cluster) first savefirst savefprefix(loofull) partial($partial_vars)
estimates restore loofulleduc_years
eststo full
scalar b_full = _b[treat]

*------------------------------------------------------------------------------
* Figure: first-stage coefficient on the exposure dummy
*------------------------------------------------------------------------------
coefplot ///
    (full,    rename(treat = "Full sample") msymbol(D) mcolor("31 119 180") msize(large)) ///
    (drop_r8, rename(treat = "Omit Gambela")) ///
    (drop_r7, rename(treat = "Omit SNNPR")) ///
    (drop_r6, rename(treat = "Omit Benishangul")) ///
    (drop_r5, rename(treat = "Omit Somali")) ///
    (drop_r4, rename(treat = "Omit Oromia")) ///
    (drop_r3, rename(treat = "Omit Amhara")) ///
    (drop_r2, rename(treat = "Omit Afar")) ///
    (drop_r1, rename(treat = "Omit Tigray")) ///
    , keep(treat) ///
    xline(`=b_full', lpattern(dash) lcolor("31 119 180") lwidth(medium)) ///
    ciopts(recast(rcap) lwidth(medium)) mcolor("50 50 50") msize(medium) msymbol(O) ///
    title("First-stage robustness: leave-one-region-out", size(medsmall) color(black)) ///
    subtitle("IV: Exposed cohort (age {&le}7 in 1994)", size(small) color(gs6)) ///
    xtitle("First-stage coefficient on exposure dummy", size(small)) ///
    xlabel(0(0.25)1.5, format(%4.2f) labsize(small)) ysize(4) xsize(6) ///
    plotregion(margin(medium) fcolor(white) lcolor(white)) ///
    graphregion(color(white)) legend(off) scheme(s2mono)

graph export "$figure/Figure1_leave_one_out_first_stage.png", replace width(2400) as(png)

*==============================================================================
* End of Figure1_TablesS2-S3_leave_one_region_out.do
*==============================================================================
