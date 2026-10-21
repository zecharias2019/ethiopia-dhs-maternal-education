*==============================================================================
* TableS8_Figure4_mechanisms.do
* Table S8 and Figure 4. Effect of maternal education on 19 intermediate
* outcomes, baseline 2SLS.
*
* One table, three panels, in the order used in the text:
*   A  Empowerment and partner outcomes            (9 outcomes)
*   B  Healthcare access and utilisation           (4 outcomes)
*   C  Fertility timing and maternal health        (6 outcomes)
* Columns: outcome mean | 2SLS estimate | SE | N | raw p | Holm-adjusted p | AR p
* AR p is the Anderson-Rubin p-value (weak-instrument-robust test of a zero
* effect). The Holm step-down adjustment is applied jointly across all 19
* outcomes.
*
* Outputs: output/tables/TableS8_mechanisms.xlsx
*          output/figures/Figure4_mechanisms.png
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

use "$maindata", clear

*------------------------------------------------------------------------------
* Outcomes and labels (table order)
*------------------------------------------------------------------------------
local outs_A dec_health_involved dec_purchase_involved dec_own_earn_involved ///
    dec_hus_earn_involved married_bywill husband_supports perm_NonProblem ///
    HigherEduc money_NonProblem
local labs_A `""Own healthcare decisions" "Large purchase decisions" "Own earnings decisions" "Husband earnings decisions" "Married by own will" "Husband helps with chores" "Permission not a barrier" "Husband higher education" "Money not a barrier""'

local outs_B insured prenatal_doc_recent hc_use modern_contraception
local labs_B `""Has health insurance" "Prenatal care: doctor" "Healthcare use (12 months)" "Modern contraception""'

local outs_C age_at_cohabitation age_at_fsex age_at_fbirth high_parity ///
    children_ever_born nt_wm_ovobese
local labs_C `""Age at first cohabitation" "Age at first sex" "Age at first birth" "High parity (4+ births)" "Children ever born" "Overweight or obese""'

local ttl_A "Empowerment and partner outcomes"
local ttl_B "Healthcare access and utilisation"
local ttl_C "Fertility timing and maternal health"

*------------------------------------------------------------------------------
* 2SLS for each outcome. Results are stored for the table and for the figure.
*------------------------------------------------------------------------------
tempname P
tempfile RES
postfile `P' double ord str60 outcome double(mean coef se n p_raw kpf arp) using `RES'

eststo clear
local k = 0
foreach pnl in A B C {
    local i = 0
    foreach lhs of local outs_`pnl' {
        local ++k
        local ++i
        local lab : word `i' of `labs_`pnl''
        local lab = subinstr(`"`lab'"', char(34), "", .)

        * ffirst makes ivreg2 store the weak-identification statistics
        quietly ivreg2 `lhs' (educ_years = $instruments) $controls if $sample, ///
            cluster($cluster) partial($partial_vars) ffirst
        eststo mec_`lhs'

        local b  = _b[educ_years]
        local s  = _se[educ_years]
        local n  = e(N)
        local kp = e(widstat)
        local ar = e(archi2p)
        local pr = 2*(1 - normal(abs(`b'/`s')))
        quietly summarize `lhs' if e(sample)
        local mu = r(mean)

        post `P' (`k') ("`lab'") (`mu') (`b') (`s') (`n') (`pr') (`kp') (`ar')
    }
}
postclose `P'

*------------------------------------------------------------------------------
* Holm step-down adjusted p-values across all 19 outcomes, then the table
*------------------------------------------------------------------------------
preserve
    use `RES', clear
    local nout = _N
    display as text "Number of mechanism outcomes: `nout'"

    * Holm: sort ascending, multiply by (n - rank + 1), enforce monotonicity, cap at 1
    sort p_raw
    gen holm_p = (`nout' - _n + 1)*p_raw
    replace holm_p = max(holm_p, holm_p[_n-1]) if _n > 1
    replace holm_p = min(holm_p, 1)
    sort ord

    quietly summarize kpf
    display as text "Kleibergen-Paap F across outcomes: min " %5.1f r(min) ", max " %5.1f r(max)
    list outcome mean coef se n p_raw holm_p arp kpf, noobs sep(0)

    * Panel subheadings
    local n0 = _N
    set obs `=`n0'+3'
    replace outcome = "Panel A: Empowerment and partner outcomes"    in `=`n0'+1'
    replace outcome = "Panel B: Healthcare access and utilisation"   in `=`n0'+2'
    replace outcome = "Panel C: Fertility timing and maternal health" in `=`n0'+3'
    replace ord = 0.5  in `=`n0'+1'
    replace ord = 9.5  in `=`n0'+2'
    replace ord = 13.5 in `=`n0'+3'
    sort ord

    * Table-ready strings (stars refer to the unadjusted p-values)
    gen str5 stars = cond(p_raw<.01,"***",cond(p_raw<.05,"**",cond(p_raw<.1,"*","")))
    gen str12 Mean_of_outcome = cond(missing(mean),"",strofreal(mean,"%9.3f"))
    gen str12 Estimate        = cond(missing(coef),"",strofreal(coef,"%9.3f")+stars)
    gen str12 SE              = cond(missing(se),"","("+strofreal(se,"%9.3f")+")")
    gen str12 Observations    = cond(missing(n),"",strofreal(n,"%9.0fc"))
    gen str12 Raw_p           = cond(missing(p_raw),"",cond(p_raw<0.001,"<0.001",strofreal(p_raw,"%9.3f")))
    gen str12 AR_p            = cond(missing(arp),"",cond(arp<0.001,"<0.001",strofreal(arp,"%9.3f")))
    gen str12 Holm_p          = cond(missing(holm_p),"",cond(holm_p<0.001,"<0.001",strofreal(holm_p,"%9.3f")))
    rename outcome Outcome

    export excel Outcome Mean_of_outcome Estimate SE Observations Raw_p Holm_p AR_p ///
        using "$output/TableS8_mechanisms.xlsx", replace firstrow(variables)
restore

*------------------------------------------------------------------------------
* Figure 4: coefficient plots, one per panel, combined in memory
*------------------------------------------------------------------------------
foreach pnl in A B C {
    local plots ""
    local i = 0
    foreach v of local outs_`pnl' {
        local ++i
        local lab : word `i' of `labs_`pnl''
        local lab = subinstr(`"`lab'"', char(34), "", .)
        local plots `plots' (mec_`v', rename(educ_years = "`lab'"))
    }
    local ys = cond("`pnl'" == "A", 4, 3)

    coefplot `plots', keep(educ_years) xline(0, lpattern(dash) lcolor(gs10)) ///
        ciopts(recast(rcap) lcolor(black) lwidth(medium)) ///
        msymbol(O) mcolor(black) msize(medium) ///
        title("`ttl_`pnl''", box bexpand margin(small) bmargin(small) size(medium) color(white) bcolor(205 32 44)) ///
        xtitle("Effect of one additional year of maternal education", size(small)) ///
        xlabel(, labsize(small) format(%4.2f)) ytitle("") ysize(`ys') xsize(6) ///
        plotregion(margin(medium) fcolor(white) lcolor(white)) ///
        graphregion(color(white)) bgcolor(white) legend(off) ///
        name(fig4_`pnl', replace) nodraw
}

graph combine fig4_A fig4_B fig4_C, cols(1) graphregion(color(white)) ysize(12) xsize(8)
graph export "$figure/Figure4_mechanisms.png", replace width(2400) as(png)

*==============================================================================
* End of TableS8_Figure4_mechanisms.do
*==============================================================================
