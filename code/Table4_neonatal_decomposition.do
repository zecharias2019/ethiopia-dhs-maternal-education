*==============================================================================
* Table4_neonatal_decomposition.do
* Table 4. Decomposition of first-born infant mortality into neonatal (month 0) and
* post-neonatal (months 1-11) mortality, using the baseline 2SLS specification.
* Output: output/tables/Table4_neonatal_decomposition.xls
*==============================================================================

if "$root" == "" {
    display as error "Set the global root (see master.do) first."
    exit 198
}
if "$maindata" == "" do "$root/code/00_config.do"

use "$maindata", clear

* The three outcomes must be defined on a common sample
assert neonatal_mort + postneonatal_mort == infant_mortality if !missing(infant_mortality)

local first = 1
foreach y in infant_mortality neonatal_mort postneonatal_mort {
    ivreg2 `y' (educ_years = $instruments) $controls if $sample, ///
        cluster($cluster) ffirst partial($partial_vars)

    scalar kpf = e(widstat)
	scalar arp_`y' = e(archi2p)

    quietly summarize `y' if e(sample)
    local ymean = r(mean)
    local lab : variable label `y'

    local mode = cond(`first', "replace", "append")
    outreg2 using "$output/Table4_neonatal_decomposition.xls", `mode' bdec(3) adec(3) ///
        ctitle("`lab'") keep(educ_years) nor2 noni nocons label ///
        addstat(KP rk Wald F, kpf, AR test p-value, arp_`y', Avg. outcome, `ymean') ///
        addtext(Controls, YES, Region x age trends, YES)
    local first = 0
}

*==============================================================================
* End of Table4_neonatal_decomposition.do
*==============================================================================
