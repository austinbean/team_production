/*
USES ARMY PERSONNEL FILE TO PRODUCE SOME STATS ON TRANSFERS AND RUN REGS TO CONFIRM THAT 
TRANSFERS ARE QUASI RANDOM.

FIRST CREATED: SEPT 4, 2019
LAST UPDATED : SEPT 6, 2019

LAST UPDATE: XX
		BY : AG
*/

set more off
clear all

* COMMENT OUT THE TWO WHICH ARE NOT YOURS TO RUN!
*local file_p = "/Users/tuk39938/Desktop/programs/team_production/"
local file_p = "C:\Users\atulgup\Dropbox (Penn)\Projects\Teams\team_production\"
*local file_p = "C:\Users\STEPHEN\Dropbox (Personal)\Army-Baylor\Research\Teams\team_production"

use "`file_p'fake_army_master", clear

*Set last date in army master;
local last_snp = td(1oct2016)

*Set "target" tenure: Duration that we expect to be modal;
local targ 3

*use shorter var names;
ren ZIP_CODE_PDE_ASG_UNT_LOC zip_asg
ren ZIP_CODE_PDE_DTY_UNT_LOC zip_dty

replace zip_dty = zip_asg if ASG_UIC_PDE == DTY_UIC_PDE

sort PID_PDE SNPSHT_DT

*Identify transfers;
gen xfer=0
by PID_PDE: replace xfer = ASG_UIC_PDE != ASG_UIC_PDE[_n-1] if _n>1
by PID_PDE: gen xfer_cnt = sum(xfer)
by PID_PDE: egen n_xfers = max(xfer_cnt)
by PID_PDE: gen next_snpsht = SNPSHT_DT[_n+1]

*Create unique IDs for each assignment;
egen assnt_id = group(PID_PDE xfer_cnt)

order PID_PDE SNPSHT_DT ASG_UIC_PDE xfer xfer_cnt assnt_id

bysort assnt_id: gen assnt_start = SNPSHT_DT[1]
by assnt_id: gen assnt_end = next_snpsht[_N]-1

by assnt_id: gen attrit = assnt_end==. & SNPSHT_DT[_N]<`last_snp'
by assnt_id: gen cens = assnt_end==. & SNPSHT_DT[_N]==`last_snp'

by assnt_id: replace assnt_end = SNPSHT_DT[_N]+90 if attrit
format assnt_start assnt_end next_snpsht %td

gen ten_assnt = (assnt_end - assnt_start)/365.25

order PID_PDE SNPSHT_DT record ASG_UIC_PDE xfer xfer_cnt assnt_id assnt_end assnt_start assnt_end ///
	cens attrit ten_assnt

*Code category variables;
	
*Sex;	
gen fem = PN_SEX_CD=="F"
drop PN_SEX_CD

*Race;
gen nonwht = RACE_CD!="005"

tempfile basic
save `basic', replace

*1. Distribution of period between transfers and correlation with observables;
use `basic', clear

*Drop obs before first transfer assuming we will not know tenure prior to first transfer;
drop if xfer_cnt==0

*Drop censored and attrition assignments;
drop if cens | attrit

gen start_yr = year(assnt_start)

*Collapse to assignment level file;
collapse (mean) ten_assnt start_yr fem nonwht (max) PN_AGE_QY ///
	(lastnm) EDU_LVL_CD ETH_AFF_CD FAITH_GRP_CD RANK_GRP_PDE zip_asg, by(assnt_id)

*Age group;
gen age_l20 = PN_AGE_QY<20
gen age_20s = inrange(PN_AGE_QY,20,29)
gen age_30s = inrange(PN_AGE_QY,30,39)
gen age_40s = inrange(PN_AGE_QY,40,49)
gen age_50s = inrange(PN_AGE_QY,50,59)
gen age_60s = inrange(PN_AGE_QY,60,69)

drop PN_AGE_QY	

*Rank;
gen off = inlist(RANK_GRP_PDE,"OJ","OS")
gen war_off = inlist(RANK_GRP_PDE,"WJ","WS")
drop RANK_GRP_PDE
	
*Distribution of assignment tenure;	
summ ten_assnt, d

hist ten_assnt if ten_assnt<r(p99), frac width(0.25) xla(2(0.25)5) ///
	fcolor(navy) lcolor(white)	

*What proportion of assignments are close to 3 year duration;
gen prop_around_`targ' = inrange(ten_assnt,(`targ'-0.51),(`targ'+0.51))

tabstat ten_assnt prop_around_`targ', by(start_yr)
tab prop_around_`targ' age_20s, summ(ten_assnt) means

regress ten_assnt fem nonwht age_* off war_off , rob

destring zip_asg, force replace

xtset zip_asg

