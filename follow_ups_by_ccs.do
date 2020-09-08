* Follow-ups w/in CCS codes

/*

- will count follow-ups w/in 90 days by CCS
- special note for those CCS codes which are in the same system.
NB: maybe unavoidable limitation - some visits are going to be counted as follow-ups more 
than once.  
EX: 
- 5 Visits w/in 90 days for CCS 1
- 2nd, 3rd, 4th, 5th are follow-ups to 1st visit 
- 3rd, 4th, 5th are follow-ups to 2nd visit
- 4th, 5th are follow ups to 3rd visit 
- 5th is follow-up to 4th.
- Total of 10 follow ups from 5 visits.
*/



clear 

do "/Users/austinbean/Desktop/programs/team_production/master_filepaths.do"
*do "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production\master_filepaths.do"
*do "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production\master_filepaths.do"

cd "${file_p}"


	* prep variables
	
	rename *, upper 
	keep PATIENT ENCDATE CCS_* 
	sort PATIENT ENCDATE
	destring CCS_*, replace force                    // whatever format they are in.

	* list CCS 
	
	preserve 
		keep PATIENT ENCDATE CCS_*                   // reshape long at first to count all CCS codes and store
		duplicates drop PATIENT ENCDATE, force 
		reshape long CCS_, i(PATIENT ENCDATE)
		drop if CCS_ == .
		levelsof CCS_, local(all_ccs)                // all CCS codes in local all_ccs
	restore

	di "`all_ccs'"
	
	* Body System variables:

	gen NERV = 0
	gen ENDO = 0
	gen EENT = 0
	gen RESP = 0
	gen CARD = 0
	gen LYMPH = 0
	gen DIG = 0
	gen URIN = 0
	gen GENIT = 0
	gen OBST = 0
	gen ORTHO = 0
	gen INTEG = 0
	gen MISC = 0
	
	foreach nm of numlist 1(1)10{
		replace NERV = 1 if inrange(CCS_`nm', 1, 9)
		replace ENDO = 1 if inrange(CCS_`nm', 10, 12)
		replace EENT = 1 if inrange(CCS_`nm', 13, 33)
		replace RESP = 1 if inrange(CCS_`nm', 34, 42)
		replace CARD = 1 if inrange(CCS_`nm', 45, 62)
		replace LYMPH = 1 if inrange(CCS_`nm', 64, 67)
		replace DIG = 1 if inrange(CCS_`nm', 64, 99)
		replace URIN = 1 if inrange(CCS_`nm', 100, 112)
		replace GENIT = 1 if (inrange(CCS_`nm', 113, 121) | inrange(CCS_`nm', 123, 132 ))
		replace OBST = 1 if CCS_`nm' == 122 | inrange(CCS_`nm', 134, 141)       // single code for this CCS out of order
		replace ORTHO = 1 if inrange(CCS_`nm', 142, 164)
		replace INTEG = 1 if inrange(CCS_`nm', 165, 175)
		replace MISC = 1 if CCS_`nm' == 244
	}
	
	
	* Prerequisites for loop
	duplicates drop PATIENT ENCDATE, force           // duplicate encounters?
	bysort PATIENT (ENCDATE): gen pctr =_n           // how many encounters?
	summarize pctr, d                                // max encounters over all patients
	local max_r = `r(max)'                           // most encounters by any patient
	local stopping = `max_r'-1                       // next to last of max encounters
	rename CCS_* CCS_*_
	reshape wide CCS_*_ ENCDATE NERV ENDO EENT RESP CARD LYMPH DIG URIN GENIT OBST ORTHO INTEG MISC, i(PATIENT) j(pctr)   // one row w/ all encounters and CCS codes per patient.  width is (# CCS) x (14 systems) x Max Encounters 

	foreach prior_vis of numlist 1(1)`stopping'{
		
		local next_vis = `prior_vis'+1
		
		// readmissions (at all, any CCS)
		gen all_readmits_`prior_vis' = 0
		foreach current_vis of numlist `next_vis'(1)`max_r'{
				replace all_readmits_`prior_vis' = all_readmits_`prior_vis' + 1 if (ENCDATE`current_vis' - ENCDATE`prior_vis') <= 90     // missing encounters fine b/c ". - number" !<= 90.
		}
		
		

		// readmissions by CCS - remember that there are a lot of them: CCS_1 - CCS_10, 
		foreach ccs of local all_ccs {
			gen readmits_`ccs'_`prior_vis' = 0 // do I care about what visit they occurred in?
			foreach current_vis of numlist `next_vis'(1)`max_r' {
				foreach ix of numlist 1(1)10 {                                  // 10 possible CCS codes per visit
					replace readmits_`ccs'_`prior_vis' = readmits_`ccs'_`prior_vis' + 1 if (ENCDATE`current_vis' - ENCDATE`prior_vis') <= 90 & CCS_`ix'_`prior_vis' == `ccs' // in a prior visit <= 90 days, you had `ccs' done
				}
			}	
		}
	}

	* Collapse by CCS and drop to save space
	foreach ccs of local all_ccs{
		egen all_ccs_readmit_`ccs' = rowtotal(readmits_`ccs'_*)
		label variable all_ccs_readmit_`ccs' "# readmits after CCS `ccs'"
		drop readmits_`ccs'_*
	}

	
foreach prior_vis of numlist 1(1)`stopping'{
		
		local next_vis = `prior_vis'+1

		// readmissions by system  
		foreach ccs of local all_ccs {
			gen readmits_ss_`ccs'_`prior_vis' = 0
			foreach current_vis of numlist `next_vis'(1)`max_r' {			
				foreach ix of numlist 1(1)10{
					replace readmits_ss_`ccs'_`prior_vis' = readmits_ss_`ccs'_`prior_vis' + 1 if (ENCDATE`current_vis' - ENCDATE`prior_vis') <= 90 & CCS_`ix'_`current_vis' == `ccs' & CCS_`ix'_`prior_vis' == `ccs' // in a prior visit <= 90 days, you had `ccs' done AND the same this time
				}
			}
		}	
	}
	
	foreach ccs of local all_ccs{
		egen same_ccs_readmit_`ccs' = rowtotal(readmits_ss_`ccs'_*)
		label variable same_ccs_readmit_`ccs' "# same CCS readm. after CCS `ccs'"
		drop readmits_ss_`ccs'_*
	}



	reshape long CCS_1_ CCS_2_ CCS_3_ CCS_4_ CCS_5_ CCS_6_ CCS_7_ CCS_8_ CCS_9_ CCS_10_ ENCDATE NERV ENDO EENT RESP CARD LYMPH DIG URIN GENIT OBST ORTHO INTEG MISC  , i(PATIENT )
	
	drop _j

	
* Now: reshape this to summarize readmits over all patients in the data.
		/*
		creates a collection of locals w/ counts of frequency of each CCS code,
		all as CCS_TOTAL_#CCS
		*/
	preserve
		keep CCS_* 
		rename CCS_*_ CCS_*
		gen ix = _n 
		reshape long CCS_, i(ix) j(ctt)
		drop if CCS_ == .
		sort CCS_ 
		foreach ccs of local all_ccs{
			count if CCS_ == `ccs'
			local CCS_TOTAL_`ccs' = `r(N)'
		}
	restore 
	
	drop ENCDATE NERV ENDO EENT RESP CARD LYMPH DIG URIN GENIT OBST ORTHO INTEG MISC 
	drop CCS_1_ CCS_2_ CCS_3_ CCS_4_ CCS_5_ CCS_6_ CCS_7_ CCS_8_ CCS_9_ CCS_10_
	drop all_readmits_1 all_readmits_2 all_readmits_3 all_readmits_4 all_readmits_5 all_readmits_6 all_readmits_7 all_readmits_8 all_readmits_9
	
	
	* duplicate variables for the collapse, which is cumbersome
	
	ds all_ccs_readmit_* 
	foreach v1 of varlist `r(varlist)'{
		gen mn_`v1' = `v1'
	}
	ds same_ccs_readmit_*
	foreach v1 of varlist `r(varlist)'{
		gen mn_`v1' = `v1'
	}
	
	
	collapse (max) all_ccs_readmit_*  same_ccs_readmit_* (min) mn_all_ccs_readmit_*  mn_same_ccs_readmit_*, by(PATIENT)

	foreach ccs of local all_ccs{
		assert all_ccs_readmit_`ccs' == mn_all_ccs_readmit_`ccs'
		assert same_ccs_readmit_`ccs' == mn_same_ccs_readmit_`ccs'
		drop mn_all_ccs_readmit_`ccs'
		drop mn_same_ccs_readmit_`ccs'
	}
	
	
	reshape long all_ccs_readmit_ same_ccs_readmit_ , i(PATIENT) j(CCS)
	
	drop PATIENT 
	
	sort CCS 
	
	collapse (sum) all_ccs_readmit same_ccs_readmit_, by(CCS)
	
