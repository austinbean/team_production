* Organize Episodes:
	/*
	README
	- identifies "sentinel_events" according to a list of ICD-9's below under PROGRAM_CONSTANTS
	- tracks those events and follow-up admissions (for any reason) w/in 30, 60 or 90 days (assigns to earliest sentinel event for if more than one)
	- adds two variables for each of 30 60 90 day thresholds: 
		- following_up_from_`day_threshold' - the date of the original visit to which the current record is a follow up.
		- is_`day_threshold'_follow_up - an indicator which is 1 if the visit is a follow up to another w/in `day_threshold' days
	- Creates a new file fake_SIDR_DOD_Dep_readmits.dta with these variables added.	
	*/


	* TODO - remove extra local constants below.  Don't keep at 10.

	
local file_p = "/Users/tuk39938/Desktop/programs/team_production/"
*local file_p = "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production"
*local file_p = "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production"


use "`file_p'fake_SIDR_DOD_Dep.dta", clear
 
 
* COMMENTS:
	/*
	Solvable (probably) problem: catches readmission n+1 w/in threshold days of admission n *admission date*, rather than discharge date.  Perhaps not that important.  
	
	One (complicated) unresovled problem - Tracking follow-ups to different kinds of episodes, e.g., 
		- patient has appendectomy, has two follow ups.
		- patient also has heart surgery (later than appendectomy), has 3 follow ups.
		- Imagine all visits within 90 days of appendectomy 
		- If appendectomy and heart surgery are *both* sentinel events, then 
		  all of those follow-ups are going to be assigned as follow-ups to 
		  the appendectomy.
		- In other words, this is not going to track separate sequences of follow-up 
		  events by the original type of event.
	One solution: If the file is run multiple times and saves separate output
		  for a one-item list of sentinel events, then this isn't an issue.  
		  
	Another (probably impossible) problem - We have no way to know whether the follow up is "related"
		- Imagine an appendectomy (sentinel event) followed by an unrelated brain surgery. 
	*/
 
 
* PROGRAM CONSTANTS
	* LIST RELEVANT ICD-9's HERE
	local sentinel_events = "V053 V3000 9955 V3001 640 7746 V290 7661 9983 V7219 V502 76528 7742 77989 7706 76519 77089 77931 769 76529 76518 9604 9915 V3101 605 9390 77181 76527"
	* MAX number of times we see someone in the record -
		 * can get this by counting,
		 /*
			bysort PID_PDE_PATIENT: gen ctr = _n 
			bysort PID_PDE_PATIENT: egen mxct = max(ctr)
			summarize mxct, d 
			local max_readmit = `r(max)'
			drop mxct ctr 
			di "`max_readmit'"
		 */
	local max_readmit = 10
	local barrier = 90 // There is only a single barrier value - 90 days.
	summarize DATE_ADMISSION 
	local date_min = `r(min)' // minimum date -> can't determine whether these are follow-ups 

	

* Generate list of patients with relevant admissions	
	* Sort by patient and then date.
	sort PID_PDE_PATIENT DATE_ADMISSION

	* keep only diagnosis related variables
	keep PID_PDE_PATIENT DATE_ADMISSION *DX*
	drop DX*POA
	rename ADMDX DX21
	
	* simulated data may permit unique patient to appear twice in one day  
	* there are multiple single-day admissions, esp. for dependents, per Steve.
	* create one record per patient-admission 
	bysort PID_PDE_PATIENT DATE_ADMISSION: gen pctr = _n
	reshape long DX, i(PID_PDE_PATIENT DATE_ADMISSION pctr)
	drop _j  pctr 
	drop if DX == ""
	
	* Tag diagnoses from the list sentinel_events above
	gen event = 0
	foreach ev of local sentinel_events {
		replace event = 1 if DX == "`ev'"
	}
	
	* generate "of_interest" tracking whether patient had one of these admissions.
	bysort PID_PDE_PATIENT DATE_ADMISSION: egen of_interest = sum(event)
	replace of_interest = 1 if of_interest >= 1
	drop event
	label variable of_interest "patient has sentinel event"
	
