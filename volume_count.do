* volume_count.do
	
local file_p = "/Users/tuk39938/Desktop/programs/team_production/"
*local file_p = "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production"
*local file_p = "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production"

	* 
use "`file_p'fake_dep_4.dta", clear
 
 
merge 1:1 MERGE_VAR using "`file_p'fake_SIDR_DOD_Dep.dta"

* "unique episode" -> kind of
	gen episode_id = _n


* keep diagnoses, procedure, drg, count those by NPI month.

	gen adm_month = month(DATE_ADMISSION)
	gen adm_year = year(DATE_ADMISSION)
	
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
	keep provnpi adm_year adm_month MSDRG drg_ct 
	rename *, upper 
	bysort PROVNPI ADM_MONTH ADM_YEAR (DRG_CT): gen nn = _n 
	reshape wide MSDRG DRG_CT, i(PROVNPI ADM_MONTH ADM_YEAR) j(nn)
	save "`file_p'drg_count_by_npi.dta", replace
restore 


* others require reshape and different sort
	* are DX and dx the same across the files?  
	* DIAGNOSES
preserve 
	keep provnpi adm_year adm_month ADMDX dx* DX*
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
	keep provnpi adm_year adm_month DX dx_count 
	duplicates drop provnpi adm_year adm_month DX, force 
	rename *, upper
	bysort PROVNPI ADM_MONTH ADM_YEAR (DX_COUNT): gen nn = _n 
	reshape wide DX DX_COUNT, i(PROVNPI ADM_MONTH ADM_YEAR) j(nn)
	save "`file_p'diag_code_count_by_npi.dta", replace
restore 

	* PROCEDURES - cpt_, PROC
preserve 
	keep provnpi cpt_* adm_year adm_month 
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
	keep provnpi adm_year adm_month cpt cpt_count 
	rename *, upper
	bysort PROVNPI ADM_MONTH ADM_YEAR (CPT_COUNT): gen nn = _n 
	reshape wide CPT CPT_COUNT, i(PROVNPI ADM_MONTH ADM_YEAR) j(nn)
	save "`file_p'cpt_code_count_by_npi.dta", replace
restore 
	
* Finally, there is the set of PROC values
	* this includes a PROCQTY -> generate two sums, one where each appearance of PROC counts as 1 (proc_units_count)
	* and another sum proc_total_count which is the sum of PROCQTY by PROC type.  

preserve 
	keep provnpi PROC* adm_year adm_month 
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
	keep provnpi adm_year adm_month PROC proc_units_count proc_total_count 
	rename *, upper 
	bysort PROVNPI ADM_MONTH ADM_YEAR (PROC_UNITS_COUNT): gen nn = _n 
	reshape wide PROC PROC_UNITS_COUNT PROC_TOTAL_COUNT, i(PROVNPI ADM_MONTH ADM_YEAR) j(nn)
	save "`file_p'proc_count_by_npi.dta", replace 
restore 
		
* Clean up, merge all volumes into single file 

clear 
use "`file_p'drg_count_by_npi.dta"

merge m:1 PROVNPI ADM_YEAR ADM_MONTH using "`file_p'diag_code_count_by_npi.dta"
drop _merge

merge 1:1 PROVNPI ADM_YEAR ADM_MONTH using "`file_p'cpt_code_count_by_npi.dta"
drop _merge 

merge 1:1 PROVNPI ADM_YEAR ADM_MONTH using "`file_p'proc_count_by_npi.dta"
drop _merge 

save "`file_p'ALL_counts_by_npi.dta", replace 
