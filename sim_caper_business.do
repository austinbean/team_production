/*
Generate simulated caper business file;

FIRST CREATED: OCT 2, 2019
LAST UPDATE: 
WHAT: REFINEMENTS. ADAPT TO BEING CALLED TOGETHER WITH DATA_SIMULATE.
WHEN: OCT 3, 2019
BY: AG
*/

clear
set seed 41
set more off

*****************************
*Create assgndur values;
set obs 1000

gen str8 assgndur=""
replace assgndur = string(runiformint(0,9)) + string(runiformint(0,9)) + string(runiformint(0,9)) + string(runiformint(0,9)) + string(runiformint(0,9))

bysort assgndur: keep if _n==1
keep in 1/900
gen assgndur_key = _n

tempfile assgndur
save `assgndur', replace

*****************************
*Create msma values;

clear
set obs 20

gen str2 msma=""
replace msma= string(runiformint(0,9)) + string(runiformint(0,9))
bysort msma: keep if _n==1
drop if msma=="00"
keep in 1/14

gen msma_key = _n

tempfile msma
save `msma', replace

*****************************
*Create PID_PDE_SPONSOR;

clear

set obs 15000

gen str12 PID_PDE_SPONSOR = ""  
replace PID_PDE_SPONSOR = "PDE"+char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(48,57)) + char(runiformint(48,57))
label variable PID_PDE_SPONSOR "" 

bysort PID_PDE_SPONSOR: keep if _n==1

expand 2

*Create patient IDs;

gen str12 PID_PDE_PATIENT = ""  
replace PID_PDE_PATIENT = "PDE"+char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(48,57)) + char(runiformint(48,57))
label variable PID_PDE_PATIENT "" 

bysort PID_PDE_PATIENT: keep if _n==1

gen reps = runiformint(1,5)

*Now add vars that vary within patient;
expand 5

bysort PID_PDE_PATIENT: gen nobs = _n

keep if nobs<=reps

drop nobs reps

gen rand = runiform(0,1)

*Encounter id;
gen str64 encounter_key=""
local c2use 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ

replace encounter_key = "0" + string(runiformint(0,9)) + string(runiformint(0,9)) + string(runiformint(0,9)) + "_"
forval i=1/40{
	replace encounter_key = encounter_key + substr("`c2use'", runiformint(1,length("`c2use'")),1)
} 


gen assgndur_key = runiformint(1,900)

merge m:1 assgndur_key using `assgndur'
drop if _m==2
drop _m assgndur_key
replace assgndur="" if rand<=0.03

sort PID_PDE_PATIENT encounter_key

*Create cpt and different rvu codes;

gen cptuos_1 = 1 if rand<=0.980
replace cptuos_1 = 0 if inrange(rand,0.9801,0.983)
replace cptuos_1 = runiformint(2,4) if inrange(rand,0.9831,0.985)


forval i=2/13{
	
		gen randmiss`i' = runiform(0.9,0.99)		
		local val = randmiss`i'[1]
		replace randmiss`i' = `val'
		gen cptuos_`i' = 1 if rand >= randmiss`i'
		
		if inrange(`i',2,3){
			replace cptuos_`i' = runiformint(2,4) if rand >= 0.995
		}
		
		if `i'>3{
			replace cptuos_`i' = runiformint(2,900) if rand >= 0.998
		}
}

*Bring in msma value;
gen msma_key = runiformint(1,14)
merge m:1 msma_key using `msma'
drop if _m==2
drop _m msma_key

replace msma="" if rand <= 0.615

sort PID_PDE_PATIENT encounter_key

*Create npervu* variables;

gen npervu1=.
replace npervu1=0 if rand<=0.56
replace npervu1=1 if inrange(rand,0.561,0.91)
replace npervu1=2 if inrange(rand,0.911,0.94)
replace npervu1 =runiformint(3,8) if inrange(rand,0.941,0.945)

forval i=2/13{
	gen npervu`i'=.
	replace npervu`i' = runiformint(0,1) if inrange(rand,randmiss`i',0.998)
	if (inrange(`i',2,3) | inrange(`i',12,13)) {
		replace npervu`i' = runiformint(2,8) if rand > 0.998
	}
	else{
		replace npervu`i' = runiformint(2,60) if rand > 0.998
	}
}

