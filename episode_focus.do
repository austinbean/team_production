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
		summarize dxct 
		local mxdx = `r(max)'
			* For the most frequently readmitted patients, this is going to be very wide.  
		reshape wide DX DATE_ADMISSION DATE_DISPOSITION, i(PID_PDE_PATIENT) j(dxct)
		* Resembles previous loop but is not the same - must check admission date not on same day.  
		foreach daylim of numlist 30 60 90{		
				local stopping = `mxdx'-1
				foreach prior_vis of numlist 1(1)`stopping'{
					gen readmits_vis_`daylim'_`prior_vis' = 0
					local next_vis =`prior_vis'+1
					foreach current_vis of numlist `next_vis'(1)`mxdx'{
						* multiple DX per visit, so this checks whether *admission* dates are different to make sure the visit is different - e.g., no follow-ups from same visit.  
						replace readmits_vis_`daylim'_`prior_vis' = readmits_vis_`daylim'_`prior_vis' + 1 if (DATE_ADMISSION`current_vis' - DATE_DISPOSITION`prior_vis' < `daylim') & (DATE_ADMISSION`current_vis' - DATE_ADMISSION`prior_vis' > 0) 
					}
				}
			}
		keep PID_PDE_PATIENT DX* DATE_ADMISSION* DATE_DISPOSITION* readmits_*
		reshape long DX DATE_ADMISSION DATE_DISPOSITION readmits_vis_30_ readmits_vis_60_ readmits_vis_90_, i(PID_PDE_PATIENT)
		drop _j 
		drop if DX == ""
		foreach days of numlist 30 60 90{
			replace readmits_vis_`days'_ = 0 if readmits_vis_`days'_ == .
		}
		drop PID_PDE_PATIENT DATE_ADMISSION DATE_DISPOSITION 
		sort DX 
		bysort DX: gen tv_i = _n 
		bysort DX: egen total_obs = max(tv_i)
		drop tv_i
		* Fraction with follow ups (at all)  
		foreach days of numlist 30 60 90 {
			gen f_u_c_`days' = 0
			replace f_u_c_`days' = 1 if readmits_vis_`days'_ > 0 
			bysort DX: egen tfu_`days' = sum(f_u_c_`days')
			gen frac_follow_up_`days' = tfu_`days'/total_obs 
			label variable frac_follow_up_`days' "Frac. of Visits w/ Follow up before `days'"
		}
		foreach days of numlist 30 60 90{
			bysort DX: egen total_fu_visits_`days' = sum(readmits_vis_`days'_)
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
	
	
* CPT Codes - TODO.  
