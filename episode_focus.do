* episode_focus.do

/*
Which episodes lead to a lot of follow up?

Count follow ups.  
Merge to episodes.
Reshape by diagnosis/CPT/DRG

Sum total count / Sum Redmissions


*/

clear 

do "/Users/tuk39938/Desktop/programs/team_production/master_filepaths.do"
*do "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production\master_filepaths.do"
*do "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production\master_filepaths.do"

cd "${file_p}"


* Use SIDR for CPT and DX/ICD-9
use "${file_p}fake_SIDR_DOD_Dep.dta"

	
	
* Generate list of patients with relevant admissions	
	* Sort by patient and then date.
	sort PID_PDE_PATIENT DATE_ADMISSION

	keep PID_PDE_PATIENT DATE_ADMISSION DATE_DISPOSITION *DX* PROC*
	drop DX*POA
	drop PROCQTY* PROCLOC* 
	* keep ADMDX - this will be constant w/in patient admission date
	bysort PID_PDE_PATIENT DATE_ADMISSION: gen pctr = _n
	reshape long DX PROC, i(PID_PDE_PATIENT DATE_ADMISSION pctr)
	drop _j  pctr 
	drop if (DX == ""  & PROC == "" & ADMDX == "")
	duplicates drop PID_PDE_PATIENT DATE_ADMISSION ADMDX if DX == "" & PROC == "", force
	
	
* First count w/ admitting diagnosis.
	preserve
		keep PID_PDE_PATIENT DATE_ADMISSION DATE_DISPOSITION ADMDX 
		duplicates drop PID_PDE_PATIENT DATE_ADMISSION ADMDX, force
		bysort PID_PDE_PATIENT (DATE_ADMISSION): gen pctr = _n 
		summarize pctr, d
		local max_r = `r(max)'
		reshape wide DATE_ADMISSION DATE_DISPOSITION ADMDX, i(PID_PDE_PATIENT) j(pctr)
		foreach daylim of numlist 30 60 90{		
			local stopping = `max_r'-1
			foreach prior_vis of numlist 1(1)`stopping'{
				gen readmits_vis_`daylim'_`prior_vis' = 0
				local next_vis =`prior_vis'+1
				foreach current_vis of numlist `next_vis'(1)`max_r'{
					replace readmits_vis_`daylim'_`prior_vis' = readmits_vis_`daylim'_`prior_vis' + 1 if (DATE_ADMISSION`current_vis' - DATE_DISPOSITION`prior_vis') < `daylim' 
				}
			}
		}
		keep PID_PDE_PATIENT ADMDX* DATE_ADMISSION* DATE_DISPOSITION* readmits_*
		reshape long ADMDX DATE_ADMISSION DATE_DISPOSITION readmits_vis_30_ readmits_vis_60_ readmits_vis_90_, i(PID_PDE_PATIENT)
		drop _j 
		drop if ADMDX == ""
		foreach days of numlist 30 60 90{
			replace readmits_vis_`days'_ = 0 if readmits_vis_`days'_ == .
		}
		drop PID_PDE_PATIENT DATE_ADMISSION DATE_DISPOSITION 
		sort ADMDX 
		bysort ADMDX: gen tv_i = _n 
		bysort ADMDX: egen total_obs = max(tv_i)
		drop tv_i
		
		* Fraction with follow ups (at all)  
		foreach days of numlist 30 60 90 {
			gen f_u_c_`days' = 0
			replace f_u_c_`days' = 1 if readmits_vis_`days'_ > 0 
			bysort ADMDX: egen tfu_`days' = sum(f_u_c_`days')
			gen frac_follow_up_`days' = tfu_`days'/total_obs 
			label variable frac_follow_up_`days' "Frac. of Visits w/ Follow up before `days'"
		}
		drop tfu_* f_u_c_*
		* total follow-up visits.  
		foreach days of numlist 30 60 90{
			bysort ADMDX: egen total_fu_visits_`days' = sum(readmits_vis_`days'_)
			label variable total_fu_visits_`days' "Total number of follow-ups before `days'"
		}
		keep ADMDX frac_follow_up_* total_fu_* total_obs
		duplicates drop ADMDX, force 
		icd9 check ADMDX, generate(CODE_FAIL)
		drop if CODE_FAIL != 0
		drop CODE_FAIL
		icd9 generate CODE_DESC = ADMDX, description end
		icd9 generate CODE_CAT = ADMDX, category
		sort CODE_CAT ADMDX 
		save "${file_p}freq_follow_ups_adm_dx_only.dta", replace
	restore	

* create temp file to handle problem with width of next part 	
preserve
		keep PID_PDE_PATIENT ADMDX DX DATE_* 
		bysort PID_PDE_PATIENT DATE_ADMISSION: gen pctr = _n 
		bysort PID_PDE_PATIENT DATE_ADMISSION: egen pc = max(pctr)
		drop pctr 
		expand 2 if pc == 1, gen(expdr)
		replace DX = ADMDX if expdr == 1
		keep PID_PDE_PATIENT DATE_* DX* 
		keep if DX != ""
		gen tc = 1
		bysort PID_PDE_PATIENT DATE_ADMISSION: egen vdxct = sum(tc)
		drop tc
		duplicates drop PID_PDE_PATIENT DATE_ADMISSION, force
		drop DX 
		bysort PID_PDE_PATIENT (DATE_ADMISSION): gen pctr = _n 
		summarize pctr, d 
		local mxvs = `r(max)'
		reshape wide DATE_ADMISSION DATE_DISPOSITION vdxct, i(PID_PDE_PATIENT) j(pctr)
		foreach daylim of numlist 30 60 90 {
			local stopping = `mxvs'-1 
			foreach prior_vis of numlist 1(1)`stopping'{
				gen read_vis_`daylim'_`prior_vis' = 0 
				local next_vis = `prior_vis'+1
				foreach current_vis of numlist `next_vis'(1)`mxvs'{
					replace read_vis_`daylim'_`prior_vis' = read_vis_`daylim'_`prior_vis' + vdxct`current_vis' if (DATE_ADMISSION`current_vis' - DATE_DISPOSITION`prior_vis' < `daylim') & (DATE_ADMISSION`current_vis' - DATE_ADMISSION`prior_vis' > 0)
				}
			}
		}
		reshape long DATE_ADMISSION DATE_DISPOSITION vdxct read_vis_30_ read_vis_60_ read_vis_90_ , i(PID_PDE_PATIENT) j(vctr)
		drop if DATE_ADMISSION == . 
		rename read_vis_*_ readmits_vis_*
		foreach daylim of numlist 30 60 90 {
			replace readmits_vis_`daylim' = 0 if readmits_vis_`daylim' == .
		}
		drop vctr vdxct 
		save "${file_p}temp_follow_up_count.dta", replace 