*Create ntrvu* variables;

*First one has no missing;
gen ntrvu=.
replace ntrvu = 0 if rand<=0.49
replace ntrvu = 1 if inrange(rand,0.491,0.65)
replace ntrvu = 2 if inrange(rand,0.651,0.749)
replace ntrvu = 3 if inrange(rand,0.7491,0.85)
replace ntrvu = 4 if inrange(rand,0.851,0.98)
replace ntrvu = runiformint(5,321) if ntrvu==.

gen ntrvu1=.
replace ntrvu1=0 if rand<=0.56 & npervu1!=.
replace ntrvu1=1 if inrange(rand,0.561,0.74) & npervu1!=.
replace ntrvu1=2 if inrange(rand,0.741,0.89) & npervu1!=.
replace ntrvu1=3 if inrange(rand,0.891,0.941) & npervu1!=.
replace ntrvu1 =runiformint(4,26) if ntrvu1==. & npervu1!=.

forval i=2/13{
	gen ntrvu`i'=.
	replace ntrvu`i'=runiformint(0,1) if inrange(rand,randmiss`i',0.995)
	if inrange(`i',1,3){
		replace ntrvu`i'=runiformint(2,26) if rand > 0.995
	}
	else{
		replace ntrvu`i'=runiformint(2,150) if rand > 0.995
	}
}

*Create nwrvu* variables;
gen nwrvu=.
replace nwrvu = 0 if rand<=0.49
replace nwrvu = 1 if inrange(rand,0.491,0.74)
replace nwrvu = 2 if inrange(rand,0.741,0.95)
replace nwrvu = 3 if inrange(rand,0.951,0.99)
replace nwrvu = runiformint(4,82) if nwrvu==.

gen nwrvu1=.
replace nwrvu1 = 0 if rand<=0.74 & npervu1!=.
replace nwrvu1 = 1 if inrange(rand,0.741,0.89) & npervu1!=.
replace nwrvu1 = 2 if inrange(rand,0.891,0.94) & npervu1!=.
replace nwrvu1 = runiformint(3,18) if nwrvu1==. & npervu1!=.

forval i=2/13{
	gen nwrvu`i'=.
	replace nwrvu`i' = 0 if inrange(rand,randmiss`i',0.998)
	if inrange(`i',1,3){
		replace nwrvu`i'=runiformint(1,18) if rand>0.998
	}
	if inrange(`i',4,5){
		replace nwrvu`i'=runiformint(1,70) if rand>0.998
	}
	if inrange(`i',6,13){
		replace nwrvu`i'=runiformint(1,15) if rand>0.998
	}

}

*Create p1pervu* variables;
gen p1pervu=.
replace p1pervu = 0 if rand<=0.49
replace p1pervu = 1 if inrange(rand,0.491,0.85)
replace p1pervu = 2 if inrange(rand,0.851,0.99)
replace p1pervu = runiformint(3,316) if p1pervu==.

gen p1pervu1=.
replace p1pervu1=0 if rand<=0.56 & npervu1!=.
replace p1pervu1=1 if inrange(rand,0.561,0.91) & npervu1!=.
replace p1pervu1=2 if inrange(rand,0.911,0.94) & npervu1!=.
replace p1pervu1 =runiformint(3,8) if p1pervu1==. & npervu1!=.

forval i=2/13{
	gen p1pervu`i'=.
	replace p1pervu`i' = runiformint(0,1) if inrange(rand,randmiss`i',0.998)
	if (inrange(`i',2,3) | inrange(`i',12,13)) {
		replace p1pervu`i' = runiformint(2,8) if rand > 0.998
	}
	else{
		replace npervu`i' = runiformint(2,60) if rand > 0.998
	}
}

*Create p1trvu* variables;
gen p1trvu=.
replace p1trvu = 0 if rand<=0.49
replace p1trvu = 1 if inrange(rand,0.491,0.65)
replace p1trvu = 2 if inrange(rand,0.651,0.749)
replace p1trvu = 3 if inrange(rand,0.7491,0.85)
replace p1trvu = 4 if inrange(rand,0.851,0.99)
replace p1trvu = runiformint(5,321) if p1trvu==.

