* Organize Episodes:

local file_p = "/Users/tuk39938/Desktop/programs/team_production/"
*local file_p = "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production"
*local file_p = "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production"


 use "`file_p'fake_SIDR_DOD_Dep.dta", clear
 
 
* PROGRAM CONSTANTS
	* LIST RELEVANT ICD-9's HERE
	local sentinel_events = "V053 V3000 9955 V3001 640 7746 V290 7661 9983 V7219 V502 76528 7742 77989 7706 76519 77089 77931 769 76529 76518 9604 9915 V3101 605 9390 77181 76527"
	* MAX number of times we see someone in the record -	
	local max_readmit = 10
	
	

* Generate list of patients with relevant admissions	
	* Sort by patient and then date.
	sort PID_PDE_PATIENT DATE_ADMISSION

	* keep only diagnosis related variables
	keep PID_PDE_PATIENT DATE_ADMISSION *DX*
	drop DX*POA
	rename ADMDX DX21
	
	* simulated data may permit unique patient to appear twice in one day -> Is this a real problem or not? 
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
	
	/*
	Next loop looks (and may be) very inefficient, but...
	- Need to identify ALL readmissions within some set of thresholds, here 30 60 and 90 days
	- Any individual may have many or none within the thresholds.
	- Thus... 
		- Reshape to wide
		- Measure distance between subsequent admissions
		- Generate an indicator for the later when the earlier one is "of interest" and the readmission is within the threshold
	- Current: combine this set of indicators.
	- Very happy to hear about more efficient ways to solve this problem!
	*/
	local max_readmit = 10
	foreach day_threshold of numlist 30 60 90{ 
		foreach strt of numlist 1(1)`max_readmit'{
			foreach next of numlist 2(1)`max_readmit'{
				gen readmit_`strt'_`next'_`day_threshold' = 1 if DATE_ADMISSION`next' - DATE_ADMISSION`strt' <= `day_threshold' & of_interest`strt' == 1
			}
		} 
	}
	
	
	
/*	
	bysort PID_PDE_PATIENT (DATE_ADMISSION): egen total_admits = count(_n) 
	egen max_admits = max(total_admits)
	
	
	
	foreach nm of numlist 30 60 90{
		gen within_`nm' = 0
		label variable within_`nm' "Readmissions w/in `nm'"
	}
	
	summarize max_admits, meanonly
	local max_ad = `r(mean)'
	foreach i of numlist 1(1)10{
		bysort PID_PDE_PATIENT (DATE_ADMISSION): gen ddiff_`i' = 1 if DATE_ADMISSION[_n+`k'] - DATE_ADMISSION <= 30
	}
	
	
		* TODO - this isn't right because it only checks the next one.  
	foreach days of numlist 30 60 90 {
	bysort PID_PDE_PATIENT (DATE_ADMISSION): gen readmit_`days' if DATE_ADMISSION[_n+1] - DATE_ADMISSION <= `days'
	}
*/