restore 

* Do the same with ALL diagnoses (incl admitting.)
	preserve
		keep PID_PDE_PATIENT ADMDX DX DATE_* 
		bysort PID_PDE_PATIENT DATE_ADMISSION: gen pctr = _n 
		bysort PID_PDE_PATIENT DATE_ADMISSION: egen pc = max(pctr)
		drop pctr 
		expand 2 if pc == 1, gen(expdr)
		replace DX = ADMDX if expdr == 1
		keep PID_PDE_PATIENT DATE_* DX* 
		keep if DX != ""
		bysort PID_PDE_PATIENT: gen dxct = _n 	
		summarize dxct, d
		local mxdx = `r(max)'
	* every DX code receives all follow up counts 
		merge m:1 PID_PDE_PATIENT DATE_ADMISSION DATE_DISPOSITION using "${file_p}temp_follow_up_count.dta"
		drop if _merge != 3 
		drop _merge 
		drop if DX == ""
		drop PID_PDE_PATIENT DATE_ADMISSION DATE_DISPOSITION dxct
		sort DX 
		bysort DX: gen tv_i = _n 
		bysort DX: egen total_obs = max(tv_i)
		drop tv_i
		* Fraction with follow ups (at all)  
		foreach days of numlist 30 60 90 {
			gen f_u_c_`days' = 0
			replace f_u_c_`days' = 1 if readmits_vis_`days' > 0 
			bysort DX: egen tfu_`days' = sum(f_u_c_`days')
			gen frac_follow_up_`days' = tfu_`days'/total_obs 
			label variable frac_follow_up_`days' "Frac. of Visits w/ Follow up before `days'"
		}
		foreach days of numlist 30 60 90{
			bysort DX: egen total_fu_visits_`days' = sum(readmits_vis_`days')
			label variable total_fu_visits_`days' "Total number of follow-ups before `days'"
		}
		keep DX frac_follow_up_* total_fu_* total_obs
		duplicates drop DX, force 
		icd9 check DX, generate(CODE_FAIL)
		drop if CODE_FAIL != 0
		drop CODE_FAIL
		icd9 generate CODE_DESC = DX, description end
		icd9 generate CODE_CAT = DX, category
		sort CODE_CAT DX 
		save "${file_p}freq_follow_ups_all_dx.dta", replace
	restore 
	
	
* CPT Codes .  

* Use SIDR for CPT and DX/ICD-9
use "${file_p}fake_dep_4.dta", clear

/*
Notes - want asc1-13 variables.  But note the codebook separates 1-3 and 4-13
mepr3 is the location vars.  
the codes for this variable are in the codebook.  They are numerous.
Codes for emergency are BIA BIZ (latter is emerg otherwise unclassified)
- What about BIX?  

*/

	* TODO - do we want to track same-day procedures?  This is tricky.  Procedure done badly -> immediate, emergency follow up -> same day
	format encdate %td // for readability in fake data.  
	rename *, upper

preserve 
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
	save "${file_p}temp_cpt_er_flw_up_count.dta", replace 
restore 
	
	
	
	
	
	
	
preserve 	
	keep PID_PDE_PATIENT ENCDATE CPT_* MEPR3
	reshape long CPT_ , i(PID_PDE_PATIENT ENCDATE) j(ctr)
	drop if CPT_ == ""
	sort PID_PDE_PATIENT ENCDATE ctr 
	drop ctr 
	merge m:1 PID_PDE_PATIENT ENCDATE using "${file_p}temp_cpt_er_flw_up_count.dta"
	drop if _merge != 3 
	drop _merge 
	rename CPT_ CPT
	drop if CPT == ""
	drop PID_PDE_PATIENT ENCDATE 
	sort CPT 
	bysort CPT: gen tv_i = _n 
	bysort CPT: egen total_obs = max(tv_i)
	drop tv_i
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
	foreach days of numlist 30 60 90{
		bysort CPT: egen total_fu_visits_`days' = sum(readmits_vis_`days')
		label variable total_fu_visits_`days' "Total number of follow-ups before `days'"
		* ER in particular 
		bysort CPT: egen ER_total_fu_visits_`days' = sum(ER_readmits_vis_`days')
		label variable ER_total_fu_visits_`days' "Total number of follow-ups before `days'"
	}
	keep CPT frac_follow_up_* total_fu_* ER_frac_follow_up_* ER_total_fu_* total_obs
	duplicates drop CPT, force 
	* sadly nothing akin to icd9 check as above.
	save "${file_p}freq_follow_ups_cpt.dta", replace
restore 
