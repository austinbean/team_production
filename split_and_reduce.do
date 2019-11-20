* Split large file and redo.

clear 

do "/Users/tuk39938/Desktop/programs/team_production/master_filepaths.do"
*do "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production\master_filepaths.do"
*do "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production\master_filepaths.do"

cd "${file_p}"




* CPT Codes .  

* Use SIDR for CPT and DX/ICD-9
use "${file_p}fake_dep_4.dta", clear

/*
Notes - want asc1-13 variables.  But note the codebook separates 1-3 and 4-13
mepr3 is the location vars.  
the codes for this variable are in the codebook.  They are numerous.
Codes for emergency are BIA BIZ (latter is emerg otherwise unclassified)

*/


	format encdate %td // for readability in fake data.  
	rename *, upper


* sort and Generate Splits 
	sort PID_PDE_PATIENT ENCDATE 
	gen ctr1 = _n
	xtile cutpoints = ctr1, nq(100)
	drop ctr1 
	save "${file_p}fake_dep_4.dta", replace


	
// OPERATION W/IN SPLIT FILE 	

	levelsof cutpoints, local(cut_levels)
	
	
	
foreach block of local cut_levels{			
		use "${file_p}fake_dep_4.dta", clear 
		keep if cutpoints == `block'
		* Do computation w/in block 
		keep PID_PDE_PATIENT ENCDATE CPT_* MEPR3
		reshape long CPT_ , i(PID_PDE_PATIENT ENCDATE) j(ctr)
		drop if CPT_ == ""
		sort PID_PDE_PATIENT ENCDATE ctr 
		drop ctr 
		gen EMERGENCY = 0
		replace EMERGENCY = 1 if MEPR3 == "BIA" |  MEPR3 == "BIZ" //  BIX code probably not important 
		bysort PID_PDE_PATIENT ENCDATE: gen cptcx = _n
		bysort PID_PDE_PATIENT ENCDATE: egen cptcount = max(cptcx)
		drop cptcx
		duplicates drop PID_PDE_PATIENT ENCDATE, force
		drop CPT_ MEPR3 
		bysort PID_PDE_PATIENT (ENCDATE): gen pctr = _n 
		summarize pctr, d 
		local mxvs = `r(max)'
		reshape wide ENCDATE cptcount EMERGENCY, i(PID_PDE_PATIENT) j(pctr)
		foreach daylim of numlist 30 60 90 {
			local stopping = `mxvs'-1 
			foreach prior_vis of numlist 1(1)`stopping'{
				gen read_vis_`daylim'_`prior_vis' = 0 
				gen ER_read_vis_`daylim'_`prior_vis' = 0
				local next_vis = `prior_vis'+1
				foreach current_vis of numlist `next_vis'(1)`mxvs'{
					replace read_vis_`daylim'_`prior_vis' = read_vis_`daylim'_`prior_vis' + cptcount`current_vis' if (ENCDATE`current_vis' - ENCDATE`prior_vis' < `daylim') & (ENCDATE`current_vis' - ENCDATE`prior_vis' > 0)
					* count readmissions to the ER 
					replace read_vis_`daylim'_`prior_vis' = read_vis_`daylim'_`prior_vis' + cptcount`current_vis' if (ENCDATE`current_vis' - ENCDATE`prior_vis' < `daylim') & (ENCDATE`current_vis' - ENCDATE`prior_vis' > 0) & EMERGENCY`current_vis' == 1
					}
				}
			}
		reshape long ENCDATE EMERGENCY cptcount read_vis_30_ read_vis_60_ read_vis_90_ ER_read_vis_30_ ER_read_vis_60_ ER_read_vis_90_, i(PID_PDE_PATIENT) j(vctr)
		drop if ENCDATE == . 
		rename read_vis_*_ readmits_vis_*
		rename ER_read_vis_*_ ER_readmits_vis_*
		foreach daylim of numlist 30 60 90 {
			replace readmits_vis_`daylim' = 0 if readmits_vis_`daylim' == .
			replace ER_readmits_vis_`daylim' = 0 if readmits_vis_`daylim' == .
		}
		drop vctr cptcount  
		save "${file_p}temp_cpt_er_BLOCK`block'.dta", replace 
}			
	
	
// REDUCE -> this is a little trickier, but not too hard.   
	
	
foreach block of local cut_levels{			
	use "${file_p}fake_dep_4.dta", clear 
	keep if cutpoints == `block'
		keep PID_PDE_PATIENT ENCDATE CPT_* MEPR3
		reshape long CPT_ , i(PID_PDE_PATIENT ENCDATE) j(ctr)
		drop if CPT_ == ""
		sort PID_PDE_PATIENT ENCDATE ctr 
		drop ctr 
		merge m:1 PID_PDE_PATIENT ENCDATE using "${file_p}temp_cpt_er_BLOCK`block'.dta"
		drop if _merge != 3 
		drop _merge 
		rename CPT_ CPT
		drop if CPT == ""
		drop PID_PDE_PATIENT ENCDATE 
		sort CPT 
		bysort CPT: gen tv_i = _n 
		bysort CPT: egen total_obs = max(tv_i)
		drop tv_i
		foreach days of numlist 30 60 90{
			bysort CPT: egen total_fu_visits_`days' = sum(readmits_vis_`days')
			label variable total_fu_visits_`days' "Total number of follow-ups before `days'"
			* ER in particular 
			bysort CPT: egen ER_total_fu_visits_`days' = sum(ER_readmits_vis_`days')
			label variable ER_total_fu_visits_`days' "Total number of follow-ups before `days'"
		}
			* Fraction with follow ups (at all)  
		foreach days of numlist 30 60 90 {
			gen f_u_c_`days' = 0
			replace f_u_c_`days' = 1 if readmits_vis_`days' > 0 
			bysort CPT: egen tfu_`days' = sum(f_u_c_`days')
			gen frac_follow_up_`days' = tfu_`days'/total_obs 
			label variable frac_follow_up_`days' "Frac. of Visits w/ ANY Follow up before `days'"
	* TODO - er follow up visit count not working exactly. 
			* ER in particular 
			gen ERf_u_c_`days' = 0
			replace ERf_u_c_`days' = 1 if ER_readmits_vis_`days' > 0 
			bysort CPT: egen ER_tfu_`days' = sum(ERf_u_c_`days')
			gen ER_frac_follow_up_`days' = ER_tfu_`days'/total_obs 
			label variable ER_frac_follow_up_`days' "Frac. of Visits w/ ER Follow up before `days'"
		}
		keep CPT total_fu_* frac_follow_up_* ER_total_fu_* ER_frac_follow_up_* total_obs
		duplicates drop CPT, force 
		* sadly nothing akin to icd9 check as above.
		save "${file_p}freq_follow_ups_cpt_BLOCK`block'.dta", replace
}

clear 
use "${file_p}freq_follow_ups_cpt_BLOCK1.dta"

foreach block of local cut_levels{
	if `block' != 1{
		append using "${file_p}freq_follow_ups_cpt_BLOCK`block'.dta"
	}
}

sort CPT 
collapse (sum) total_obs total_fu_visits_30 ER_total_fu_visits_30 total_fu_visits_60 ER_total_fu_visits_60 total_fu_visits_90 ER_total_fu_visits_90 (mean) frac_follow_up_30 ER_frac_follow_up_30 frac_follow_up_60 ER_frac_follow_up_60 frac_follow_up_90 ER_frac_follow_up_90, by(CPT)

save "${file_p}freq_follow_ups_cpt.dta"

