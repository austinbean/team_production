/*
* Generates simulated file for the army personnel master file.

FIRST CREATED: SEPT 4, 2019
LAST UPDATED : X

LAST UPDATE: XX
		BY : AG
*/

set more off
clear all
set seed 41

* COMMENT OUT THE TWO WHICH ARE NOT YOURS TO RUN!
*local file_p = "/Users/tuk39938/Desktop/programs/team_production/"
local file_p = "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production\"
*local file_p = "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production"

*************;
*Create list of unit IDs;
clear
set obs 200

gen str10 UIC_PDE = ""
replace UIC_PDE = char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + ///
		char(runiformint(48,57)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + ///
		char(runiformint(48,57)) + char(runiformint(48,57)) + char(runiformint(48,57))

gen m_asg = _n

tempfile asgid
save `asgid'

drop m_asg
sort UIC_PDE
gen m_duty = _n
sort m_duty

tempfile dutyid
save `dutyid'

*************;
*Create list of zip codes;
clear
set obs 2000

gen zip = .
replace zip = runiformint(1,999)
tostring zip, force replace
replace zip = "0" + zip if length(zip)==2
replace zip = "00" + zip if length(zip)==1
gen m_asgzip = _n

tempfile asgzip
save `asgzip'

drop m_asgzip
gen unif = runiform()
sort unif

gen m_dutyzip = _n
sort m_dutyzip
drop unif

tempfile dutyzip
save `dutyzip'

*************;
*Main file;
clear

*  observation numbers
set obs 10000

*Use to make missing in same proportion as in master;
gen unif = runiform()

*Create patient level variables first;

*Patient id;
gen str12 PID_PDE = ""  
replace PID_PDE = "PDE" + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + ///
	char(runiformint(48,57)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + char(runiformint(48,57)) + char(runiformint(48,57))
label variable PID_PDE "unique id" 

*Spouse id if military;
gen str12 JSVC_SPSE_PID_PDE = ""  
replace JSVC_SPSE_PID_PDE = "PDE"+char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + ///
		char(runiformint(48,57)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(48,57)) + ///
		char(runiformint(48,57)) + char(runiformint(48,57)) if unif<=0.03
label variable JSVC_SPSE_PID_PDE "spouse id" 

*Date of birth;
gen double DATE_BIRTH_PDE = 0
gen u_mth = runiformint(1,12)
gen u_yr = runiformint(1965,1995)
replace DATE_BIRTH_PDE = mdy(u_mth,1,u_yr)
replace DATE_BIRTH_PDE = . if unif<=0.001
drop u_mth u_yr
format DATE_BIRTH_PDE %td
label variable DATE_BIRTH_PDE "Patient DOB" 

*Year of joining army;
gen yr_frst = runiformint(1998,2016)
gen yr_last = runiformint(1998,2016)
replace yr_frst = year(DATE_BIRTH_PDE)+18 if yr_frst < (year(DATE_BIRTH_PDE)+18)
replace yr_last = yr_frst+1 if yr_last<(yr_last+1)

gen double AFMS_BASE_DT =0
gen u_mth = runiformint(1,12)
replace AFMS_BASE_DT = mdy(u_mth,1,yr_frst)
replace AFMS_BASE_DT = . if unif<=0.002
format AFMS_BASE_DT %td
drop u_mth

*Education level;
local edu_lev = "11 12 14 15 18 20 22 23 24 26 29 31 32 33 35 37 39 40 42 44"
local length = 20

gen str2 EDU_LVL_CD = ""
replace EDU_LVL_CD = word( "`edu_lev'" , ceil(`length'*runiform())) 
replace EDU_LVL_CD = "" if unif<0.02

*Ethnic group code;
local eth_code = "BA BB BC BD BE BF BG CA CB CD CE CF CG DA DB DC DE DF DG EA EB EC"
local length = 22

gen str2 ETH_AFF_CD = ""
replace ETH_AFF_CD = word( "`eth_code'" , ceil(`length'*runiform())) 
replace ETH_AFF_CD = "" if unif<0.01

*Faith code;
local FAITH_GRP_CD = "AA AB AC AD AE AF AG AH BA BB BC BD BE BF BG CA CB CD CE CF CG DA DB DC DE DF DG EA EB NO"
local length = 30

gen str2 FAITH_GRP_CD = ""
replace FAITH_GRP_CD = word( "`eth_code'" , ceil(`length'*runiform())) 
replace FAITH_GRP_CD = "" if unif<0.01

*Sex code;
gen str3 PN_SEX_CD=""
replace PN_SEX_CD = "F" if unif <= 46/331
replace PN_SEX_CD = "M" if unif > 46/331

*Race code;
gen str3 RACE_CD=""
replace RACE_CD = "001" if unif<= 2.7/331
replace RACE_CD = "002" if unif > 2.7/331 & unif <= 14.7/331
replace RACE_CD = "003" if unif > 14.7/331 & unif <= 87.7/331
replace RACE_CD = "004" if unif > 87.7/331 & unif <= 87.8/331
replace RACE_CD = "005" if unif > 87.8/331 & unif <= 307.8/331

*Now create variables that vary within individuals;

drop unif yr_frst yr_last

expand 25

gen unif = runiform()

gen double SNPSHT_DT = 0
gen u_mth = runiformint(1,12)
gen u_yr = runiformint(2010,2017)
replace SNPSHT_DT = mdy(u_mth,1,u_yr)
format SNPSHT_DT %td
drop u_mth u_yr
label variable SNPSHT_DT "obs date" 

*Keep only obs with snapshot dates after joining date for each person. This creates variation where 
*some individuals have 25 obs, others have fewer.
drop if SNPSHT_DT < AFMS_BASE_DT  

sort PID_PDE SNPSHT_DT

by PID_PDE: gen record = _n

gen str2 RANK_GRP_PDE = ""
replace RANK_GRP_PDE = "EJ" if unif<=(150/331)
replace RANK_GRP_PDE = "ES" if unif >(150/331) & unif<=(270/331)
replace RANK_GRP_PDE = "OJ" if unif >(270/331) & unif<=(300/331)
replace RANK_GRP_PDE = "OS" if unif >(300/331) & unif<=(320/331)
replace RANK_GRP_PDE = "WJ" if unif >(320/331) & unif<=(327/331)
replace RANK_GRP_PDE = "WS" if unif >(327/331)

gen m_asg = runiformint(1,200)

merge m:1 m_asg using `asgid'
drop if _m==2
drop _m
ren UIC_PDE ASG_UIC_PDE
label variable ASG_UIC_PDE "assigned base" 
replace ASG_UIC_PDE="" if unif<=0.002		

ren m_asg m_duty

merge m:1 m_duty using `dutyid'
drop if _m==2
drop _m
ren UIC_PDE DTY_UIC_PDE
label variable DTY_UIC_PDE "actual base" 
replace DTY_UIC_PDE = "" if unif <= 0.015		

drop m_duty

gen m_asgzip = runiformint(1,2000)

merge m:1 m_asgzip using `asgzip'
drop if _m==2
drop _m

ren zip ZIP_CODE_PDE_ASG_UNT_LOC
replace ZIP_CODE_PDE_ASG_UNT_LOC = "" if unif<=0.08		
label variable ZIP_CODE_PDE_ASG_UNT_LOC "assigned base zip" 

ren m_asgzip m_dutyzip

merge m:1 m_dutyzip using `dutyzip'
drop if _m==2
drop _m

replace zip = ZIP_CODE_PDE_ASG_UNT_LOC if DTY_UIC_PDE == ASG_UIC_PDE

ren zip ZIP_CODE_PDE_DTY_UNT_LOC
replace ZIP_CODE_PDE_DTY_UNT_LOC = "" if unif<=0.08		
label variable ZIP_CODE_PDE_DTY_UNT_LOC "actual base zip" 

drop m_dutyzip

gen double AFMS_MN_QY = 0
replace AFMS_MN_QY = int((SNPSHT_DT - AFMS_BASE_DT)/30)
replace AFMS_MN_QY=. if AFMS_BASE_DT==.

gen double AFMS_YR_QY = 0
replace AFMS_YR_QY = year(SNPSHT_DT) - year(AFMS_BASE_DT)
replace AFMS_YR_QY =. if AFMS_BASE_DT==.

gen str2 ASG_UNT_MJR_CMD_CD=""

gen double PN_AGE_QY = int((SNPSHT_DT - DATE_BIRTH_PDE)/365.25)
replace PN_AGE_QY=. if DATE_BIRTH_PDE==.

drop unif

*save

save "`file_p'fake_army_master.dta", replace 

*clear 