* Catch follow-up admissions w/in 30, 60, 90 days. 
	* here we do not need to track multiple admissions in one day
	duplicates drop PID_PDE_PATIENT DATE_ADMISSION , force 
	drop DX
	sort PID_PDE_PATIENT DATE_ADMISSION
	bysort PID_PDE_PATIENT (DATE_ADMISSION): gen admit_counter = _n 
	reshape wide DATE_ADMISSION of_interest, i(PID_PDE_PATIENT) j(admit_counter)
	
	* Determine events which will be "lost" - not follow-ups on their own since they occur within 'barrier' days of a sentinel event.  Is this getting it exactly right?  
		* these events shouldn't initiate new chains.  	But they are potentially *follow-ups* to earlier events.
		* Also checks if visit 1 is more than barrier days from the start.

	gen lost1 = 0
	replace lost1 = 1 if (DATE_ADMISSION1 - `date_min' < `barrier') & of_interest1 == 1
	foreach curr_vis of numlist 2(1)`max_readmit'{
		local prev_vis = `curr_vis'-1
		gen lost`curr_vis' = 0
		
			foreach prior of numlist 1(1)`prev_vis'{	
				* tags lost = 1 if there is *any* previous of interest visit < barrier days. 
				replace lost`curr_vis' = 1 if (DATE_ADMISSION`curr_vis' - DATE_ADMISSION`prior' < `barrier') & (of_interest`prior' == 1) & (of_interest`curr_vis' == 1)
			}
	}

	* keep a record of which visits should be lost for each individual
		preserve 
			reshape long DATE_ADMISSION of_interest lost, i(PID_PDE_PATIENT) j(visctr)
			drop visctr of_interest 
			keep if DATE_ADMISSION != .
			rename lost visit_lost
			label variable visit_lost "visit will not generate follow-ups"
			save "`file_p'lost_visits.dta", replace
		restore 


				* to look at results, uncomment: 
				* reshape long DATE_ADMISSION lost of_interest, i(PID_PDE_PATIENT) j(vctr)

	/*
Identify ALL readmissions within some set of thresholds, here 30 60 and 90 days
	- Any individual may have many or none within the thresholds.
	- Thus... 
		- Measure distance between subsequent admissions
		- Generate an indicator for the later when the earlier one is "of interest" and the readmission is within the threshold
	- This will check for each visit N only visits numbered N+1, ..., Max_visits 
	- This will check up to Max_visits - 1 (Max_visits is a patient-population-level parameter) 
	- If a visit is "lost" (< 'barrier' days from a sentinel event), it will not initiate a new chain of follow-ups   
	- Later: combine and check to make sure there is a "gap" between sentinel events and prior admissions.
	*/

	foreach day_threshold of numlist 30 60 90{ 
		local stop_at = `max_readmit'-1
		
		foreach strt of numlist 1(1)`stop_at'{
			local from_next = `strt' + 1  
		
			foreach next of numlist `from_next'(1)`max_readmit'{

				gen readmit_`day_threshold'f`strt't`next' = 1 if DATE_ADMISSION`next' - DATE_ADMISSION`strt' <= `day_threshold' & of_interest`strt' == 1 & lost`strt' != 1
			}
		} 
	}


* identify readmissions following the sentinel events  

	foreach day_threshold of numlist 30 60 90{

	local stop_at = `max_readmit'-1


		foreach vis of numlist 1(1)`stop_at'{
		preserve
				* Is this going to skip 'lost' events properly?  
			keep PID_PDE_PATIENT DATE_ADMISSION* of_interest`vis' readmit_`day_threshold'f`vis't* lost*
			rename DATE_ADMISSION`vis' following_up_from_`vis'
			label variable following_up_from_`vis' "date of visit to which present follows up"
			rename of_interest`vis' of_interest 
				* lost == 1 indicates date in "DATE_ADMISSION" will not generate follow-ups    
			reshape long DATE_ADMISSION readmit_`day_threshold'f`vis't lost, i(PID_PDE_PATIENT) j(followups)
			keep if readmit_`day_threshold'f`vis't == 1
			drop followups of_interest readmit_`day_threshold'f`vis't 
			gen byte is_`day_threshold'_follow_up_`vis' = 1
			label variable is_`day_threshold'_follow_up_`vis' "this visit is a `day_threshold' follow-up"
				* this part saves a BUNCH of temporaries - they are removed in the next loop.
			save "`file_p'follow_ups_`day_threshold'd_`vis'vis.dta", replace
			
		restore 
		}
	}

	
