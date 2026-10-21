*==============================================================================
* TableS10_Figure6_heterogeneity.do
* Table S10 and Figure 6. Heterogeneity of the 2SLS effect by child sex, mother's residence and
* household wealth. Same specification as the baseline, estimated separately
* within each subgroup; the splitting variable is dropped from the controls.
*   residence = 1 for rural, 0 for urban (see 01_build_analysis_data.do)
*   poor      = 1 if household wealth quintile is 1 or 2
* Outputs: output/tables/TableS10_heterogeneity.xls
*          output/figures/Figure6_heterogeneity.png
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

use "$maindata", clear

local c_nosex age_head male_head hh_size Orthodox Protestant Muslim residence ///
    $lang_dummies $region_dummies $region_trends
local c_nores male_child age_head male_head hh_size Orthodox Protestant Muslim ///
    $lang_dummies $region_dummies $region_trends

eststo clear

* Order matches Table S10: female, male, urban, rural, poor, non-poor
local first = 1
foreach g in female male urban rural poor nonpoor {

    if "`g'" == "female" {
        local cond "male_child==0"
        local ctrl "`c_nosex'"
        local ttl  "Female children"
    }
    if "`g'" == "male" {
        local cond "male_child==1"
        local ctrl "`c_nosex'"
        local ttl  "Male children"
    }
    if "`g'" == "urban" {
        local cond "residence==0"
        local ctrl "`c_nores'"
        local ttl  "Urban"
    }
    if "`g'" == "rural" {
        local cond "residence==1"
        local ctrl "`c_nores'"
        local ttl  "Rural"
    }
    if "`g'" == "poor" {
        local cond "poor==1"
        local ctrl "$controls"
        local ttl  "Poor households"
    }
    if "`g'" == "nonpoor" {
        local cond "poor==0"
        local ctrl "$controls"
        local ttl  "Non-poor households"
    }

    quietly ivreg2 infant_mortality (educ_years = $instruments) `ctrl' ///
        if `cond' & $sample, cluster($cluster) partial($partial_vars) ffirst
    eststo het_`g'

    local kp  = trim("`: display %9.2f e(widstat)'")
    local arp = trim("`: display %9.4f e(archi2p)'")
    quietly summarize infant_mortality if e(sample)
    local mn  = trim("`: display %9.4f r(mean)'")

    local mode = cond(`first', "replace", "append")
    outreg2 using "$output/TableS10_heterogeneity.xls", `mode' bdec(3) adec(3) ///
        ctitle("`ttl'") keep(educ_years) ///
        addstat(KP rk Wald F, `kp', AR test p-value, `arp', Avg. outcome, `mn') ///
        addtext(Controls, YES, Region x age trends, YES) nor2 noni nocons label
    local first = 0
}

*------------------------------------------------------------------------------
* Coefficient plots
*------------------------------------------------------------------------------
local xt "2SLS estimate: effect of one additional year of maternal education"

coefplot ///
    (het_female, rename(educ_years = "Female") msymbol(O) mcolor(navy) ciopts(lcolor(navy))) ///
    (het_male,   rename(educ_years = "Male")   msymbol(O) mcolor(maroon) ciopts(lcolor(maroon))) ///
    , keep(educ_years) xline(0, lpattern(dash) lcolor(gs10)) ///
    title("By child sex", box bexpand margin(small) bmargin(small) size(medium) color(white) bcolor(205 32 44)) ///
    xtitle("") xlabel(, labsize(small) format(%4.3f)) ///
    graphregion(color(white)) bgcolor(white) legend(off) ysize(2.5) xsize(6) ///
    name(fig6_sex, replace) nodraw

coefplot ///
    (het_urban, rename(educ_years = "Urban") msymbol(O) mcolor(navy) ciopts(lcolor(navy))) ///
    (het_rural, rename(educ_years = "Rural") msymbol(O) mcolor(maroon) ciopts(lcolor(maroon))) ///
    , keep(educ_years) xline(0, lpattern(dash) lcolor(gs10)) ///
    title("By residence", box bexpand margin(small) bmargin(small) size(medium) color(white) bcolor(205 32 44)) ///
    xtitle("") xlabel(, labsize(small) format(%4.3f)) ///
    graphregion(color(white)) bgcolor(white) legend(off) ysize(2.5) xsize(6) ///
    name(fig6_res, replace) nodraw

coefplot ///
    (het_poor,    rename(educ_years = "Poor")     msymbol(O) mcolor(navy) ciopts(lcolor(navy))) ///
    (het_nonpoor, rename(educ_years = "Non-poor") msymbol(O) mcolor(maroon) ciopts(lcolor(maroon))) ///
    , keep(educ_years) xline(0, lpattern(dash) lcolor(gs10)) ///
    title("By household wealth", box bexpand margin(small) bmargin(small) size(medium) color(white) bcolor(205 32 44)) ///
    xtitle("") xlabel(, labsize(small) format(%4.3f)) ///
    graphregion(color(white)) bgcolor(white) legend(off) ysize(2.5) xsize(6) ///
    name(fig6_wealth, replace) nodraw

graph combine fig6_sex fig6_res fig6_wealth, ///
    cols(1) b1title("`xt'", size(small)) graphregion(color(white)) ///
    imargin(small) ysize(8) xsize(6)
graph export "$figure/Figure6_heterogeneity.png", replace width(2400) as(png)

*==============================================================================
* End of TableS10_Figure6_heterogeneity.do
*==============================================================================
