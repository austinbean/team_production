/* volume_count.do

LAST UPDATE:
WHAT: ADAPT TO BEING CALLED BY THE MASTER FILE
WHEN: OCT 2, 2019
BY: AG
*/

	
do "/Users/tuk39938/Desktop/programs/team_production/master_filepaths.do"
*do "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production\master_filepaths.do"
*do "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production\master_filepaths.do"

	
use "${file_p}fake_dep_4.dta", clear
 
 
merge 1:1 MERGE_VAR using "${file_p}fake_SIDR_DOD_Dep.dta"

* "unique episode" -> kind of
	gen episode_id = _n


* keep diagnoses, procedure, drg, count those by NPI month.

	gen adm_month = month(DATE_ADMISSION)
	gen adm_year = year(DATE_ADMISSION)
* Generate a continuous index of months	
	gen mnth_ix = mofd(DATE_ADMISSION)

	
	
* sort by NPI -> need multiple records for each one.
* renumber consecutively
	replace provnpi2 = provnpi3 if provnpi2 == "" & provnpi3 != ""

	reshape long provnpi, i(episode_id) j(ctr)
	* no duplicate providers within one episode.
	duplicates drop provnpi episode_id, force
	
	drop if provnpi == ""

	sort provnpi adm_year adm_month
	
	* counter
	gen thect = 1
	
	

	* count DRG's, CPT's, DIAG_CODES
preserve	
	bysort provnpi adm_year adm_month MSDRG : egen drg_ct = sum(thect)
	label variable drg_ct "monthly drg count"
	duplicates drop provnpi adm_year adm_month MSDRG, force 
	keep provnpi adm_year adm_month mnth_ix MSDRG drg_ct 
	rename *, upper 
	* Count DRGS by month
	sort PROVNPI MSDRG MNTH_IX
	bysort PROVNPI MSDRG (MNTH_IX): gen mdiff = MNTH_IX - MNTH_IX[_n+1]
	replace mdiff = abs(mdiff)
	expand mdiff, gen(expdd)
	bysort PROVNPI MSDRG MNTH_IX expdd: gen expctr = _n if expdd == 1
	replace MNTH_IX = MNTH_IX + expctr if expdd == 1
	replace DRG_CT = 0 if expdd == 1
	foreach k of numlist 1(1)12{
		bysort PROVNPI MSDRG (MNTH_IX): gen DRG_CT_`k'MNTH_PRIOR = DRG_CT[_n-`k']
		replace DRG_CT_`k'MNTH_PRIOR = 0 if DRG_CT_`k'MNTH_PRIOR == .
	}
	drop if expdd == 1
	drop expctr expdd mdiff
	* Reshape wide for one provider-month observation
	bysort PROVNPI MNTH_IX (DRG_CT): gen nn = _n 
	reshape wide MSDRG DRG_CT DRG_CT_*MNTH_PRIOR, i(PROVNPI ADM_MONTH ADM_YEAR) j(nn)
	save "${file_p}drg_count_by_npi.dta", replace
restore 


* others require reshape and different sort
	* are DX and dx the same across the files?  
	* DIAGNOSES
preserve 
	keep provnpi adm_year adm_month mnth_ix ADMDX dx* DX*
	drop dx* 
	drop DX*POA
	rename ADMDX DX21
	bysort provnpi adm_year adm_month: gen pmyct = _n
	reshape long DX , i(provnpi adm_month adm_year pmyct) j(ctrr)
	drop if DX == ""
	drop ctrr 
	gen ctr1 = 1
	sort provnpi adm_year adm_month DX 
	bysort provnpi adm_year adm_month DX: egen dx_count = sum(ctr1)
	label variable dx_count "diagnosis count by month"
	keep provnpi adm_year adm_month mnth_ix DX dx_count 
	duplicates drop provnpi adm_year adm_month DX, force 
	rename *, upper
	* count, but add a continuous sequence of months when any diagnosis is not present in a given month.
	sort PROVNPI DX MNTH_IX
	bysort PROVNPI DX (MNTH_IX): gen mdiff = MNTH_IX - MNTH_IX[_n+1]
	replace mdiff = abs(mdiff)
	expand mdiff, gen(expdd)
	bysort PROVNPI DX MNTH_IX expdd: gen expctr = _n if expdd == 1
	replace MNTH_IX = MNTH_IX + expctr if expdd == 1
	replace DX_COUNT = 0 if expdd == 1
	foreach k of numlist 1(1)12{
		bysort PROVNPI DX (MNTH_IX): gen DX_CT_`k'MNTH_PRIOR = DX_COUNT[_n-`k']
		replace DX_CT_`k'MNTH_PRIOR = 0 if DX_CT_`k'MNTH_PRIOR == .
	}
	drop if expdd == 1
	drop expctr expdd mdiff 
	* reshape to one record per doctor-month
	bysort PROVNPI ADM_YEAR ADM_MONTH (DX_COUNT): gen nn = _n 
	reshape wide DX DX_COUNT DX_CT_*MNTH_PRIOR, i(PROVNPI ADM_MONTH ADM_YEAR) j(nn)
	save "${file_p}diag_code_count_by_npi.dta", replace
restore 

	* PROCEDURES - cpt_, PROC