xtreg ten_assnt fem nonwht age_* off war_off , fe robust

*2. Do observables explain high share of variation in transfers?

*Start with basic file;
use `basic', clear
gen year = year(SNPSHT_DT)

sort PID_PDE record

*Drop people who have never had transfers. ALways drop upto and including first transfer;
*since we don't know location specific tenure accurately until we see a transfer;
drop if xfer_cnt==0
by PID_PDE: drop if _n==1 & xfer==1

*compute tenure in assignment in each quarter;
gen ten = (next_snpsht-1 - assnt_start)/365.25

*Special treatment for assignments censored due to attrition or end of sample.
by PID_PDE: replace ten = (SNPSHT_DT + 91 - assnt_start)/365.25 if _N & (cens | attrit)

*Compute tenure in assignment at the end of qtr prior to transfer;
sort PID_PDE year
by PID_PDE: gen ten_yr = ten[_n-1] if xfer==1

*Compute tenure in assignment at the end of year with no transfer;
by PID_PDE year: egen xfer_yr = max(xfer)
by PID_PDE year: egen ten_avg = mean(ten)
replace ten_yr = ten_avg if xfer_yr==0 

order PID_PDE SNPSHT_DT record ASG_UIC_PDE xfer xfer_yr assnt_id assnt_end assnt_start assnt_end ///
	cens attrit ten ten_yr

*Collapse data to person-year;
collapse (max) xfer (firstnm) EDU_LVL_CD ETH_AFF_CD FAITH_GRP_CD RANK_GRP_PDE ASG_UIC_PDE zip_asg ///
	(min) PN_AGE_QY (mean) ten_yr fem nonwht, by(PID_PDE year)

by PID_PDE: egen nxfers = total(xfer)	
by PID_PDE: gen n_obs = _N	

encode PID_PDE, gen (pid)
xtset pid year

*very few transfers for people under the age of 20. recall we drop the first observed transfer. 
*So this has to be the 2nd transfer.	
drop if PN_AGE_QY<20

*Drop outlier tenures;
summ ten_yr, d
drop if ten_yr>r(p99)
	
*Age group;
gen age_20s = inrange(PN_AGE_QY,20,29)
gen age_30s = inrange(PN_AGE_QY,30,39)
gen age_40s = inrange(PN_AGE_QY,40,49)
gen age_50s = inrange(PN_AGE_QY,50,59)
gen age_60s = inrange(PN_AGE_QY,60,69)

*Rank;
gen off = inlist(RANK_GRP_PDE,"OJ","OS")
gen war_off = inlist(RANK_GRP_PDE,"WJ","WS")
drop RANK_GRP_PDE

*Simple spec using tenure in years;
probit xfer ten_yr fem nonwht off war_off age_30s - age_50s 

*Non-linear model;
gen ten_sq = ten_yr^2
gen ten_cub = ten_yr^3

probit xfer ten_yr ten_sq ten_cub fem nonwht off war_off age_30s - age_50s ,rob	

*Test if rank is jointly significant;
test off war_off

*Test if demographics and rank are jointly sig.
test off war_off fem nonwht

*If we have a quality measure for the physician, then include that as a predictor 
*on the RHS in the spec above;

*LPM fixed effect models, use individual f.e.s;
xtreg xfer ten_yr ten_sq ten_cub i.year, fe vce(cluster pid)

*To calculate joint f-stat for individual f.e.
*with clustered std. errors need to do manually.
*Got this from a bit of googling. a response on statalist. not sure, need to check.
*this is suspicious since it uses weird deg. of freedom.

scalar rss1 = e(rss)
scalar dfr = e(df_r)
scalar dfa = e(df_a)

regress xfer ten_yr ten_sq ten_cub i.year, vce(cluster pid)	
scalar rss2 = e(rss)

scalar fstat =  ((rss2-rss1)/dfa)/(rss1/dfr)

di "Resid SS with dummies " rss1
di "Resid SS without dummies " rss2
di "F statistic with " dfa " and " dfr " d.f. = " fstat

scalar drop rss1 rss2 dfr dfa

*Now spec with location fixed effects;
encode zip_asg, gen(zip_id)

xtset zip_id

*model with location f.e.s
xtreg xfer ten_yr ten_sq ten_cub i.year, fe vce(cluster zip_id)

scalar rss1 = e(rss)
scalar dfr = e(df_r)
scalar dfa = e(df_a)

regress xfer ten_yr ten_sq ten_cub i.year, vce(cluster zip_id)	

scalar rss2 = e(rss)

scalar fstat =  ((rss2-rss1)/dfa)/(rss1/dfr)

di "Resid SS with dummies " rss1
di "Resid SS without dummies " rss2
di "F statistic with " dfa " and " dfr " d.f. = " fstat


*clear 