gen p1trvu1=.
replace p1trvu1=0 if rand<=0.56 & npervu1!=.
replace p1trvu1=1 if inrange(rand,0.561,0.65) & npervu1!=.
replace p1trvu1=2 if inrange(rand,0.651,0.85) & npervu1!=.
replace p1trvu1=3 if inrange(rand,0.851,0.94) & npervu1!=.
replace p1trvu1 =runiformint(4,26) if p1trvu1==. & npervu1!=.

forval i=2/13{
	gen p1trvu`i'=.
	replace p1trvu`i' = runiformint(0,1) if inrange(rand,randmiss`i',0.998)
	if inrange(`i',1,3){
		replace p1trvu`i'=runiformint(2,26) if rand>0.998
	}
	else{
		replace p1trvu`i'=runiformint(2,150) if rand>0.998
	}
}

*Create p1wrvu* variables;
gen p1wrvu=.
replace p1wrvu = 0 if rand<=0.49
replace p1wrvu = 1 if inrange(rand,0.491,0.74)
replace p1wrvu = 2 if inrange(rand,0.741,0.99)
replace p1wrvu = runiformint(3,82) if p1wrvu==.

gen p1wrvu1=.
replace p1wrvu1=0 if rand<=0.65 & npervu1!=.
replace p1wrvu1=1 if inrange(rand,0.651,0.85) & npervu1!=.
replace p1wrvu1=2 if inrange(rand,0.851,0.94) & npervu1!=.
replace p1wrvu1 =runiformint(3,18) if p1wrvu1==. & npervu1!=.

forval i= 2/13{
	gen p1wrvu`i'=.
	replace p1wrvu`i' = 0 if inrange(rand,randmiss`i',0.998)
	if inrange(`i',1,3){
		replace p1wrvu`i'=runiformint(1,18) if rand > 0.998
	}
	if inrange(`i',4,5){
		replace p1wrvu`i'=runiformint(1,70) if rand > 0.998
	}
	if inrange(`i',6,15){
		replace p1wrvu`i'=runiformint(1,15) if rand > 0.998
	}

}

*Create rrvu* variables;
gen rrvu1=.
replace rrvu1=0 if rand<=0.74 & npervu1!=.
replace rrvu1=1 if inrange(rand,0.741,0.89) & npervu1!=.
replace rrvu1=2 if inrange(rand,0.891,0.94) & npervu1!=.
replace rrvu1 =runiformint(3,18) if rrvu1==. & npervu1!=.

forval i=2/13{
	gen rrvu`i'=.
	replace rrvu`i' = runiformint(0,1) if inrange(rand,randmiss`i',0.998)
	if inrange(`i',2,3) {
		replace rrvu`i' = runiformint(2,18) if rand > 0.998
	}
	else{
		replace rrvu`i' = runiformint(2,15) if rand > 0.998
	}
}

gen rvu_epe = .
replace rvu_epe=0 if rand<=0.49
replace rvu_epe=1 if inrange(rand,0.491,0.85)
replace rvu_epe=2 if inrange(rand,0.851,0.98)
replace rvu_epe = runiformint(3,316) if rvu_epe==.

gen rvu_et = .
replace rvu_et = 0 if rand<=0.49
replace rvu_et = 1 if inrange(rand,0.491,0.65)
replace rvu_et = 2 if inrange(rand,0.651,0.74)
replace rvu_et = 3 if inrange(rand,0.741,0.89)
replace rvu_et = 4 if inrange(rand,0.891,0.98)
replace rvu_et = runiformint(5,321) if rvu_et==.

gen str2 skill1=""

replace skill1 = "1" if rand<=0.41
replace skill1 = "2" if inrange(rand,0.411,0.73)
replace skill1 = "3" if inrange(rand,0.731,0.91)
replace skill1 = "4" if inrange(rand,0.911,0.99)
replace skill1 = "1R" if skill1==""

save "$file_p\fake_caper_bus.dta", replace 




