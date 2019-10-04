/*
IDENTIFIES INDEX EVENTS FOR PATIENTS AMONG SPECIFIED CONDITIONS/PROCEDURES OF INTEREST.

FIRST CREATED: OCT 3, 2019

LAST UPDATE: 
WHAT: BASIC.
WHEN: OCT 4, 2019
BY : AG
*/
	

cd "$file_p"
local sentinel_events = "V053 V3000 9955 V3001 640 7746 V290 7661 9983 V7219 V502 76528 7742 77989 7706 76519 77089 77931 769 76529 76518 9604 9915 V3101 605 9390 77181 76527"

*Set moratorium period;
local mor 90

*Set follow-up period (has to be less than moratorium period);
local follow `mor'

*Set constant dollar conversion values for drg weight and rvus
local drgdol 6000
local rvudol 36

*Specify patients of certain ages to be included;
*Frakes-Gruber paper excluded patients outside this age range;
local agelo 18
local agehi 60

*Cannot identify "noprior" for cases where we don't have 90 days of history;
*assume that sample period starts on certain date. then cannot have index 
*cases within 90 days of that date;
local start td(1jan2012)

*********************************************;
*Prepare drg weight file from CMS to be merged;
import excel using "FY 2012 FR Table 5.xlsx", firstrow clear

ren MSDRG msdrg
ren Weights weight

destring weight, force replace
drop if weight==.

tempfile drgwt
save `drgwt', replace

*********************************************;
*Prepare CAPER files for use;
use fake_dep_4, clear
sort encounter_key

merge 1:1 encounter_key using fake_caper_bus
drop if _m==2
drop _m	

keep pid_pde_patient date_birth_pde cpt_1 cptdx_1 dx1 meprscd provnpi* encdate ///
	ntrvu nwrvu rvu_et dmisid
format encdate %td	

sort pid_pde_patient encdate

ren encdate date_admission
gen date_disposition = date_admission

ren dx1 admdx
ren date_birth_pde date_birth

*Create dummy for ED visit;
gen ed = substr(meprscd,1,3)=="BIA"
	
tempfile outpatient
save `outpatient', replace

*********************************************;
*Start with inpatient file;

use fake_SIDR_DOD_Dep, clear

foreach var of varlist _all{
	local name = lower("`var'")
	rename `var' `name'
}	

keep pid_pde_patient date_admission date_disposition ///
	admdx dx1 proc1 msdrg drg date_birth mtf

gen ip=1

replace admdx = dx1 if admdx==""

*replace date_admission = date_initial_admission if date_initial_admission!=.

merge m:1 msdrg using `drgwt', keepusing(weight)
drop if _m==2
drop _m

append using `outpatient'

recode ip ed (mis=0)	

sort pid_pde_patient date_admission date_disposition 
	
gen agyradm = int((date_admission - date_birth)/365.25)

gen ip_disdate = date_disposition if ip
by pid_pde_patient: replace ip_disdate = ip_disdate[_n-1] if ip_disdate==.
format ip_disdate %td

by pid_pde_patient: gen tdiff = date_admission - date_disposition[_n-1]
by pid_pde_patient: gen ip_tdiff = date_admission - ip_disdate[_n-1]

gen noprior = ip_tdiff >= `mor'
gen ofinterest = 0

foreach ev of local sentinel_events {
	replace ofinterest = 1 if admdx == "`ev'"
}	

*Cannot identify index cases within moratorium period of sample start;
replace noprior=0 if (date_admission - `start') < `mor'

gen index = noprior & ofinterest

*Index case only defined for patient within desired age range;
replace index=0 if !inrange(agyradm,`agelo',`agehi')

*Identify and drop patients that never have an index case. exclude from sample entirely;
by pid_pde_patient: egen maxindx = max(index)
drop if maxindx==0
drop maxindx

*Within each patient, drop obs before the first index case since these are useless;
by pid_pde_patient: gen numindx = sum(index)
drop if numindx==0
drop numindx

*Assign unique id to each index case and all associated follow-up events;
gen index_id = sum(index)

gen index_disdate = date_disposition if index==1
by pid_pde_patient: replace index_disdate = index_disdate[_n-1] if index_disdate==.
format index_disdate %td

by pid_pde_patient: gen index_tdiff = date_admission - index_disdate[_n-1]

*Can drop follow-up cases that occured too far from index case, but are not index 
*cases themselves because they are not "ofinterest";
drop if index_tdiff>=`follow' & index==0

order pid_pde_patient date_admission date_disposition tdiff ip ip_disdate ///
	ip_tdiff ofinterest noprior index index_id index_disdate index_tdiff

*Create indicators for adverse events within follow-up period;	
gen readm = index_tdiff < `follow' & ip
gen ed_f  = index_tdiff < `follow' & ed==1

sort index_id date_admission

gen ipwt_f = weight if index==0
gen opwt_f = rvu_et if index==0

by index_id: egen ind_readm = max(readm)
by index_id: egen ind_ed = max(ed_f)
by index_id: egen totrvu = total(opwt_f)
by index_id: egen totwt = total(ipwt_f)

gen totspend = totrvu*`rvudol' + totwt*`drgdol'

*Keep only index cases, so now each obs pertains to a different episode;
keep if index==1






	
*END CODE;