preserve 
	keep provnpi cpt_* adm_year adm_month mnth_ix
	bysort provnpi adm_year adm_month: gen pmyct = _n
	reshape long cpt_ , i(provnpi adm_month adm_year pmyct) j(ctrr)
	drop if cpt_ == ""
	drop ctrr 
	gen ctr1 = 1 
	sort provnpi adm_year adm_month cpt_ 
	bysort provnpi adm_year adm_month cpt_: egen cpt_count = sum(ctr1)
	label variable cpt_count "cpt code count by month"
	rename cpt_ cpt 
	duplicates drop provnpi adm_year adm_month cpt, force 
	keep provnpi adm_year adm_month cpt cpt_count mnth_ix
	rename *, upper
	* Count, but expand to make sure we have a continuous sequence of months.
	sort PROVNPI CPT MNTH_IX
	bysort PROVNPI CPT (MNTH_IX): gen mdiff = MNTH_IX - MNTH_IX[_n+1]
	replace mdiff = abs(mdiff)
	expand mdiff, gen(expdd)
	bysort PROVNPI CPT MNTH_IX expdd: gen expctr = _n if expdd == 1
	replace MNTH_IX = MNTH_IX + expctr if expdd == 1
	replace CPT_COUNT = 0 if expdd == 1
	foreach k of numlist 1(1)12{
		bysort PROVNPI CPT (MNTH_IX): gen CPT_CT_`k'MNTH_PRIOR = CPT_COUNT[_n-`k']
		replace CPT_CT_`k'MNTH_PRIOR = 0 if CPT_CT_`k'MNTH_PRIOR == .
	}
	drop if expdd == 1
	drop expctr expdd mdiff 
	* reshape to create one provider month record 
	bysort PROVNPI ADM_MONTH ADM_YEAR (CPT_COUNT): gen nn = _n 
	reshape wide CPT CPT_COUNT CPT_CT_*MNTH_PRIOR, i(PROVNPI ADM_MONTH ADM_YEAR) j(nn)
	save "${file_p}cpt_code_count_by_npi.dta", replace

restore 
	
* Finally, there is the set of PROC values
	* this includes a PROCQTY -> generate two sums, one where each appearance of PROC counts as 1 (proc_units_count)
	* and another sum proc_total_count which is the sum of PROCQTY by PROC type.  

preserve 
	keep provnpi PROC* adm_year adm_month mnth_ix
	drop PROCLOC*
	bysort provnpi adm_year adm_month: gen pmyct = _n
	reshape long PROC PROCQTY, i(provnpi adm_month adm_year pmyct) j(ctrr)
	drop if PROC == ""
	destring PROCQTY, replace force
	replace PROCQTY = 0 if PROCQTY == .
	gen prctr = 1
	sort provnpi adm_year adm_month PROC 
	bysort provnpi adm_year adm_month PROC: egen proc_units_count = sum(prctr)
	bysort provnpi adm_year adm_month PROC: egen proc_total_count = sum(PROCQTY)
	label variable proc_units_count "Each proc adds ONE - compare proc_total"
	label variable proc_total_count "Sum of PROC_QTY - compare proc_units"
	duplicates drop provnpi adm_year adm_month PROC , force
	keep provnpi adm_year adm_month PROC proc_units_count proc_total_count mnth_ix
	rename *, upper 
	* EXPAND ONCE AND COMPUTE BOTH SUMS 
	sort PROVNPI PROC MNTH_IX 
	bysort PROVNPI PROC (MNTH_IX): gen mdiff = MNTH_IX - MNTH_IX[_n+1]
	replace mdiff = abs(mdiff)
	expand mdiff, gen(expdd)
	bysort PROVNPI PROC MNTH_IX expdd: gen expctr = _n if expdd == 1
	replace MNTH_IX = MNTH_IX + expctr if expdd == 1
	replace PROC_UNITS_COUNT = 0 if expdd == 1
	replace PROC_TOTAL_COUNT = 0 if expdd == 1
		foreach k of numlist 1(1)12{
			bysort PROVNPI PROC (MNTH_IX): gen PROC_UNITS_`k'MNTH_PRIOR = PROC_UNITS_COUNT[_n-`k'] 
			replace PROC_UNITS_`k'MNTH_PRIOR = 0 if PROC_UNITS_`k'MNTH_PRIOR == .
		}
		foreach k of numlist 1(1)12{
			bysort PROVNPI PROC (MNTH_IX): gen PROC_TOTAL_`k'MNTH_PRIOR = PROC_TOTAL_COUNT[_n-`k'] 
			replace PROC_TOTAL_`k'MNTH_PRIOR = 0 if PROC_TOTAL_`k'MNTH_PRIOR == .
		}
	drop if expdd == 1
	drop expctr expdd mdiff 
	* Reshape to create one provider month record
	bysort PROVNPI ADM_MONTH ADM_YEAR (PROC_UNITS_COUNT): gen nn = _n 
	reshape wide PROC PROC_UNITS_COUNT PROC_TOTAL_COUNT PROC_UNITS_*MNTH_PRIOR PROC_TOTAL_*MNTH_PRIOR, i(PROVNPI ADM_MONTH ADM_YEAR) j(nn)
	save "${file_p}proc_count_by_npi.dta", replace 

restore 
		
* Clean up, merge all volumes into single file 

clear 
use "${file_p}drg_count_by_npi.dta"

merge m:1 PROVNPI ADM_YEAR ADM_MONTH using "${file_p}diag_code_count_by_npi.dta"
drop _merge

merge 1:1 PROVNPI ADM_YEAR ADM_MONTH using "${file_p}cpt_code_count_by_npi.dta"
drop _merge 

merge 1:1 PROVNPI ADM_YEAR ADM_MONTH using "${file_p}proc_count_by_npi.dta"
drop _merge 

save "${file_p}ALL_counts_by_npi.dta", replace 

*END CODE;