* Combine the follow-up visit data. 
	foreach day_threshold of numlist 30 60 90{
		local stop_at = `max_readmit'-1
		
		use "`file_p'follow_ups_`day_threshold'd_1vis.dta", clear
			foreach nm of numlist 2(1)`stop_at'{
				append using "`file_p'follow_ups_`day_threshold'd_`nm'vis.dta"

					* if disk space or clutter in folders is a concern, uncomment the remove command which follows.
				rm "`file_p'follow_ups_`day_threshold'd_`nm'vis.dta"
			}
		rm "`file_p'follow_ups_`day_threshold'd_1vis.dta"
		
		save "`file_p'follow_ups_`day_threshold'd.dta", replace
	}
	

	
* Clean up to prevent double assignment -> each double assigned visit will be assigned to the earliest sentinel event.  Note one difficulty w/ this under "comments" above
	* "lost" events will not generate follow-ups. 

	foreach day_threshold of numlist 30 60 90{
		use "`file_p'follow_ups_`day_threshold'd.dta", clear
		sort PID_PDE_PATIENT DATE_ADMISSION	
		collapse (firstnm) following_up_from_* is_`day_threshold'_follow_up_* lost, by(PID_PDE_PATIENT DATE_ADMISSION)
		reshape long following_up_from_ is_`day_threshold'_follow_up_,  i(PID_PDE_PATIENT DATE_ADMISSION) j(ctt)
		keep if is_`day_threshold'_follow_up_ != .
		bysort PID_PDE_PATIENT DATE_ADMISSION: gen adct = _n
		drop if adct > 1
		drop adct ctt 
		rename following_up_from_ following_up_from_`day_threshold'
		rename is_`day_threshold'_follow_up_ is_`day_threshold'_follow_up
		label variable following_up_from_`day_threshold' "orig. date to which this is `day_threshold' follow-up"
		label variable is_`day_threshold'_follow_up "`day_threshold' day follow up from earlier"
		save "`file_p'follow_ups_`day_threshold'd.dta", replace
	}
	
* Identify those visits which have follow ups:
	foreach day_threshold of numlist 30 60 90{
		use "`file_p'follow_ups_`day_threshold'd.dta", clear
		drop lost
		sort PID_PDE_PATIENT following_up_from_`day_threshold'
		bysort PID_PDE_PATIENT following_up_from_`day_threshold' (DATE_ADMISSION): gen follow_ups = _n 
		reshape wide DATE_ADMISSION , i(PID_PDE_PATIENT following_up_from_`day_threshold') j(follow_ups)
		rename is_`day_threshold'_follow_up has_`day_threshold'_follow_ups
		label variable has_`day_threshold'_follow_ups "admission has `day_threshold' day follow ups"
		rename DATE_ADMISSION* follow_up*_`day_threshold'
		rename following_up_from_`day_threshold' DATE_ADMISSION 
		egen num_`day_threshold'_follow_ups = rownonmiss(follow_up*)
		label variable num_`day_threshold'_follow_ups "has N follow ups w/in `day_threshold' d"
		save "`file_p'num_follups_`day_threshold'd.dta", replace
	}

	
* Merge back to original:

	use "`file_p'fake_SIDR_DOD_Dep.dta", clear
	
	* Adds 30 60 90 day follow-ups for each visit 
	foreach day_threshold of numlist 30 60 90{
		merge m:1 PID_PDE_PATIENT DATE_ADMISSION using "`file_p'follow_ups_`day_threshold'd.dta", nogen
		replace is_`day_threshold'_follow_up = 0 if is_`day_threshold'_follow_up == .
	}
	
	* Adds indicator whether visit has follow ups or not 
	foreach day_threshold of numlist 30 60 90{
		merge m:1 PID_PDE_PATIENT DATE_ADMISSION using "`file_p'num_follups_`day_threshold'd.dta", nogen
		replace has_`day_threshold'_follow_ups = 0 if has_`day_threshold'_follow_ups == .
	}
	
	* Adds indicator for lost visits.
	merge m:1 PID_PDE_PATIENT DATE_ADMISSION using "`file_p'lost_visits.dta", nogen

	save "`file_p'fake_SIDR_DOD_Dep_readmits.dta", replace
	
	
